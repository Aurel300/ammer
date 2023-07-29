package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using Lambda;
using StringTools;

enum FieldContext {
  FCLibrary(options:ammer.internal.v1.LibInfo.LibInfoLibrary);
  FCOpaque(options:ammer.internal.v1.LibInfo.LibInfoOpaque);
  FCStruct(options:ammer.internal.v1.LibInfo.LibInfoStruct);
  FCSublibrary(options:ammer.internal.v1.LibInfo.LibInfoSublibrary);
}

typedef CategorisedMethod = {
  nativeName:String,
  metas:Array<Meta.ParsedMeta>,
  field:Field,
  fun:Function,
};
typedef CategorisedVar = {
  nativeName:String,
  metas:Array<Meta.ParsedMeta>,
  field:Field,
  ct:ComplexType,
  isFinal:Bool,
};

class Fields {
  static function categorise(
    fields:Array<Field>,
    fieldCtx:FieldContext
  ):{
    staticMethods:Array<CategorisedMethod>,
    staticVars:Array<CategorisedVar>,
    instanceMethods:Array<CategorisedMethod>,
    instanceVars:Array<CategorisedVar>,
    passMethods:Array<CategorisedMethod>,
  } {
    var nativePrefix:String = null;
    switch (fieldCtx) {
      case FCLibrary(options):
        nativePrefix = options.nativePrefix;
      case FCOpaque(options):
        nativePrefix = options.nativePrefix;
      case FCStruct(options):
        nativePrefix = options.nativePrefix;
      case FCSublibrary(options):
        nativePrefix = options.nativePrefix;
    }

    var staticMethods = [];
    var staticVars = [];
    var instanceMethods = [];
    var instanceVars = [];
    var passMethods = [];
    for (field in fields) Reporting.withPosition(field.pos, () -> {
      var nativeName = nativePrefix != null
        ? nativePrefix + field.name
        : field.name;

      // validate field access modifiers
      var isInstance = !field.access.contains(AStatic);
      if (isInstance && !fieldCtx.match(FCStruct(_) | FCOpaque(_)))
        return Reporting.error('non-static field ${field.name} only allowed in struct types and opaque types');

      var isFinal = field.access.contains(AFinal);

      for (access in field.access) switch (access) {
        case AOverride: Reporting.error('"override" not allowed in ammer definitions');
        case ADynamic:  Reporting.error('"dynamic" not allowed in ammer definitions');
        case AInline:   Reporting.error('"inline" not allowed in ammer definitions');
        case AMacro:    Reporting.error('"macro" not allowed in ammer definitions');
        case AExtern:   Reporting.error('"extern" not allowed in ammer definitions');
        case AAbstract: Reporting.error('"abstract" not allowed in ammer definitions');
        case AOverload: Reporting.error('"overload" not allowed in ammer definitions');
        case _:
      }

      // parse metadata
      var allowHaxe = false;
      var defaultNativeName = true;
      var metas = Meta.extract(field.meta, Meta.COMMON_FIELD, false);
      for (meta in metas) switch (meta) {
        case PMHaxe: allowHaxe = true;
        case PMNative(name): defaultNativeName = false; nativeName = name;
        case _: throw 0;
      }
      if (allowHaxe) {
        defaultNativeName || throw Reporting.error("@:ammer.native has no effect on @:ammer.haxe fields");
      }

      // categorise
      switch (field.kind) {
        case FFun(f):
          if (allowHaxe) {
            f.expr != null || throw Reporting.error("function body required for @:ammer.haxe functions");
            passMethods.push({
              nativeName: null,
              metas: metas,
              field: field,
              fun: f,
            });
          } else {
            f.expr == null || throw Reporting.error("function body not allowed (unless @:ammer.haxe is added)");
            f.ret != null || return Reporting.error("type annotation required for return type");
            !isFinal || return Reporting.error('"final" not allowed on methods');
            for (arg in f.args) arg.type != null || return Reporting.error("type annotation required for arguments");
            (isInstance ? instanceMethods : staticMethods).push({
              nativeName: nativeName,
              metas: metas,
              field: field,
              fun: f,
            });
          }
        case FVar(ct, def):
          !allowHaxe || return Reporting.error("@:ammer.haxe not yet supported on variable fields");
          ct != null || return Reporting.error("type annotation required");
          def == null || return Reporting.error("default values are not allowed");
          (isInstance ? instanceVars : staticVars).push({
            nativeName: nativeName,
            metas: metas,
            field: field,
            ct: ct,
            isFinal: isFinal,
          });
        case _: return Reporting.error("invalid field kind");
      }
    });
    return {
      staticMethods: staticMethods,
      staticVars: staticVars,
      instanceMethods: instanceMethods,
      instanceVars: instanceVars,
      passMethods: passMethods,
    };
  }

