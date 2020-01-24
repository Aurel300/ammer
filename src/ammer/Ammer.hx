package ammer;

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;
import sys.FileSystem;
import ammer.AmmerConfig.AmmerLibraryConfig;

using StringTools;
using ammer.FFITools;

/**
  Main class for `ammer`. Handles common tasks and dispatches calls to
  target-specific stages.
**/
class Ammer {
  static var config:AmmerConfig;
  static var libraries:Array<AmmerLibraryConfig> = [];
  static var libraryMap:Map<String, AmmerLibraryConfig> = [];
  static var libraryTypeMap:Map<String, AmmerContext> = [];
  static var opaques:Array<AmmerOpaqueContext> = [];
  public static var opaqueMap:Map<String, AmmerOpaqueContext> = [];
  static var opaqueCache:Map<String, {fields:Array<Field>, library:ComplexType}> = [];
  static var ctx:AmmerContext;
  static var ctxStack:Array<AmmerContext> = [];
  static var printer:Printer = new Printer();

  static var opaqueCtr = 0;

  public static function debugP(message:() -> Dynamic, stream:String, ?pos:haxe.PosInfos):Void {
    if (config.debug.indexOf(stream) == -1)
      return;
    Sys.println('[ammer:$stream] ${message()} (${pos.fileName}:${pos.lineNumber})');
  }

  public static function debug(message:Dynamic, stream:String, ?pos:haxe.PosInfos):Void {
    if (config.debug.indexOf(stream) == -1)
      return;
    Sys.println('[ammer:$stream] $message (${pos.fileName}:${pos.lineNumber})');
  }

  /**
    Gets a compile-time define by `key`. If the specified key is not defined,
    return the value `dv`, or throw an error if `doThrow` is `true`.
  **/
  public static function getDefine(key:String, ?dv:String, ?doThrow:Bool = false):String {
    if (Context.defined(key))
      return Context.definedValue(key);
    if (doThrow)
      Context.fatalError('required define: $key', Context.currentPos());
    return dv;
  }

  /**
    Gets a path from the compile-time define `key`. If the path is relative,
    resolve it relative to the current working directory.
  **/
  public static function getPath(key:String, ?dv:String, ?doThrow:Bool = false):String {
    var p = getDefine(key, dv, doThrow);
    if (p != null && !Path.isAbsolute(p))
      p = Path.join([Sys.getCwd(), p]);
    return p;
  }

  /**
    Creates `config` object, runs some project-global tasks.
  **/
  static function configure():Void {
    // run only once
    if (config != null)
      return;

    // check platform
    var platform = (switch (Context.definedValue("target.name")) {
      case "hl": AmmerPlatform.Hl;
      case "cpp": AmmerPlatform.Cpp;
      case "eval": AmmerPlatform.Eval;
      case "cross": AmmerPlatform.Cross;
      case _:
        Context.fatalError("unsupported ammer platform", Context.currentPos());
        null;
    });

    // load configuration from defines
    config = {
      eval: null,
      hl: null,
      debug: (switch (getDefine("ammer.debug")) {
        case null: [];
        case "all": ["stage", "gen-library", "gen-opaque", "msg"];
        case s: s.split(",");
      }),
      platform: platform,
      useMSVC: Context.defined("ammer.msvc") ? (getDefine("ammer.msvc", "no") != "no") : Sys.systemName() == "Windows"
    };

    // load target-specific configuration, create directories
    inline function mk(dir:String):Void {
      if (!FileSystem.exists(dir))
        FileSystem.createDirectory(dir);
    }
    switch (platform) {
      case Eval:
        config.eval = {
          build: getPath("ammer.eval.build", Sys.getCwd()),
          output: getPath("ammer.eval.output", Sys.getCwd()),
          haxeDir: getPath("ammer.eval.haxeDir", true),
          bytecode: Context.defined("ammer.eval.bytecode")
        };
        mk(config.eval.build);
        mk(config.eval.output);
      case Hl:
        var outputDir = Path.directory(Compiler.getOutput());
        config.hl = {
          build: getPath("ammer.hl.build", outputDir),
          output: getPath("ammer.hl.output", outputDir),
          hlIncludePath: getPath("ammer.hl.hlInclude", null),
          hlLibraryPath: getPath("ammer.hl.hlLibrary", null)
        };
        mk(config.hl.build);
        mk(config.hl.output);
      case _:
    }

    // register the build stage
    Context.onAfterTyping(runBuild);
  }

