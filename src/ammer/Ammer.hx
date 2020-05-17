package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import ammer.Config.AmmerLibraryConfig;
import ammer.patch.PatchMethod;

using StringTools;

/**
  Main class for `ammer`. Handles common tasks and dispatches calls to
  target-specific stages.
**/
class Ammer {
  public static var config(default, null):Config;
  public static var typeMap:Map<String, AmmerTypeContext> = [];
  static var libraries:Array<AmmerLibraryConfig> = [];
  static var libraryMap:Map<String, AmmerLibraryConfig> = [];
  static var libraryContextMap:Map<String, AmmerContext> = [];
  static var types:Array<AmmerTypeContext> = [];
  static var typeCache:Map<String, {native:String, fields:Array<Field>, library:ComplexType}> = [];
  static var typeCtr = 0;
  public static var ctx:AmmerContext;
  static var ctxStack:Array<AmmerContext> = [];
  static var definedTypes:Array<TypeDefinition>;
  static var modifiedTypes:Array<{t:ClassType, fields:Array<Field>}>;

  /**
    Creates `config` object, runs some project-global tasks.
  **/
  static function configure():Void {
    // run only once
    if (config != null)
      return;

    // create config from defines
    config = new Config();

    // create build directories
    switch (config.platform) {
      case Cpp:
        Utils.ensureDirectory(config.output + "/ammer");
      case Eval:
        Utils.ensureDirectory(config.eval.build);
        Utils.ensureDirectory(config.eval.output);
      case Hl:
        Utils.ensureDirectory(config.hl.build);
        Utils.ensureDirectory(config.hl.output);
      case Lua:
        Utils.ensureDirectory(config.lua.build);
        Utils.ensureDirectory(config.lua.output);
      case _:
    }

    // register the build stage
    Context.onAfterTyping(runBuild);
  }

  static function defineType(c:TypeDefinition):Void {
    if (definedTypes != null)
      definedTypes.push(c);
    Context.defineType(c);
  }

  static function modifyType(t:ClassType, fields:Array<Field>):Void {
    if (modifiedTypes != null)
      modifiedTypes.push({t: t, fields: fields});
  }

  /**
    Registers the types of a library.
  **/
  static function registerTypes(field:Field, f:Function):Void {
    function handle(t:FFIType):Void {
      switch (t) {
        case LibType(id, _):
          if (!ctx.types.exists(id))
            ctx.types[id] = typeMap[id];
        case Closure(_, args, ret, _):
          for (a in args)
            handle(a);
          handle(ret);
        case _:
      }
    }

    for (i in 0...f.args.length)
      handle(FFITools.toFFIType(f.args[i].type, f.args.map(a -> a.name), field.pos, i));
    handle(FFITools.toFFIType(f.ret, f.args.map(a -> a.name), field.pos, null));
  }

  /**
    Creates the `FFIMethod` corresponding to the given class method. Raises an
    error if the FFI types are incorrectly specified.
  **/
  static function createFFIMethod(field:Field, f:Function, nativePrefix:String, ?typeThis:String):FFIMethod {
    var ffiFunc = FFITools.toFFITypeFunction(f.args, f.ret, f.args.map(a -> a.name), field.pos, typeThis);

    var ffi:FFIMethod = {
      name: field.name,
      uniqueName: field.name,
      native: nativePrefix + field.name,
      cPrereturn: null,
      cReturn: null,
      isMacro: false,
      args: ffiFunc.args,
      ret: ffiFunc.ret,
      field: field
    }

    // handle metadata
    for (meta in Utils.meta(field.meta, Utils.META_LIBRARY_METHOD)) {
      switch (meta) {
        case {id: "native", params: [{expr: EConst(CString(n))}]}:
          ffi.native = n;
        case {id: "c.prereturn", params: [{expr: EConst(CString(n))}]}:
          ffi.cPrereturn = n;
        case {id: "c.return", params: [{expr: EConst(CString(n))}]}:
          ffi.cReturn = n;
        case {id: "macroCall", params: []}:
          ffi.isMacro = true;
        case _:
      }
    }

    return ffi;
  }