  public static function process(
    fields:Array<Field>,
    ctx:LibContext,
    fieldCtx:FieldContext
  ):Array<Field> {
    var categorised = categorise(fields, fieldCtx);
    var processed:Array<Field> = [];

    // create type representation
    var libraryOptions:ammer.internal.v1.LibInfo.LibInfoLibrary;
    var opaqueOptions:ammer.internal.v1.LibInfo.LibInfoOpaque;
    var structOptions:ammer.internal.v1.LibInfo.LibInfoStruct;
    var sublibraryOptions:ammer.internal.v1.LibInfo.LibInfoSublibrary;
    switch (fieldCtx) {
      case FCLibrary(options):
        libraryOptions = options;
      case FCOpaque(options):
        // TODO: reduce duplication between opaque and struct cases
        opaqueOptions = options;
        options.marshal = ctx.marshal.opaque(options.opaqueName);
        processed.push({
          name: "_ammer_native",
          meta: [],
          pos: Reporting.currentPos(),
          kind: FVar(options.marshal.type.haxeType, null),
          doc: null,
          access: [APrivate],
        });
        processed.push({
          name: "new",
          meta: [],
          pos: Reporting.currentPos(),
          kind: FFun({
            ret: null,
            expr: macro _ammer_native = native,
            args: [{ name: "native", type: options.marshal.type.haxeType }],
          }),
          doc: null,
          access: [APrivate],
        });
        var implCt = TypeTools.toComplexType(options.implType);
        var implTp = (switch (implCt) {
          case TPath(tp): tp;
          case _: throw 0;
        });
        processed.push({
          name: "_ammer_lib_nullPtr",
          meta: [],
          pos: Reporting.currentPos(),
          kind: FFun({
            ret: implCt,
            expr: macro return new $implTp($e{options.marshal.nullPtr}),
            args: [],
          }),
          doc: null,
          access: [APrivate, AStatic],
        });
      case FCStruct(options):
        structOptions = options;

        // TODO: this is not great, is there better API design?
        var structEmpty = ctx.marshal.structPtr(options.structName, [], false);
        options.marshalOpaque = structEmpty.type;
        options.marshalDeref = structEmpty.typeDeref;

        // TODO: store the fieldRefs?
        var fieldRefs = categorised.instanceVars.map(f -> {
          var fieldType = Types.resolveComplexType(f.ct, ctx);
          var fref = ctx.marshal.fieldRef(f.nativeName, fieldType.marshal);
          fref;
        });
        options.marshal = ctx.marshal.structPtr(
          options.structName,
          fieldRefs,
          options.gen.alloc != null
            || options.gen.free != null
            || options.gen.nullPtr != null
        );
        processed.push({
          name: "_ammer_native",
          meta: [],
          pos: Reporting.currentPos(),
          kind: FVar(options.marshal.type.haxeType, null),
          doc: null,
          access: [APrivate],
        });
        processed.push({
          name: "new",
          meta: [],
          pos: Reporting.currentPos(),
          kind: FFun({
            ret: null,
            expr: macro _ammer_native = native,
            args: [{ name: "native", type: options.marshal.type.haxeType }],
          }),
          doc: null,
          access: [APrivate],
        });
        var implCt = TypeTools.toComplexType(options.implType);
        var implTp = (switch (implCt) {
          case TPath(tp): tp;
          case _: throw 0;
        });

        if (options.gen.alloc != null) {
          processed.push({
            name: options.gen.alloc,
            meta: [],
            pos: Reporting.currentPos(),
            kind: FFun({
              ret: implCt,
              expr: macro return new $implTp($e{options.marshal.alloc}),
              args: [],
            }),
            doc: null,
            access: [APublic, AStatic],
          });
        }
        if (options.gen.free != null) {
          processed.push({
            name: options.gen.free,
            meta: [],
            pos: Reporting.currentPos(),
            kind: FFun({
              ret: (macro : Void),
              expr: macro $e{options.marshal.free(macro _ammer_native)},
              args: [],
            }),
            doc: null,
            access: [APublic],
          });
        }
        if (options.gen.nullPtr != null) {
          processed.push({
            name: options.gen.nullPtr,
            meta: [],
            pos: Reporting.currentPos(),
            kind: FFun({
              ret: implCt,
              expr: macro return new $implTp($e{options.marshal.nullPtr}),
              args: [],
            }),
            doc: null,
            access: [APublic, AStatic],
          });
        }
      case FCSublibrary(options):
        sublibraryOptions = options;
    }

    // process fields
    function processMethod(method:CategorisedMethod, isInstance:Bool):Void {
      var argCount = method.fun.args.length;

      // process method metadata
      var retCCast = null;
      var cPrereturn = "";
      var cReturn = "%CALL%";
      var derivedRet = null;
      var derivedRetType = null;
      for (meta in Meta.extract(method.field.meta, Meta.COMMON_METHOD)) switch (meta) {
        case PMNative(name): // already processed in `categorised`, ignore
        case PMC_Cast(to): retCCast = to;
        case PMC_MacroCall: // no-op
        case PMC_Prereturn(expr): cPrereturn = expr;
        case PMC_Return(expr):
          // ret.mangled != "v" || throw Reporting.error(":ammer.c.return cannot be used on a method with `Void` return type");
          cReturn = expr;
        case PMRet_Derive(expr, ct):
          derivedRet = expr;
          derivedRetType = ct;
        case _: throw 0;
      }

      // process argument metadata
      var skipArgs = [ for (idx in 0...argCount) false ];
      var derivedHaxe = [ for (idx in 0...argCount) null ];
      var replaceHaxe = [ for (idx in 0...argCount) null ]; // TODO: messy!
      var replaceArgType = [ for (idx in 0...argCount) null ];
      var cCast = [ for (idx in 0...argCount) null ]; // TODO: messy!
      for (idx in 0...argCount) {
        method.fun.args[idx].meta != null || continue;
        for (meta in Meta.extract(method.fun.args[idx].meta, Meta.METHOD_ARG)) switch (meta) {
          case PMC_Cast(to): cCast[idx] = to;
          case PMSkip: skipArgs[idx] = true;
          case PMDerive(e): derivedHaxe[idx] = e;
          // TODO: c.derive
          case _: throw 0;
        }
      }
      var nonSkipCtr = 0;
      var derivedC = [ for (idx in 0...argCount) skipArgs[idx]
        ? null
        : ((cCast[idx] != null ? '(${cCast[idx]})' : "") + '_arg${nonSkipCtr++}') ];
      var preExprs = [];

      // TODO: sanity checks, e.g. disallow skip and derive on the same argument
      // TODO: ammer.argN... variant of metadata?
      // TODO: ammer.ret... metadata

      // process special types
      // TODO: retAlloc is not a very clean solution
      var retAlloc = null;
      function localResolve(res:Type, idx:Int):Types.ResolvedType {
        if (Types.TYPES.this_.match(res)) {
          isInstance || throw Reporting.error("ammer.ffi.This can only be used in instance methods of opaque or struct types");
          (structOptions != null || opaqueOptions != null) || throw Reporting.error("ammer.ffi.This can only be used in instance methods of opaque or struct types");
          idx != -1 || throw Reporting.error("ammer.ffi.This cannot be used as the return type");
          derivedHaxe[idx] = macro this;
          res = structOptions != null ? structOptions.implType : opaqueOptions.implType;
        } else if (Types.TYPES.derefThis.match(res)) {
          isInstance || throw Reporting.error("ammer.ffi.This can only be used in instance methods of opaque or struct types");
          (structOptions != null || opaqueOptions != null) || throw Reporting.error("ammer.ffi.This can only be used in instance methods of opaque or struct types");
          idx != -1 || throw Reporting.error("ammer.ffi.This cannot be used as the return type");
          derivedHaxe[idx] = macro this;
          var implCt = TypeTools.toComplexType(structOptions != null ? structOptions.implType : opaqueOptions.implType);
          res = haxe.macro.ComplexTypeTools.toType((macro : ammer.ffi.Deref<$implCt>));
        } else {
          switch (res) {
            case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.callbacks.byTypeId.exists(id)):
              var callback = Ammer.mergedInfo.callbacks.byTypeId[id];
              derivedC[idx] = callback.callbackName;
              if (callback.isGlobal) {
                var ident = 'arg$idx';
                preExprs.push(macro $p{Utils.accessTp(Utils.expectTypePath(callback.callbackCt))}.store($i{ident}));
                replaceHaxe[idx] = macro 0;
                replaceArgType[idx] = callback.funCt;
              } else {
                derivedHaxe[idx] = macro 0;
              }
              res = Types.TYPES.i32.type;
            case TInst(Utils.typeId(_.get()) => "ammer.ffi.Alloc.Alloc", params):
              idx == -1 || throw Reporting.error("ammer.ffi.Alloc cannot be used as an argument type");
              params.length == 1 || throw Reporting.error("ammer.ffi.Alloc should have one type parameter");
              var type = Utils.classOfParam(params[0]).get();
              var id = Utils.typeId(type);
              Ammer.mergedInfo.structs[id].marshal != null || throw Reporting.error("type parameter should be a struct");
              Ammer.mergedInfo.structs[id].alloc || throw Reporting.error("struct is not allocatable");
              var ct = TypeTools.toComplexType(params[0]);
              var tp = (switch (ct) {
                case TPath(tp): tp;
                case _: throw 0;
              });
              retAlloc = Ammer.mergedInfo.structs[id].structName;
              res = params[0];
            case TInst(Utils.typeId(_.get()) => "ammer.ffi.Unsupported.Unsupported", [val]):
              // TODO: allow ammer.ffi.Unsupported<""> for ignored return values
              idx != -1 || throw Reporting.error("ammer.ffi.Unsupported cannot be used as the return type");
              var expr = Utils.stringOfParam(val);
              expr != null || throw Reporting.error("ammer.def.Unsupported type parameter should be a string");
              derivedHaxe[idx] = (macro 0);
              derivedC[idx] = expr;
              res = Types.TYPES.i32.type;
            case TType(_): return localResolve(TypeTools.follow(res, true), idx);
            case _:
          }
        }
        return Types.resolveType(res, ctx);
      }
      function localResolveCt(ct:ComplexType, idx:Int):Types.ResolvedType {
        var res = Reporting.resolveType(ct, Reporting.currentPos());
        return localResolve(res, idx);
      }

      // resolve types
      var ret = localResolveCt(method.fun.ret, -1);
      var args = method.fun.args.mapi((idx, arg) -> skipArgs[idx] ? null : localResolveCt(arg.type, idx));

      // create native representation
      var nativeCall = '${method.nativeName}(${[ for (idx in 0...argCount) if (!skipArgs[idx]) derivedC[idx] ].join(", ")})';
      var native = ctx.library.addFunction(
        ret.marshal,
        [ for (idx in 0...argCount) if (!skipArgs[idx]) args[idx].marshal ],
        cPrereturn + "\n" + (retAlloc != null
          // TODO: configure malloc, memcpy
          ? '_return = ($retAlloc*)malloc(sizeof($retAlloc));
$retAlloc retval = ${cReturn.replace("%CALL%", nativeCall)};
memcpy(_return, &retval, sizeof($retAlloc));'
          : '${ret.marshal.mangled != "v" ? "_return = " : ""}${retCCast != null ? '($retCCast)' : ""}${cReturn.replace("%CALL%", nativeCall)};'),
        {
          comment: 'original field name: ${method.field.name}',
        }
      );

      // create Haxe call
      var call:Expr = {
        expr: ECall(
          native,
          [ for (idx in 0...argCount) if (!skipArgs[idx]) {
            var expr = derivedHaxe[idx] != null
              ? derivedHaxe[idx]
              : (replaceHaxe[idx] != null
                ? replaceHaxe[idx]
                : { expr: EConst(CIdent('arg$idx')), pos: method.field.pos });
            Utils.exprMap(expr, args[idx].unwrap);
          } ]
        ),
        pos: method.field.pos,
      };
      var finalExprs = derivedRet != null
        ? [macro (var ret = $e{Utils.exprMap(call, ret.wrap)}), macro return $derivedRet]
        : [macro return $e{Utils.exprMap(call, ret.wrap)}];
      processed.push(Utils.updateField(method.field, FFun({
        ret: derivedRetType != null ? derivedRetType : ret.haxeType,
        expr: macro $b{preExprs.concat(finalExprs)},
        args: [ for (idx in 0...argCount) {
          derivedHaxe[idx] == null || continue;
          ({name: 'arg$idx', type: skipArgs[idx]
            ? method.fun.args[idx].type
            : (replaceArgType[idx] != null
              ? replaceArgType[idx]
              : args[idx].haxeType)}:FunctionArg);
        } ],
      })));
    }