  /**
    Maps an FFI type to its syntactic Haxe equivalent.
  **/
  public static function mapFFIType(t:FFIType):ComplexType {
    return (switch (t) {
      case Void: (macro:Void);
      case Bool: (macro:Bool);
      case Int: (macro:Int);
      case Float: (macro:Float);
      case Bytes: (macro:haxe.io.Bytes);
      case String: (macro:String);
      case Opaque(id, _): (macro:Dynamic);
      //case Deref(t): mapFFIType(t);
      case NoSize(t): mapFFIType(t);
      case SameSizeAs(t, _): mapFFIType(t);
      case SizeOf(_): (macro:Void);
      case SizeOfReturn: (macro:Void);
      case _: throw "!";
    });
  }

  /**
    Maps a Haxe type (including the special `ammer.ffi.*` types) to its FFI
    type equivalent. Only allows FFI type wrappers if `annotated` is `false`
    (this prevents malformed FFI types like `SameSizeAs(SameSizeAs(...), ...)`).
  **/
  static function mapTypeFFIResolved(resolved:Type, field:String, arg:String, p:Position, ?annotated:Bool = false):FFIType {
    var pos = (macro null).pos;
    var ret = null;
    function c(type:ComplexType, ffi:FFIType):Bool {
      if (Context.unify(Context.resolveType(type, pos), resolved)) {
        ret = ffi;
        return true;
      }
      return false;
    }
    c((macro:Void), Void)
    || c((macro:Bool), Bool) // order matters for Float and Int!
    || c((macro:Float), Float)
    || c((macro:Int), Int) // also matches UInt
    || c((macro:String), String)
    || c((macro:haxe.io.Bytes), Bytes)
    || c((macro:ammer.ffi.SizeOfReturn), SizeOfReturn)
    || c((macro:ammer.ffi.This), This)
    || {
      ret = (switch (resolved) {
        //case TInst(_.get() => {name: "Deref", pack: ["ammer", "ffi"]}, [inner]) if (!annotated):
        //  Deref(mapTypeFFIResolved(inner, field, arg, p, true));
        case TInst(_.get() => {name: "NoSize", pack: ["ammer", "ffi"]}, [inner]) if (!annotated):
          NoSize(mapTypeFFIResolved(inner, field, arg, p, true));
        case TInst(_.get() => {name: "SameSizeAs", pack: ["ammer", "ffi"]},
          [inner, TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]) if (!annotated):
          SameSizeAs(mapTypeFFIResolved(inner, field, arg, p, true), argName);
        case TInst(_.get() => {name: "SizeOf", pack: ["ammer", "ffi"]},
          [TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]) if (!annotated):
          SizeOf(argName);
        case TInst(_.get() => opaque, []) if (!annotated && opaque.superClass != null):
          switch (opaque.superClass.t.get()) {
            case {name: "Opaque", pack: ["ammer"]}:
              var id = opaqueId(opaque);
              if (!opaqueMap.exists(id))
                delayedBuildOpaque(id, opaque);
              Opaque(id, false);
            case _:
              null;
          }
        case _:
          null;
      });
      true;
    };

    if (ret == null) {
      if (arg == null)
        Context.fatalError('invalid FFI type for the return type of $field', p);
      else
        Context.fatalError('invalid FFI type for argument $arg of $field', p);
    }

    return ret;
  }

  /**
    Resolves a Haxe syntactic type at the given position, then maps it to its
    FFI type equivalent.
  **/
  static function mapTypeFFI(t:ComplexType, field:String, arg:String, p:Position):FFIType {
    return mapTypeFFIResolved(Context.resolveType(t, p), field, arg, p);
  }