  static function parseMetadata():Void {
    for (meta in Utils.meta(ctx.implType.meta.get(), Utils.META_LIBRARY_CLASS)) {
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
    var type = FFITools.toFFIType(t, [], field.pos, null);

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
    for (meta in Utils.meta(field.meta, Utils.META_LIBRARY_VARIABLE)) {
      switch (meta) {
        case {id: "native", params: [{expr: EConst(CString(n))}]}:
          ffi.native = n;
        case _:
      }
    }

    return ffi;
  }

  static function createFFIStructVariable(field:Field, t:ComplexType, nativePrefix:String):FFIStructVariable {
    var type = FFITools.toFFIType(t, [], field.pos, null);

    // TODO: check annotations make sense

    var ffi = {
      name: field.name,
      native: nativePrefix + field.name,
      type: type,
      complexType: type.toComplexType(),
      field: field,
      getField: null,
      setField: null
    };

    // handle metadata
    for (meta in Utils.meta(field.meta, Utils.META_LIBRARY_VARIABLE)) {
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
    for (id => type in ctx.types) {
      Debug.log('type $id for library ${ctx.libraryConfig.name}', "msg");
      for (method in type.ffiMethods) {
        method.uniqueName = Utils.typeIdField(type.implType) + method.name;
        Debug.log(' -> field: ${method.field.name} (${method.uniqueName})', "msg");
        ctx.ffiMethods.push(method);
        var libraryField:Field = {
          access: [APrivate, AStatic],
          kind: FFun({ret: null, expr: null, args: null}),
          name: Utils.typeIdField(type.implType) + method.field.name,
          pos: method.field.pos
        };
        method.field = libraryField;
        ctx.implFields.push(libraryField);
      }
    }
    Debug.log(ctx.ffiMethods, "gen-library");
    Debug.log(ctx.ffiVariables, "gen-library");
  }

  /**
    Patches extern calls.
  **/
  static function patchImpl():Void {
    switch (config.platform) {
      case Eval: ammer.patch.PatchEval.patch(ctx);
      case Cpp: ammer.patch.PatchCpp.patch(ctx);
      case Hl: ammer.patch.PatchHl.patch(ctx);
      case Lua: ammer.patch.PatchLua.patch(ctx);
      case Cross: ammer.patch.PatchCross.patch(ctx);
      case _: throw "!";
    }
    for (method in ctx.ffiMethods) Utils.withPos(() -> {
      Debug.log('patching ${method.name} (${method.native})', "msg");
      var f = (switch (method.field.kind) {
        case FFun(f): f;
        case _: throw "!";
      });

      // normalise derivable arguments
      var norm = method.args.map(FFITools.normalise);

      // generate signature for calls from Haxe code
      f.args = [ for (i in 0...method.args.length) switch (norm[i]) {
        case Derived(_, _) | SizeOfReturn: continue;
        case ClosureDataUse: continue;
        case ClosureData(_): continue;
        case t: {
          name: '_arg$i',
          type: t.toComplexType()
        };
      } ];
      f.ret = method.ret.toComplexType();

      // apply common patches
      var mctx:AmmerMethodPatchContext = {
        top: ctx,
        ffi: method,
        callArgs: [ for (i in 0...method.args.length) switch (norm[i]) {
          case Derived(gen, _): gen(Utils.arg);
          case SizeOfReturn: Utils.id("_retSize");
          case _: Utils.arg(i);
        } ],
        callExpr: null,
        wrapExpr: null
      };
      ctx.methodContexts.push(mctx);
      mctx.callExpr = macro $p{["ammer", "externs", ctx.externName, method.uniqueName]}($a{mctx.callArgs});
      mctx.wrapExpr = mctx.callExpr;

      // common patches
      mctx.wrapExpr = PatchMethod.commonPatchReturn(mctx.wrapExpr, method.ret);
      for (i in 0...method.args.length) {
        mctx.callArgs[i] = PatchMethod.commonPatchArgument(mctx.callArgs[i], method.args[i]);
      }

      // apply platform-specific patches
      var methodPatcher = (switch (config.platform) {
        case Eval: new ammer.patch.PatchEval.PatchEvalMethod(mctx);
        case Cpp: new ammer.patch.PatchCpp.PatchCppMethod(mctx);
        case Hl: new ammer.patch.PatchHl.PatchHlMethod(mctx);
        case Lua: new ammer.patch.PatchLua.PatchLuaMethod(mctx);
        case Cross: new ammer.patch.PatchCross.PatchCrossMethod(mctx);
        case _: throw "!";
      });
      for (i in 0...method.args.length) {
        methodPatcher.visitArgument(i, method.args[i]);
      }
      methodPatcher.finish();

      // wrap up
      if (config.platform == Cross) {
        f.expr = macro throw "";
      } else {
        if (method.ret == Void)
          f.expr = macro ${mctx.wrapExpr};
        else
          f.expr = macro return ${mctx.wrapExpr};
      }
    }, method.field.pos);
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
    Debug.logP(() -> Debug.typeDefinition(c), "gen-library");
    defineType(c);
  }

  /**
    Runs target-specific build actions after all libraries are processed.
    Callback to this is registered in `configure`.
  **/
  static function runBuild(_):Void {
    switch (config.platform) {
      case Cpp:
        for (library in libraries)
          ammer.stub.StubCpp.generate(config, library);
        // no build process
      case Eval:
        for (library in libraries)
          ammer.stub.StubEval.generate(config, library);
        ammer.build.BuildEval.build(config, libraries);
      case Hl:
        for (library in libraries)
          ammer.stub.StubHl.generate(config, library);
        ammer.build.BuildHl.build(config, libraries);
      case Lua:
        for (library in libraries)
          ammer.stub.StubLua.generate(config, library);
        ammer.build.BuildLua.build(config, libraries);
      case _:
    }
  }

  static function createLibraryConfig(libname:String, pos:Position):AmmerLibraryConfig {
    if (libraryMap.exists(libname))
      return libraryMap[libname];
    var config:AmmerLibraryConfig = {
      name: libname,
      includePath: config.getPath('ammer.lib.${libname}.include'),
      libraryPath: config.getPath('ammer.lib.${libname}.library'),
      headers: config.getDefine('ammer.lib.${libname}.headers', '${libname}.h').split(","),
      abi: config.getEnum('ammer.lib.${libname}.abi', [
        "c" => C,
        "cpp" => Cpp
      ], C),
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
    Debug.log('started ${implType.name} (library $libname)', "stage");
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
      closureTypes: [],
      nativePrefix: "",
      types: [],
      methodContexts: []
    };
    ctxStack.push(ctx);
    libraryConfig.contexts.push(ctx);
    libraryContextMap[Utils.typeId(implType)] = ctx;
    Utils.posStack.push(implType.pos);
    parseMetadata();
    createFFI();
    patchImpl();
    createExtern();
    var ret = ctx.implFields;
    for (f in ret)
      Debug.logP(() -> Debug.field(f), "gen-library");
    Debug.log('finished ${implType.name} (library $libname)', "stage");
    modifyType(ctx.implType, ret);
    ctxStack.pop();
    ctx = ctxStack.length > 0 ? ctxStack[ctxStack.length - 1] : null;
    Utils.posStack.pop();
    return ret;
  }

  public static function delayedBuildType(id:String, implType:ClassType):AmmerTypeContext {
    var moduleName = implType.module.split(".").pop();
    var implTypePath:TypePath = (if (implType.name != moduleName)
        {pack: implType.pack, name: moduleName, sub: implType.name}
      else
        {pack: implType.pack, name: implType.name});

    if (!typeMap.exists(id)) {
      if (!typeCache.exists(id))
        throw "!";

      var nativeName = typeCache[id].native;
      var nativePrefix = "";
      var isStruct = false;
      for (meta in Utils.meta(implType.meta.get(), Utils.META_TYPE_CLASS)) {
        switch (meta) {
          case {id: "nativePrefix", params: [{expr: EConst(CString(n))}]}:
            nativePrefix = n;
          case {id: "struct", params: []}:
            isStruct = true;
          case _:
        }
      }

      types.push(typeMap[id] = {
        implType: implType,
        implTypePath: implTypePath,
        nativeName: nativeName,
        nativePrefix: nativePrefix,
        nativeType: (switch (config.platform) {
          case Hl:
            TPath({name: "Abstract", pack: ["hl"], params: [TPExpr({expr: EConst(CString(nativeName)), pos: implType.pos})]});
          case Cpp:
            var c = macro class LibTypeExtern {};
            c.isExtern = true;
            c.meta = [{name: ":native", params: [macro $v{nativeName}], pos: implType.pos}];
            c.name = 'AmmerExternType_${typeCtr++}';
            c.pack = ["ammer", "externs"];
            defineType(c);
            TPath({name: "Pointer", pack: ["cpp"], params: [TPType(TPath({name: c.name, pack: c.pack}))]});
          case Lua:
            TPath({name: "UserData", pack: ["lua"], params: []});
          case _:
            throw "!";
        }),
        originalFields: typeCache[id].fields,
        library: typeCache[id].library,
        processed: null,
        isStruct: isStruct,
        ffiMethods: [],
        ffiVariables: [],
        libraryCtx: null
      });
      typeCache.remove(id);
    }
    var typeCtx = typeMap[id];
    if (typeCtx.processed != null)
      return typeCtx;
    Debug.log('finalising type $id', "stage");
    var native = typeCtx.nativeType;
    var retFields = (macro class LibType {
      private var ammerNative:$native;

      private function new(native:$native) {
        this.ammerNative = native;
      }

      public static function nullPointer() {
        return new $implTypePath(null);
      }
    }).fields;
    var library = (switch (typeCtx.library) {
      case TPath(tp): tp;
      case _: throw "!";
    });
    var libraryParts = library.pack.concat([library.name]).concat(library.sub != null ? [library.sub] : []);
    var idField = Utils.typeIdField(typeCtx.implType);
    function accessLibrary(field:String, ?pos:Position):Expr {
      if (pos == null)
        pos = typeCtx.implType.pos;
      var fieldParts = libraryParts.concat([idField + field]);
      var fieldAccess = {expr: EConst(CIdent(fieldParts[0])), pos: pos};
      for (i in 1...fieldParts.length) {
        fieldAccess = {expr: EField(fieldAccess, fieldParts[i]), pos: pos};
      }
      return fieldAccess;
    }
    if (typeCtx.isStruct) {
      // generate alloc and free if the type is marked with ammer.struct
      typeCtx.ffiMethods.push({
        name: "alloc",
        uniqueName: "alloc",
        native: "",
        cPrereturn: null,
        cReturn: '(${typeCtx.nativeName} *)calloc(sizeof(${typeCtx.nativeName}), 1)',
        isMacro: false,
        args: [],
        ret: LibType(id, false),
        field: {
          access: [],
          kind: FFun({args: [], ret: null, expr: null}),
          name: "alloc",
          pos: typeCtx.implType.pos
        }
      });
      retFields.push({
        access: [APublic, AStatic],
        kind: FFun({
          args: [],
          ret: TPath(implTypePath),
          expr: macro return @:privateAccess $e{accessLibrary("alloc")}()
        }),
        name: "alloc",
        pos: typeCtx.implType.pos
      });
      typeCtx.ffiMethods.push({
        name: "free",
        uniqueName: "free",
        native: "",
        cPrereturn: null,
        cReturn: "free(arg_0)",
        isMacro: false,
        args: [LibType(id, true)],
        ret: Void,
        field: {
          access: [],
          kind: FFun({args: [], ret: null, expr: null}),
          name: "free",
          pos: typeCtx.implType.pos
        }
      });
      retFields.push({
        access: [APublic],
        kind: FFun({
          args: [],
          ret: (macro : Void),
          expr: macro @:privateAccess $e{accessLibrary("free")}(this)
        }),
        name: "free",
        pos: typeCtx.implType.pos
      });
    }
    for (field in typeCtx.originalFields) {
      switch (field) {
        case {kind: FFun(f), access: [APublic]}:
          registerTypes(field, f);
          var ffi = createFFIMethod(field, f, typeCtx.nativePrefix, id);
          var thisArg = ffi.args.filter(arg -> arg.match(LibType(_, true))).length > 0;
          if (!thisArg)
            Context.fatalError("type methods must have an ammer.ffi.This argument", field.pos);
          var norm = ffi.args.map(FFITools.normalise);
          var signArgs = [ for (i in 0...f.args.length) {
            name: '_arg$i',
            type: (switch (norm[i]) {
              case LibType(_, true): continue;
              case Derived(_) | SizeOfReturn: continue;
              case t: t.toComplexType();
            })
          } ];
          var callArgs = [ for (i in 0...f.args.length) switch (norm[i]) {
            case LibType(_, true): macro this;
            case Derived(_) | SizeOfReturn: continue;
            case _: Utils.arg(i);
          } ];
          typeCtx.ffiMethods.push(ffi);
          retFields.push({
            access: [APublic],
            kind: FFun({
              args: signArgs,
              ret: ffi.ret.toComplexType(),
              expr: macro return @:privateAccess $e{accessLibrary(field.name, field.pos)}($a{callArgs})
            }),
            name: field.name,
            pos: field.pos
          });
        case {kind: FFun(_)}:
          Context.fatalError("only non-static public methods are supported in ammer type definitions", field.pos);
        case {kind: FVar(ct, null), access: [APublic]}:
          var ffi = createFFIStructVariable(field, ct, typeCtx.nativePrefix);
          typeCtx.ffiVariables.push(ffi);
          // ClosureDataUse is only visible in ffiVariables (for stub access)
          if (ffi.type == ClosureDataUse)
            continue;
          var ffiGet:FFIMethod = {
            name: 'get_${field.name}',
            uniqueName: 'get_${field.name}',
            native: "",
            cPrereturn: null,
            cReturn: 'arg_0->${ffi.native}',
            isMacro: false,
            args: [LibType(id, true)],
            ret: ffi.type,
            field: null
          };
          typeCtx.ffiMethods.push(ffiGet);
          retFields.push(ffi.getField = ffiGet.field = {
            access: [AInline],
            kind: FFun({
              args: [],
              ret: ffi.complexType,
              expr: macro return @:privateAccess $e{accessLibrary('get_${field.name}', field.pos)}(this)
            }),
            name: 'get_${field.name}',
            pos: field.pos
          });
          var ffiSet:FFIMethod = {
            name: 'set_${field.name}',
            uniqueName: 'set_${field.name}',
            native: "",
            cPrereturn: null,
            cReturn: 'arg_0->${ffi.native} = arg_1',
            isMacro: false,
            args: [LibType(id, true), ffi.type],
            ret: Void,
            field: null
          };
          typeCtx.ffiMethods.push(ffiSet);
          retFields.push(ffi.setField = ffiSet.field = {
            access: [AInline],
            kind: FFun({
              args: [{name: "val", type: ffi.complexType}],
              ret: ffi.complexType,
              expr: macro {
                @:privateAccess $e{accessLibrary('set_${field.name}', field.pos)}(this, val);
                return val;
              }
            }),
            name: 'set_${field.name}',
            pos: field.pos
          });
          retFields.push({
            access: [APublic],
            kind: FProp("get", "set", ffi.complexType, null),
            name: field.name,
            pos: field.pos
          });
        case {kind: FVar(_, _)}:
          Context.fatalError("only non-static public variables are supported in ammer type definitions", field.pos);
        case _:
          Context.fatalError("invalid field in ammer type definition", field.pos);
      }
    }
    Debug.log('finished type $id', "stage");
    typeCtx.processed = retFields;
    return typeCtx;
  }

  public static function buildType(pointer:Bool):Array<Field> {
    configure();
    var implType = Context.getLocalClass().get();
    var id = Utils.typeId(implType);
    Debug.log('started type $id', "stage");
    var libraryCT = (switch (implType.superClass) {
      case {t: _.get() => {name: "PointerProcessed", pack: ["ammer"]}, params: [TInst(_.get() => {kind: KExpr({expr: EConst(CString(native))})}, []), libType = TInst(lib, [])]}:
        typeCache[id] = {native: native, fields: Context.getBuildFields(), library: Context.toComplexType(libType)};
        // ensure base library is typed
        lib.get();
      case _:
        throw "!";
    });
    var ctx = delayedBuildType(id, implType);
    ctx.libraryCtx = libraryContextMap[Utils.typeId(libraryCT)];
    switch (config.platform) {
      // case Eval: ammer.patch.PatchEval.patchType(ctx);
      case Cpp: ammer.patch.PatchCpp.patchType(ctx);
      // case Hl: ammer.patch.PatchHl.patchType(ctx);
      // case Cross: ammer.patch.PatchCross.patchType(ctx);
      case _:
    }
    for (f in ctx.processed) {
      Debug.logP(() -> Debug.field(f), "gen-type");
    }
    modifyType(ctx.implType, ctx.processed);
    return ctx.processed;
  }
}