    for (method in categorised.staticMethods)
      Reporting.withPosition(method.field.pos, () -> processMethod(method, false));
    for (method in categorised.instanceMethods)
      Reporting.withPosition(method.field.pos, () -> processMethod(method, true));
    for (method in categorised.passMethods)
      processed.push(method.field);

    // TODO: reduce duplication?
    for (v in categorised.staticVars) Reporting.withPosition(v.field.pos, () -> {
      var fieldType = Types.resolveComplexType(v.ct, ctx);
      var marshal = ctx.marshal.fieldRef(v.nativeName, fieldType.marshal);
      var getter = ctx.library.addFunction(
        marshal.type,
        [],
        '_return = ${v.nativeName};'
      );
      if (v.isFinal) {
        processed.push({
          name: 'get_${v.field.name}',
          pos: v.field.pos,
          kind: FFun({
            ret: fieldType.haxeType,
            expr: macro return $e{Utils.exprMap(macro $getter(), fieldType.wrap)},
            args: [],
          }),
          access: [APrivate, AStatic],
        });
        v.field.access.remove(AFinal); // Haxe#8859
        processed.push(Utils.updateField(v.field, FProp("get", "never", fieldType.haxeType, null)));
      } else {
        processed.push({
          name: 'get_${v.field.name}',
          pos: v.field.pos,
          kind: FFun({
            ret: fieldType.haxeType,
            expr: macro return $e{Utils.exprMap(macro $getter(), fieldType.wrap)},
            args: [],
          }),
          access: [APrivate, AStatic],
        });
        var setter = ctx.library.addFunction(
          ctx.marshal.void(),
          [marshal.type],
          '${v.nativeName} = _arg0;'
        );
        processed.push({
          name: 'set_${v.field.name}',
          pos: v.field.pos,
          kind: FFun({
            ret: fieldType.haxeType,
            expr: macro {
              $setter($e{Utils.exprMap(macro val, fieldType.unwrap)});
              return val;
            },
            args: [{
              name: "val",
              type: fieldType.haxeType,
            }],
          }),
          access: [APrivate, AStatic],
        });
        processed.push(Utils.updateField(v.field, FProp("get", "set", fieldType.haxeType, null)));
      }
    });

    for (v in categorised.instanceVars) Reporting.withPosition(v.field.pos, () -> {
      var fieldType = Types.resolveComplexType(v.ct, ctx);
      var marshal = ctx.marshal.fieldRef(v.nativeName, fieldType.marshal);
      processed.push({
        name: 'get_${v.field.name}',
        pos: v.field.pos,
        kind: FFun({
          ret: fieldType.haxeType,
          expr: macro return $e{Utils.exprMap(structOptions.marshal.fieldGet[v.nativeName](macro _ammer_native), fieldType.wrap)},
          args: [],
        }),
        access: [APrivate],
      });
      processed.push({
        name: 'set_${v.field.name}',
        pos: v.field.pos,
        kind: FFun({
          ret: fieldType.haxeType,
          expr: macro {
            $e{structOptions.marshal.fieldSet[v.nativeName](macro _ammer_native, Utils.exprMap(macro val, fieldType.unwrap))};
            return val;
          },
          args: [{
            name: "val",
            type: fieldType.haxeType,
          }],
        }),
        access: [APrivate],
      });
      processed.push(Utils.updateField(v.field, FProp("get", "set", fieldType.haxeType, null)));
    });

    return processed;
  }
}

#end