  /**
    Registers the opaque types of a library.
  **/
  static function registerTypes(field:Field, f:Function):Void {
    function handle(t:FFIType):Void {
      switch (t) {
        case Opaque(id, _):
          if (!ctx.opaqueTypes.exists(id))
            ctx.opaqueTypes[id] = opaqueMap[id];
        case _:
      }
    }

    for (arg in f.args)
      handle(mapTypeFFI(arg.type, field.name, arg.name, field.pos));
    handle(mapTypeFFI(f.ret, field.name, null, field.pos));
  }

  /**
    Creates the `FFIMethod` corresponding to the given class method. Raises an
    error if the FFI types are incorrectly specified.
  **/
  static function createFFIMethod(field:Field, f:Function, nativePrefix:String, ?opaqueThis:String):FFIMethod {
    // null in the needsSizes and hasSizes arrays signifies the return
    var needsSizes:Array<String> = [];
    var hasSizes:Array<String> = [];

    // map arguments
    var argNames = f.args.map(a -> a.name);
    var ffiArgs = [
      for (arg in f.args) {
        if (arg.type == null)
          Context.fatalError('type required for argument ${arg.name} of ${field.name}', field.pos);
        var type = mapTypeFFI(arg.type, field.name, arg.name, field.pos);
        if (!type.isArgumentType())
          Context.fatalError('FFI type not allowed for argument ${arg.name} of ${field.name}', field.pos);
        if (type.needsSize()) {
          // a size specification would be ambiguous
          if (argNames.filter(a -> a == arg.name).length > 1)
            Context.fatalError('argument ${arg.name} of ${field.name} should have a unique identifier', field.pos);
          needsSizes.push(arg.name);
        }
        switch (type) {
          case NoSize(_):
            if (hasSizes.indexOf(arg.name) != -1)
              Context.fatalError('size of ${arg.name} is already specified in a prior argument', field.pos);
            hasSizes.push(arg.name);
          case SizeOf(arg):
            if (hasSizes.indexOf(arg) != -1)
              Context.fatalError('size of ${arg} is already specified in a prior argument', field.pos);
            hasSizes.push(arg);
          case SizeOfReturn:
            if (hasSizes.indexOf(null) != -1)
              Context.fatalError('size of return is already specified in a prior argument', field.pos);
            hasSizes.push(null);
          case _:
        }
        if (type == This) {
          if (opaqueThis == null)
            Context.fatalError('ammer.ffi.This can only be used in opaque type methods', field.pos);
          FFIType.Opaque(opaqueThis, true);
        } else
          type;
      }
    ];

    // map return type
    if (f.ret == null)
      Context.fatalError('return type required for ${field.name}', field.pos);
    var ffiRet = mapTypeFFI(f.ret, field.name, null, field.pos);
    if (!ffiRet.isReturnType())
      Context.fatalError('FFI type not allowed for argument return of ${field.name}', field.pos);
    if (ffiRet.needsSize())
      needsSizes.push(null);
    if (ffiRet == This) {
      if (opaqueThis == null)
        Context.fatalError('ammer.ffi.This can only be used in opaque type methods', field.pos);
      // TODO: does This as return type make sense?
      ffiRet = Opaque(opaqueThis, true);
    }

    // ensure all size requirements are satisfied
    for (need in needsSizes) {
      if (hasSizes.indexOf(need) == -1)
        if (need == null)
          Context.fatalError('size specification required for return of ${field.name}', field.pos);
        else
          Context.fatalError('size specification required for argument $need of ${field.name}', field.pos);
      hasSizes.remove(need);
    }
    // if (hasSizes.length > 0)
    //  Context.fatalError('superfluous sizes specified in ${field.name}', field.pos);

    var ffi = {
      name: field.name,
      native: nativePrefix + field.name,
      args: ffiArgs,
      ret: ffiRet,
      field: field
    }

    // handle metadata
    for (meta in Utils.meta(field.meta, ["native", "macroCall"])) {
      switch (meta) {
        case {id: "native", params: [{expr: EConst(CString(n))}]}:
          ffi.native = n;
        case _:
      }
    }

    return ffi;
  }

