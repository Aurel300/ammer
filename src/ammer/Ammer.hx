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
  public static var typeCache:Map<String, {native:String, fields:Array<Field>, library:ComplexType, kind:SubtypeKind}> = [];
  public static var ctx:AmmerContext;
  static var libraries:Array<AmmerLibraryConfig> = [];
  static var libraryMap:Map<String, AmmerLibraryConfig> = [];
  static var libraryContextMap:Map<String, AmmerContext> = [];
  static var types:Array<AmmerTypeContext> = [];
  static var typeCtr = 0;
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

  public static function defineType(c:TypeDefinition):Void {
    if (definedTypes != null)
      definedTypes.push(c);
    Context.defineType(c);
  }

  static function modifyType(t:ClassType, fields:Array<Field>):Void {
    if (modifiedTypes != null)
      modifiedTypes.push({t: t, fields: fields});
  }

  static function registerType(t:FFIType):Void {
    switch (t) {
      case LibType(t, _) | LibIntEnum(t, _) | LibSub(t):
        if (ctx == null || t == null) {
          Context.fatalError("context loss (make sure classes are linked properly with @:ammer.sub)", Context.currentPos());
        }
        ctx.types[t.id] = t;
      case Closure(_, args, ret, _):
        for (a in args)
          registerType(a);
        registerType(ret);
      case _:
    }
  }

  /**
    Registers the types of a library.
  **/
  static function registerTypes(field:Field, f:Function, ?typeThis:String):Void {
    var ffi = FFITools.toFFITypeFunctionF(field, f, typeThis);
    for (arg in ffi.args)
      registerType(arg);
    registerType(ffi.ret);
  }

  /**
    Creates the `FFIMethod` corresponding to the given class method. Raises an
    error if the FFI types are incorrectly specified.
  **/
  static function createFFIMethod(field:Field, f:Function, nativePrefix:String, ?typeThis:String):FFIMethod {
    var ffiFunc = FFITools.toFFITypeFunctionF(field, f, typeThis);

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
        case {id: "sub", params: [e]}:
          var ct = Utils.extractComplexType(e);
          ctx.subtypes.push(ct);
        case _:
      }
    }
  }

  /**
    Creates the `FFIConstant` corresponding to the given `static var`.
  **/
  static function createFFIConstant(field:Field, t:ComplexType, nativePrefix:String):FFIConstant {
    var type = FFITools.toFFITypeVariable(field, t);

    if (!type.isVariableType())
      Context.fatalError('invalid type for ${field.name}', field.pos);

    var ffi = {
      name: field.name,
      uniqueName: null,
      index: -1,
      native: nativePrefix + field.name,
      type: type,
      nativeType: (switch (type) {
        case LibIntEnum(_, _): FFIType.Int;
        case _: type;
      }),
      field: field,
      target: null
    };

    // handle metadata
    for (meta in Utils.meta(field.meta, Utils.META_LIBRARY_VARIABLE)) {
      switch (meta) {
        case {id: "native", params: [{expr: EConst(CString(n))}]}:
          ffi.native = n;
        case _:
      }
    }

    // register constant index
    if (!ctx.ffiConstants.exists(ffi.nativeType))
      ctx.ffiConstants[ffi.nativeType] = [];
    ffi.index = ctx.ffiConstants[ffi.nativeType].length;
    ctx.ffiConstants[ffi.nativeType].push(ffi);

    var t = FFITools.CONSTANT_TYPES_MAP[ffi.nativeType];
    var values = macro @:privateAccess $p{Utils.access(ctx.implType).concat(['ammer_g_${t.name}_values'])}();

    // create read-only field
    ffi.field.kind = (switch [ffi.field.kind, ffi.type] {
      case [FVar(vt, _), LibIntEnum(t, _)]:
        var implTypePath = t.implTypePath;
        FProp("default", "never", vt, macro @:privateAccess new $implTypePath($values[$v{ffi.index}]));
      case [FVar(vt, _), String]:
        FProp("default", "never", vt, macro ammer.conv.CString.fromNative($values[$v{ffi.index}]));
      case [FVar(vt, _), _]:
        FProp("default", "never", vt, macro $values[$v{ffi.index}]);
      case _: throw "!";
    });

    return ffi;
  }

  /**
    Creates the `FFIVariable` corresponding to the given `var`.
  **/
  static function createFFIVariable(field:Field, t:ComplexType, nativePrefix:String):FFIVariable {
    var type = FFITools.toFFIType(t, {
      pos: field.pos,
      parent: null,
      type: LibType
    });

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
          if (t == null)
            Context.fatalError('type annotation required for ${field.name}', field.pos);
        case _:
          Context.fatalError("properties are not supported in ammer library definitions", field.pos);
      }
    }
    for (type in ctx.subtypes) {
      registerType(FFITools.toFFIType(type, {
        pos: ctx.implType.pos,
        parent: null,
        type: None
      }));
    }
    for (field in ctx.implFields) {
      switch (field) {
        case {kind: FFun(f)}:
          ctx.ffiMethods.push(createFFIMethod(field, f, ctx.nativePrefix));
        case {kind: FVar(t, null)}:
          var const = createFFIConstant(field, t, ctx.nativePrefix);
          const.target = {
            pack: ctx.implType.pack,
            module: ctx.implType.name,
            cls: ctx.implType.name,
            field: field.name
          };
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
      for (const in type.ffiConstants) {
        const.uniqueName = Utils.typeIdField(type.implType) + const.name;
        Debug.log(' -> field: ${const.field.name} (${const.uniqueName})', "msg");
      }
    }
    Debug.log(ctx.ffiMethods, "gen-library");
    Debug.log(ctx.ffiConstants, "gen-library");
  }

  /**
    Patches extern calls.
  **/
  static function patchImpl():Void {
    var externPath = ["ammer", "externs", ctx.externName];
    for (t in FFITools.CONSTANT_TYPES) {
      var consts = ctx.ffiConstants[t.ffi];
      if (consts == null || consts.length == 0)
        continue;
      ctx.implFields.push({
        access: [AStatic],
        kind: FVar(null, macro null),
        name: 'ammer_g_${t.name}_cache',
        pos: ctx.implType.pos
      });
      var cache = macro $p{Utils.access(ctx.implType).concat(['ammer_g_${t.name}_cache'])};
      ctx.implFields.push({
        access: [AStatic],
        kind: FFun({
          ret: null,
          args: [],
          expr: macro @:privateAccess {
            if ($cache == null)
              $cache = $p{externPath.concat(['ammer_g_${t.name}'])}();
            return $cache;
          }
        }),
        name: 'ammer_g_${t.name}_values',
        pos: ctx.implType.pos
      });
    }
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
        case Unsupported(_): continue;
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
          case Derived(e, _): e;
          case SizeOfReturn: Utils.id("_retSize");
          case _: Utils.arg(i);
        } ],
        callExpr: null,
        wrapExpr: null
      };
      ctx.methodContexts.push(mctx);
      mctx.callExpr = macro $p{externPath.concat([method.uniqueName])}($a{mctx.callArgs});
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

  static function createLibraryConfig(libname:String):AmmerLibraryConfig {
    if (libraryMap.exists(libname))
      return libraryMap[libname];
    var config:AmmerLibraryConfig = {
      name: libname,
      linkName: config.getDefine('ammer.lib.${libname}.linkName', libname).split(","),
      includePath: config.getPath('ammer.lib.${libname}.include'),
      libraryPath: config.getPath('ammer.lib.${libname}.library'),
      headers: config.getDefine('ammer.lib.${libname}.headers', '${libname}.h').split(","),
      abi: config.getEnum('ammer.lib.${libname}.abi', [
        "c" => ammer.Config.AmmerAbi.C,
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
    var implComplexType = TPath({
      name: implType.module.split(".").pop(),
      pack: implType.pack,
      sub: implType.name,
    });
    var libname = (switch (implType.superClass.params[0]) {
      case TInst(_.get() => {kind: KExpr({expr: EConst(CString(libname))})}, []):
        libname;
      case _:
        throw Context.fatalError("ammer.Library type parameter should be a string", implType.pos);
    });
    Debug.log('started ${implType.name} (library $libname)', "stage");
    var libraryConfig = createLibraryConfig(libname);
    var ctxIndex = libraryConfig.contexts.length;
    ctx = {
      index: ctxIndex,
      config: config,
      subtypes: [],
      libraryConfig: libraryConfig,
      implType: implType,
      implComplexType: implComplexType,
      implFields: Context.getBuildFields(),
      externName: 'AmmerExtern_${libname}_${ctxIndex}',
      externFields: [],
      externIsExtern: true,
      externMeta: [],
      ffiMethods: [],
      ffiConstants: [],
      closureTypes: [],
      arrayTypes: [],
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

  public static function delayedBuildType(id:String, implType:ClassType, subtypeKind:SubtypeKind):AmmerTypeContext {
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
            if (!subtypeKind.match(Pointer(_)))
              Context.fatalError("ammer.struct is only valid on library data types", implType.pos);
            isStruct = true;
          case _:
        }
      }

      types.push(typeMap[id] = {
        id: id,
        implType: implType,
        implTypePath: implTypePath,
        nativeName: nativeName,
        nativePrefix: nativePrefix,
        nativeType: (switch [subtypeKind, config.platform] {
          case [Pointer(_), Hl]:
            TPath({name: "Abstract", pack: ["hl"], params: [TPExpr({expr: EConst(CString(nativeName)), pos: implType.pos})]});
          case [Pointer(star), Cpp]:
            var c = macro class LibTypeExtern {};
            c.isExtern = true;
            c.meta = [{name: ":native", params: [macro $v{nativeName}], pos: implType.pos}];
            c.name = 'AmmerExternType_${typeCtr++}';
            c.pack = ["ammer", "externs"];
            defineType(c);
            var externType:ComplexType = TPath({name: c.name, pack: c.pack});
            star
              ? TPath({name: "Pointer", pack: ["cpp"], params: [TPType(externType)]})
              : TPath({name: "Struct", pack: ["cpp"], params: [TPType(externType)]});
          case [Pointer(_), Lua]:
            TPath({name: "UserData", pack: ["lua"], params: []});
          case [Pointer(_), _]:
            throw "!";
          case [IntEnum, _]:
            TPath({name: "Int", pack: [], params: []});
          case [Sublibrary, _]:
            (macro : Void);
        }),
        originalFields: typeCache[id].fields,
        library: typeCache[id].library,
        processed: null,
        isStruct: isStruct,
        kind: subtypeKind,
        ffiMethods: [],
        ffiConstants: [],
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
    var retFields:Array<Field> = [];
    switch (subtypeKind) {
      case Pointer(_):
        retFields = retFields.concat((macro class LibType {
          private var ammerNative:$native;

          private function new(native:$native) {
            this.ammerNative = native;
          }

          public static function nullPointer() {
            return new $implTypePath(null);
          }
        }).fields);
      case IntEnum:
        var impl = TPath(typeCtx.implTypePath);
        retFields = retFields.concat((macro class LibType {
          private static var ammerNativeInstances:Map<Int, $impl>;

          private static function ammerFromNative(native:$native) {
            if (ammerNativeInstances == null) {
              ammerNativeInstances = [];
            }
            return ammerNativeInstances.exists(native)
              ? ammerNativeInstances[native]
              : new $implTypePath(native);
          }

          private var ammerNative:$native;

          private function new(native:$native) {
            this.ammerNative = native;
            if (ammerNativeInstances == null) {
              ammerNativeInstances = [];
            }
            ammerNativeInstances[native] = this;
          }

          public function asInt():Int {
            return ammerNative;
          }
        }).fields);
      case Sublibrary:
        // nothing to add
    }
    var library = (switch (typeCtx.library) {
      case TPath(tp): tp;
      case _: throw "!";
    });
    var libraryParts = library.pack.concat([library.name]).concat(library.sub != null ? [library.sub] : []);
    var idField = Utils.typeIdField(typeCtx.implType);
    Utils.posStack.push(typeCtx.implType.pos);
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
    if (subtypeKind.match(Pointer(_)) && typeCtx.isStruct) {
      // generate alloc and free if the type is marked with ammer.struct
      typeCtx.ffiMethods.push({
        name: "alloc",
        uniqueName: "alloc",
        native: "",
        cPrereturn: null,
        cReturn: '(${typeCtx.nativeName} *)calloc(sizeof(${typeCtx.nativeName}), 1)',
        isMacro: false,
        args: [],
        ret: LibType(typeCtx, false),
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
        args: [LibType(typeCtx, true)],
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
    // process "virtual" fields
    var fieldSizes = new Map<String, Expr>();
    for (field in typeCtx.originalFields) {
      switch (field) {
        case {kind: FVar(ct, null), access: [APublic]}:
          var ffi = createFFIVariable(field, ct, typeCtx.nativePrefix);
          switch (ffi.type) {
            case SizeOfField(target):
              fieldSizes[target] = macro $p{["_arg0", field.name]};
            case _:
          }
        case _:
      }
    }
    // process remaining fields
    for (field in typeCtx.originalFields) {
      switch (field) {
        case {kind: FFun(f), access: access}:
          if (access.indexOf(APublic) == -1)
            Context.fatalError("type methods must be public", field.pos);
          var isInstance = access.indexOf(AStatic) == -1;
          registerTypes(field, f, id);
          var ffi = createFFIMethod(field, f, typeCtx.nativePrefix, id);
          var thisArgs = ffi.args.filter(arg -> arg.match(
            LibType(_, true) | Nested(LibType(_, true)) | LibIntEnum(_, true)
          )).length;
          if (isInstance) {
            if (thisArgs != 1)
              Context.fatalError("non-static type methods must have exactly one ammer.ffi.This argument", field.pos);
          } else {
            if (thisArgs != 0)
              Context.fatalError("static type methods must have no ammer.ffi.This arguments", field.pos);
          }
          var norm = ffi.args.map(FFITools.normalise);
          var signArgs = [ for (i in 0...f.args.length) {
            name: '_arg$i',
            type: (switch (norm[i]) {
              case LibType(_, true): continue;
              case Nested(LibType(_, true)): continue;
              case LibIntEnum(_, true): continue;
              case Derived(_) | SizeOfReturn: continue;
              case ClosureData(_): continue;
              case Unsupported(_): continue;
              case t: t.toComplexType();
            })
          } ];
          var callArgs = [ for (i in 0...f.args.length) switch (norm[i]) {
            case LibType(_, true): macro this;
            case Nested(LibType(_, true)): macro this;
            case LibIntEnum(_, true): macro this;
            case Derived(_) | SizeOfReturn: continue;
            case ClosureData(_): continue;
            case Unsupported(_): continue;
            case _: Utils.arg(i);
          } ];
          typeCtx.ffiMethods.push(ffi);
          retFields.push({
            access: isInstance ? [APublic] : [APublic, AStatic],
            kind: FFun({
              args: signArgs,
              ret: ffi.ret.toComplexType(),
              expr: macro return @:privateAccess $e{accessLibrary(field.name, field.pos)}($a{callArgs})
            }),
            name: field.name,
            pos: field.pos
          });
        case {kind: FVar(ct, null), access: [APublic]}:
          var ffi = createFFIVariable(field, ct, typeCtx.nativePrefix);
          typeCtx.ffiVariables.push(ffi);
          switch (ffi.type) {
            case ClosureDataUse:
              // ClosureDataUse is only visible in ffiVariables (for stub access)
              continue;
            case _:
          }
          var isNested = ffi.type.match(Nested(LibType(_, _)));
          var isReadOnly = ffi.type.match(ArrayDynamic(_, _) | ArrayFixed(_, _, _));
          if (ffi.type.needsSize()) {
            if (!fieldSizes.exists(field.name))
              Context.fatalError("field requires size", field.pos);
            ffi.type = WithSize(fieldSizes[field.name], ffi.type);
          }
          var ffiGet:FFIMethod = {
            name: 'get_${field.name}',
            uniqueName: 'get_${field.name}',
            native: "",
            cPrereturn: null,
            cReturn: (isNested ? "&" : "") + 'arg_0->${ffi.native}',
            isMacro: false,
            args: [LibType(typeCtx, true)],
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
          if (!isReadOnly) {
            var ffiSet:FFIMethod = {
              name: 'set_${field.name}',
              uniqueName: 'set_${field.name}',
              native: "",
              cPrereturn: null,
              cReturn: 'arg_0->${ffi.native} = ${isNested ? "*" : ""}arg_1',
              isMacro: false,
              args: [LibType(typeCtx, true), ffi.type],
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
          }
          retFields.push({
            access: [APublic],
            kind: FProp("get", isReadOnly ? "never" : "set", ffi.complexType, null),
            name: field.name,
            pos: field.pos
          });
        case {kind: FVar(ct, null), access: [APublic, AStatic]}:
          var ffi = createFFIConstant(field, ct, typeCtx.nativePrefix);
          ffi.target = {
            pack: implType.pack,
            module: implType.module.split(".").pop(),
            cls: implType.name,
            field: field.name
          };
          typeCtx.ffiConstants.push(ffi);
          retFields.push(field);
        case {kind: FVar(_, _)}:
          Context.fatalError("only public variables are supported in ammer type definitions", field.pos);
        case _:
          Context.fatalError("invalid field in ammer type definition", field.pos);
      }
    }
    Utils.posStack.pop();
    Debug.log('finished type $id', "stage");
    typeCtx.processed = retFields;
    return typeCtx;
  }

  public static function buildType():Array<Field> {
    configure();
    var implType = Context.getLocalClass().get();
    var id = Utils.typeId(implType);
    var subtypeKind = SubtypeKind.Pointer(true);
    Debug.log('started type $id', "stage");
    // add type into cache
    // ensure base library is typed
    var libraryCT = (switch (implType.superClass) {
      case {t: _.get() => {name: "PointerProcessed", pack: ["ammer"]}, params: [TInst(_.get() => {kind: KExpr({expr: EConst(CString(native))})}, []), libType = TInst(lib, [])]}:
        typeCache[id] = {native: native, fields: Context.getBuildFields(), library: Context.toComplexType(libType), kind: subtypeKind = Pointer(true)};
        lib.get();
      case {t: _.get() => {name: "PointerNoStarProcessed", pack: ["ammer"]}, params: [TInst(_.get() => {kind: KExpr({expr: EConst(CString(native))})}, []), libType = TInst(lib, [])]}:
        typeCache[id] = {native: native, fields: Context.getBuildFields(), library: Context.toComplexType(libType), kind: subtypeKind = Pointer(false)};
        lib.get();
      case {t: _.get() => {name: "IntEnumProcessed", pack: ["ammer"]}, params: [TInst(_.get() => {kind: KExpr({expr: EConst(CString(native))})}, []), libType = TInst(lib, [])]}:
        typeCache[id] = {native: native, fields: Context.getBuildFields(), library: Context.toComplexType(libType), kind: subtypeKind = IntEnum};
        lib.get();
      case {t: _.get() => {name: "Sublibrary", pack: ["ammer"]}, params: [libType = TInst(lib, [])]}:
        typeCache[id] = {native: null, fields: Context.getBuildFields(), library: Context.toComplexType(libType), kind: subtypeKind = Sublibrary};
        lib.get();
      case _:
        throw "!";
    });
    var ctx = delayedBuildType(id, implType, subtypeKind);
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