  static function parseMetadata():Void {
    for (meta in Utils.meta(ctx.implType.meta.get(), ["nativePrefix"])) {
      switch (meta) {
        case {id: "nativePrefix", params: [{expr: EConst(CString(n))}]}:
          ctx.nativePrefix = n;
        case _:
      }
    }
  }

  /**
    Creates the `FFIField` corresponding to the given class variable.
  **/
  static function createFFIVariable(field:Field, t:ComplexType, nativePrefix:String):FFIVariable {
    var type = mapTypeFFI(t, field.name, null, field.pos);

    if (!type.isVariableType())
      Context.fatalError('invalid type for ${field.name}', field.pos);

    if (!ctx.varCounter.exists(type))
      ctx.varCounter[type] = 0;
    var ffi = {
      name: field.name,
      index: ctx.varCounter[type]++,
      native: nativePrefix + field.name,
      type: type,
      field: field
    };

    // handle metadata
    for (meta in Utils.meta(field.meta, ["native"])) {
      switch (meta) {
        case {id: "native", params: [{expr: EConst(CString(n))}]}:
          ffi.native = n;
        case _:
      }
    }

    return ffi;
  }

  /**
    Creates FFI-mapped fields for the library class.
  **/
  static function createFFI():Void {
    for (field in ctx.implFields) {
      switch (field) {
        case {kind: FFun(f)}:
          registerTypes(field, f);
        case {kind: FVar(t, null)}:
          // pass
        case _:
          Context.fatalError("only methods and variables are supported in ammer library definitions", field.pos);
      }
    }
    for (field in ctx.implFields) {
      switch (field) {
        case {kind: FFun(f)}:
          ctx.ffiMethods.push(createFFIMethod(field, f, ctx.nativePrefix));
        case {kind: FVar(t, null)}:
          if (t == null)
            Context.fatalError('type annotation required for ${field.name}', field.pos);
          ctx.ffiVariables.push(createFFIVariable(field, t, ctx.nativePrefix));
        case _:
      }
    }
    for (id => opaque in ctx.opaqueTypes) {
      debug('opaque type $id for library ${ctx.libraryConfig.name}', "msg");
      for (field in opaque.originalFields) {
        debug(' -> field: ${field.name}', "msg");
        switch (field) {
          case {kind: FFun(f)}:
            ctx.ffiMethods.push(createFFIMethod(field, f, opaque.nativePrefix, id));
            field.access = [APrivate, AStatic];
            ctx.implFields.push(field);
          case _:
        }
      }
    }
    debug(ctx.ffiMethods, "gen-library");
    debug(ctx.ffiVariables, "gen-library");
  }

  /**
    Patches extern calls.
  **/
  static function patchImpl():Void {
    var patcher = (switch (config.platform) {
      case Eval: new ammer.patch.PatchEval(ctx);
      case Cpp: new ammer.patch.PatchCpp(ctx);
      case Hl: new ammer.patch.PatchHl(ctx);
      case Cross: new ammer.patch.PatchCross(ctx);
      case _: throw "!";
    });
    for (method in ctx.ffiMethods) {
      debug('patching ${method.name} (${method.native})', "msg");
      var f = (switch (method.field.kind) {
        case FFun(f): f;
        case _: throw "!";
      });
      inline function e(e:ExprDef):Expr {
        return {expr: e, pos: method.field.pos};
      }
      inline function id(s:String):Expr {
        return e(EConst(CIdent(s)));
      }
      var mctx:AmmerMethodPatchContext = {
        top: ctx,
        name: method.field.name,
        native: method.native,
        isMacro: false,
        argNames: f.args.map(a -> a.name),
        ffiArgs: method.args,
        ffiRet: method.ret,
        field: method.field,
        fn: f,
        callArgs: [for (i in 0...method.args.length) id('_arg${i}')],
        callExpr: null,
        wrapArgs: [],
        wrapExpr: null,
        externArgs: []
      };
      for (meta in Utils.meta(method.field.meta, ["native", "macroCall"])) {
        switch (meta) {
          case {id: "macroCall", params: []}:
            mctx.isMacro = true;
          case _:
        }
      }
      Utils.argNames = mctx.argNames;
      ctx.methodContexts.push(mctx);
      mctx.callExpr = e(ECall(macro $p{["ammer", "externs", ctx.externName, method.field.name]}, mctx.callArgs));
      mctx.wrapExpr = mctx.callExpr;
      var methodPatcher = patcher.visitMethod(mctx);
      (function mapReturn(t:FFIType):Void {
        switch (t) {
          case Bytes:
            mctx.wrapExpr = macro ammer.conv.Bytes.fromNative(cast ${mctx.wrapExpr}, _retSize);
          case String:
            mctx.wrapExpr = macro ammer.conv.CString.fromNative(${mctx.wrapExpr});
          case Opaque(oid, _):
            var implTypePath = opaqueMap[oid].implTypePath;
            mctx.wrapExpr = macro @:privateAccess new $implTypePath(${mctx.wrapExpr});
          case SameSizeAs(t, arg):
            mapReturn(t);
            mctx.wrapExpr = macro {
              var _retSize = $e{Utils.an(arg)}.length;
              ${mctx.wrapExpr};
            };
          case _:
        }
      })(method.ret);
      methodPatcher.visitReturn(method.ret, f.ret);
      // visit arguments in reverse so they may be removed from callExpr with splice
      for (ri in 0...method.args.length) {
        var i = method.args.length - ri - 1;
        f.args[i].type = mapFFIType(method.args[i]);
        (function mapArgument(t:FFIType):Void {
          switch (t) {
            case NoSize(t):
              mapArgument(t);
            case Bytes:
              mctx.callArgs[i] = macro($e{id('_arg${i}')} : ammer.conv.Bytes).toNative1();
            case String:
              mctx.callArgs[i] = macro($e{id('_arg${i}')} : ammer.conv.CString).toNative();
            case FFIType.Opaque(_, _):
              mctx.callArgs[i] = macro @:privateAccess $e{mctx.callArgs[i]}.ammerNative;
            case _:
          }
        })(method.args[i]);
        methodPatcher.visitArgument(i, method.args[i], f.args[i]);
      }
      mctx.wrapArgs.reverse();
      mctx.externArgs.reverse();
      methodPatcher.finish();
      if (config.platform == Cross) {
        f.expr = (switch (method.ret) {
          case Void: macro {};
          case Int | Float: macro return 0;
          case _: macro return null;
        });
      } else {
        if (method.ret == Void)
          f.expr = macro ${mctx.wrapExpr};
        else
          f.expr = macro return ${mctx.wrapExpr};
      }
      f.args = mctx.wrapArgs;
      f.ret = mapFFIType(method.ret);
    }
  }

  /**
    Creates an extern type for the library.
  **/
  static function createExtern():Void {
    var c = macro class AmmerExtern {};
    c.isExtern = ctx.externIsExtern;
    c.meta = ctx.externMeta;
    c.name = ctx.externName;
    c.pack = ["ammer", "externs"];
    c.fields = ctx.externFields;
    debugP(() -> printer.printTypeDefinition(c), "gen-library");
    Context.defineType(c);
  }

  /**
    Runs target-specific build actions after all libraries are processed.
    Callback to this is registered in `configure`.
  **/
  static function runBuild(_):Void {
    switch (config.platform) {
      case Eval:
        for (library in libraries)
          ammer.stub.StubEval.generate(config, library);
        ammer.build.BuildEval.build(config, libraries);
      case Hl:
        for (library in libraries)
          ammer.stub.StubHl.generate(config, library);
        ammer.build.BuildHl.build(config, libraries);
      case _:
    }
  }

  static function createLibraryConfig(libname:String, pos:Position):AmmerLibraryConfig {
    if (libraryMap.exists(libname))
      return libraryMap[libname];
    var config:AmmerLibraryConfig = {
      name: libname,
      includePath: getPath('ammer.lib.${libname}.include'),
      libraryPath: getPath('ammer.lib.${libname}.library'),
      headers: getDefine('ammer.lib.${libname}.headers', '${libname}.h').split(","),
      abi: (switch (getDefine('ammer.lib.${libname}.abi', "c")) {
        case "c": C;
        case "cpp": Cpp;
        case _: Context.fatalError('invalid value for ammer.lib.${libname}.abi', pos);
      }),
      contexts: []
    };
    libraries.push(config);
    return libraryMap[libname] = config;
  }

  /**
    Main entry point for each library.
  **/
  public static function build():Array<Field> {
    configure();
    var implType = Context.getLocalClass().get();
    var libname = (switch (implType.superClass.params[0]) {
      case TInst(_.get() => {kind: KExpr({expr: EConst(CString(libname))})}, []):
        libname;
      case _:
        throw Context.fatalError("ammer.Library type parameter should be a string", implType.pos);
    });
    debug('started ${implType.name} (library $libname)', "stage");
    var libraryConfig = createLibraryConfig(libname, implType.pos);
    var ctxIndex = libraryConfig.contexts.length;
    ctx = {
      index: ctxIndex,
      config: config,
      libraryConfig: libraryConfig,
      implType: implType,
      implFields: Context.getBuildFields(),
      externName: 'AmmerExtern_${libname}_${ctxIndex}',
      externFields: [],
      externIsExtern: true,
      externMeta: [],
      ffiMethods: [],
      ffiVariables: [],
      varCounter: [],
      nativePrefix: "",
      opaqueTypes: [],
      methodContexts: []
    };
    ctxStack.push(ctx);
    libraryConfig.contexts.push(ctx);
    libraryTypeMap[opaqueId(implType)] = ctx;
    Utils.posStack.push(implType.pos);
    parseMetadata();
    createFFI();
    patchImpl();
    createExtern();
    var ret = ctx.implFields;
    for (f in ret)
      debugP(() -> printer.printField(f), "gen-library");
    debug('finished ${implType.name} (library $libname)', "stage");
    ctxStack.pop();
    ctx = ctxStack.length > 0 ? ctxStack[ctxStack.length - 1] : null;
    Utils.posStack.pop();
    return ret;
  }

  static function opaqueId(t:ClassType):String {
    return '${t.pack.join(".")}.${t.module.split(".").pop()}.${t.name}';
  }

  static function delayedBuildOpaque(id:String, implType:ClassType):AmmerOpaqueContext {
    if (!opaqueMap.exists(id)) {
      if (!opaqueCache.exists(id))
        throw "!";

      var nativeName = implType.name;
      var nativePrefix = "";
      for (meta in Utils.meta(implType.meta.get(), ["native", "nativePrefix"])) {
        switch (meta) {
          case {id: "native", params: [{expr: EConst(CString(n))}]}:
            nativeName = n;
          case {id: "nativePrefix", params: [{expr: EConst(CString(n))}]}:
            nativePrefix = n;
          case _:
        }
      }

      var moduleName = implType.module.split(".").pop();
      var implTypePath:TypePath = (if (implType.name != moduleName)
        {pack: implType.pack, name: moduleName, sub: implType.name} else {pack: implType.pack, name: implType.name});

      opaques.push(opaqueMap[id] = {
        implType: implType,
        implTypePath: implTypePath,
        nativeName: nativeName,
        nativePrefix: nativePrefix,
        nativeType: (switch (config.platform) {
          case Hl:
            TPath({name: "Abstract", pack: ["hl"], params: [TPExpr({expr: EConst(CString(nativeName)), pos: implType.pos})]});
          case Cpp:
            var c = macro class OpaqueExtern {};
            c.isExtern = true;
            c.meta = [{name: ":native", params: [macro $v{nativeName}], pos: implType.pos}];
            c.name = 'AmmerExternOpaque_${opaqueCtr++}';
            c.pack = ["ammer", "externs"];
            Context.defineType(c);
            TPath({name: "Pointer", pack: ["cpp"], params: [TPType(TPath({name: c.name, pack: c.pack}))]});
          case _:
            throw "!";
        }),
        originalFields: opaqueCache[id].fields,
        library: opaqueCache[id].library,
        processed: null
      });
      opaqueCache.remove(id);
    }
    var opaqueCtx = opaqueMap[id];
    if (opaqueCtx.processed != null)
      return opaqueCtx;
    debug('finalising opaque $id', "stage");
    var native = opaqueCtx.nativeType;
    var retFields = (macro class Opaque {
      private var ammerNative:$native;

      private function new(native:$native) {
        this.ammerNative = native;
      }
    }).fields;
    for (field in opaqueCtx.originalFields) {
      switch (field) {
        case {kind: FFun(f), access: [APublic]}:
          var ffi = createFFIMethod(field, f, opaqueCtx.nativePrefix, id);
          var thisArg = ffi.args.filter(arg -> arg.match(Opaque(_, true))).length > 0;
          if (!thisArg)
            Context.fatalError("opaque type methods must have an ammer.ffi.This argument", field.pos);
          var library = (switch (opaqueCtx.library) {
            case TPath(tp): tp;
            case _: throw "!";
          });
          var libraryParts = library.pack.concat([library.name]).concat(library.sub != null ? [library.sub] : []);
          libraryParts.push(field.name);
          var libraryAccess = {expr: EConst(CIdent(libraryParts[0])), pos: field.pos};
          for (i in 1...libraryParts.length) {
            libraryAccess = {expr: EField(libraryAccess, libraryParts[i]), pos: field.pos};
          }
          var callArgs = [ for (i in 0...f.args.length) {
            switch (ffi.args[i]) {
              case Opaque(_, true): macro this;
              case _: macro $i{'_arg$i'};
            }
          } ];
          retFields.push({
            access: [APublic],
            kind: FFun({
              args: [ for (i in 0...f.args.length) {
                if (ffi.args[i].match(Opaque(_, true)))
                  continue;
                {
                  name: '_arg$i',
                  type: f.args[i].type,
                };
              } ],
              ret: f.ret,
              expr: macro return @:privateAccess $libraryAccess($a{callArgs})
            }),
            name: field.name,
            pos: field.pos
          });
        case _:
          Context.fatalError("only non-static methods are supported in ammer opaque type definitions", field.pos);
      }
    }
    debug('finished opaque $id', "stage");
    opaqueCtx.processed = retFields;
    return opaqueCtx;
  }

  public static function buildOpaque():Array<Field> {
    configure();
    var implType = Context.getLocalClass().get();
    var id = opaqueId(implType);
    debug('started opaque $id', "stage");
    var libraryCT = (switch (implType.superClass) {
      case {t: _.get() => {name: "Opaque", pack: ["ammer"]}, params: [libType = TInst(lib, [])]}:
        opaqueCache[id] = {fields: Context.getBuildFields(), library: Context.toComplexType(libType)};
        // ensure base library is typed
        lib.get();
      case _:
        throw "!";
    });
    var libraryCtx = libraryTypeMap[opaqueId(libraryCT)];
    var processed = delayedBuildOpaque(id, implType).processed;
    for (f in processed) {
      debugP(() -> printer.printField(f), "gen-opaque");
    }
    switch (config.platform) {
      case Cpp:
        var headerCode = [];
        for (header in libraryCtx.libraryConfig.headers)
          headerCode.push('#include <${header}>');
        implType.meta.add(
          ":headerCode",
          [{expr: EConst(CString(headerCode.join("\n"))), pos: implType.pos}],
          implType.pos
        );
        // TODO: ammer.patch.PatchCpp.patchOpaque(implType);
      case _:
    }
    return processed;
  }
}
