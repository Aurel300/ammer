package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using Lambda;

typedef ResolvedType = {
  marshal:ammer.core.TypeMarshal,
  haxeType:ComplexType,
  wrap:Null<Expr->Expr>,
  unwrap:Null<Expr->Expr>,
};

typedef CommonType = {
  type:Type,
  id:String,
  match:(Type)->Bool,
};

class Types {
  static function prepareType(type:Type):CommonType {
    var ret = {
      type: type,
      id: null,
      match: null,
    };
    switch (type) {
      case TInst(_.get() => a, []):
        ret.id = '${a.pack.join(".")}.${a.module.split(".").pop()}.${a.name}';
        ret.match = (ctype:Type) -> switch (ctype) {
          case TInst(_.get() => b, []): a.name == b.name && a.module == b.module;
          case _: false;
        };
      case TInst(_.get() => a, [TInst(_.get() => a2, [])]):
        ret.id = '${a.pack.join(".")}.${a.module.split(".").pop()}.${a.name}';
        ret.match = (ctype:Type) -> switch (ctype) {
          case TInst(_.get() => b, [TInst(_.get() => b2, [])]):
            a.name == b.name && a.module == b.module
              && a2.name == b2.name && a2.module == b2.module;
          case _: false;
        };
      case TAbstract(_.get() => a, []):
        ret.id = '${a.pack.join(".")}.${a.module.split(".").pop()}.${a.name}';
        ret.match = (ctype:Type) -> switch (ctype) {
          case TAbstract(_.get() => b, []): a.name == b.name && a.module == b.module;
          case _: false;
        };
      case _: throw 'how to match $type ?';
    }
    return ret;
  }

  public static var TYPES = {
    var herePos = (macro null).pos;
    function c(ct:ComplexType, enable:Bool = true):CommonType {
      if (!enable) return null;
      // do not follow type: on some targets, some primitive types are typedefs
      return prepareType(Context.resolveType(ct, herePos));
    }
    var hasSingle = (switch (Context.definedValue("target.name")) {
      case "cpp" | "cs" | "hl" | "java": true;
      case _: false;
    });
    {
      void:   c((macro : ammer.ffi.Void)),    hxVoid: c((macro : Void)),
      bool:   c((macro : ammer.ffi.Bool)),    hxBool: c((macro : Bool)),
      u8:     c((macro : ammer.ffi.UInt8)),
      u16:    c((macro : ammer.ffi.UInt16)),
      u32:    c((macro : ammer.ffi.UInt32)),  hxU32: c((macro : UInt)),
      u64:    c((macro : ammer.ffi.UInt64)),
      i8:     c((macro : ammer.ffi.Int8)),
      i16:    c((macro : ammer.ffi.Int16)),
      i32:    c((macro : ammer.ffi.Int32)),   hxI32: c((macro : Int)),
      i64:    c((macro : ammer.ffi.Int64)),   hxI64: c((macro : haxe.Int64)),
      f32:    c((macro : ammer.ffi.Float32)), hxF32: c((macro : Single), hasSingle),
      f64:    c((macro : ammer.ffi.Float64)), hxF64: c((macro : Float)),
      string: c((macro : ammer.ffi.String)),  hxString: c((macro : String)),
      bytes:  /*c((macro : ammer.ffi.Bytes)),*/ (null : CommonType),
      hxBytes: c((macro : haxe.io.Bytes)), //?
      this_:  c((macro : ammer.ffi.This)),
      derefThis: c((macro : ammer.ffi.Deref<ammer.ffi.This>)),
    };
  };
  static function initTypes():Void {
    if (TYPES == null || TYPES.bytes != null) return;
    var herePos = (macro null).pos;
    function c(ct:ComplexType):CommonType {
      return prepareType(Context.resolveType(ct, herePos));
    }
    TYPES.bytes = c((macro : ammer.ffi.Bytes));
  }

  public static function resolveComplexType(
    ct:ComplexType,
    lib:LibContext
  ):ResolvedType {
    return resolveType(Reporting.resolveType(ct, Reporting.currentPos()), lib);
  }

  static function resolveContexts(type:Type):Array<LibContext> {
    //var followedType = TypeTools.follow(type);
    var ret:Array<LibContext> = [];
    function c(target:CommonType):Bool {
      if (target == null) return false;
      return target.match(type);
    }
    initTypes();
       // ammer.ffi.* types
       c(TYPES.void)
    || c(TYPES.bool)
    || c(TYPES.u8)
    || c(TYPES.u16)
    || c(TYPES.u32)
    || c(TYPES.u64)
    || c(TYPES.i8)
    || c(TYPES.i16)
    || c(TYPES.i32)
    || c(TYPES.i64)
    || c(TYPES.f32)
    || c(TYPES.f64)
    || c(TYPES.string)
    || c(TYPES.bytes)
       // Haxe shortcuts
    || c(TYPES.hxVoid)
    || c(TYPES.hxBool)
    || c(TYPES.hxU32)
    || c(TYPES.hxI32)
    || c(TYPES.hxI64)
    || c(TYPES.hxF32)
    || c(TYPES.hxF64)
    || c(TYPES.hxString)
    //|| c(TYPES.hxBytes)
    || {
      ret = (switch (type) {
        case TInst(Utils.typeId(_.get()) => id, []):
          if (Ammer.mergedInfo.structs.exists(id)) {
            Ammer.mergedInfo.structs[id].ctx != null || throw "context for struct not initialised yet";
            [Ammer.mergedInfo.structs[id].ctx];
          } else if (Ammer.mergedInfo.opaques.exists(id)) [Ammer.mergedInfo.opaques[id].ctx];
          else if (Ammer.mergedInfo.sublibraries.exists(id)) [Ammer.mergedInfo.sublibraries[id].ctx];
          else if (Ammer.mergedInfo.arrays.byTypeId.exists(id)) throw 0; // Ammer.arrays.byTypeId[id].ctx;
          else if (Ammer.mergedInfo.boxes.byTypeId.exists(id)) throw 0; // Ammer.boxes.byTypeId[id].ctx;
          else if (Ammer.mergedInfo.callbacks.byTypeId.exists(id)) [Ammer.mergedInfo.callbacks.byTypeId[id].ctx];
          // TODO: enums ?
          else if (Ammer.mergedInfo.haxeRefs.byTypeId.exists(id)) [Ammer.mergedInfo.haxeRefs.byTypeId[id].ctx];
          else if (Ammer.libraries.byTypeId.exists(id)) [Ammer.libraries.byTypeId[id]];
          else [];
        case TInst(Utils.typeId(_.get()) => "ammer.ffi.Deref.Deref", [type]):
          resolveContexts(type);
        case TAbstract(_, []):
          var next = TypeTools.followWithAbstracts(type, true);
          if (Utils.typeId2(type) != Utils.typeId2(next)) resolveContexts(next);
          else [];
        case TFun(args, ret):
          var ret = [];
          var retMap:Map<String, Bool> = [];
          for (arg in args) {
            for (ctx in resolveContexts(arg.t)) {
              if (retMap.exists(ctx.name)) continue;
              retMap[ctx.name] = true;
              ret.push(ctx);
            }
          }
          ret;
        case TType(_): return resolveContexts(TypeTools.follow(type, true));
        case _: trace(type); throw 0;
      });
      true;
    };
    return ret;
  }

  public static function resolveContext(type:Type):LibContext {
    var ret = resolveContexts(type);
    if (ret.length > 1) {
      trace("contexts", ret);
      throw "multiple contexts ...";
    } else if (ret.length == 0) {
      return Ammer.libraries.byTypeId["ammer.internal.LibTypes.LibTypes"];
    }
    return ret[0];
  }

  public static function resolveType(
    type:Type,
    lib:LibContext
  ):ResolvedType {
    var marshal = lib.marshal;
    var ret:ResolvedType = null;
    function c(
      target:CommonType, ffi:()->ammer.core.TypeMarshal,
      ?haxeType:ComplexType, ?wrap:Expr->Expr, ?unwrap:Expr->Expr
    ):Bool {
      if (target == null) return false;
      if (target.match(type)) {
        var retMarshal = ffi();
        ret = {
          marshal: retMarshal,
          haxeType: haxeType != null ? haxeType : retMarshal.haxeType,
          wrap: wrap,
          unwrap: unwrap,
        };
        return true;
      }
      return false;
    }
    initTypes();
    // check abstracts first: may unify with primitive types otherwise
    (switch (type) {
      case TAbstract(_.get() => abs, []):
        // make sure build macros for the abstract get triggered
        if (abs.impl != null) {
          abs.impl.get();
        }

        var id = Utils.typeId(abs);
        if (Ammer.mergedInfo.enums.exists(id)) {
          ret = {
            marshal: Ammer.mergedInfo.enums[id].marshal,
            haxeType: Ammer.mergedInfo.enums[id].marshal.haxeType,
            wrap: e -> e,
            unwrap: e -> e,
          };
          true;
        } else {
          false;
        }
      case _: false;
    })
       // ammer.ffi.* types
    || c(TYPES.void,     marshal.void   )
    || c(TYPES.bool,     marshal.bool   )
    || c(TYPES.u8,       marshal.uint8  )
    || c(TYPES.u16,      marshal.uint16 )
    || c(TYPES.u32,      marshal.uint32 )
    || c(TYPES.u64,      marshal.uint64 )
    || c(TYPES.i8,       marshal.int8   )
    || c(TYPES.i16,      marshal.int16  )
    || c(TYPES.i32,      marshal.int32  )
    || c(TYPES.i64,      marshal.int64  )
    || c(TYPES.f32,      marshal.float32)
    || c(TYPES.f64,      marshal.float64)
    || c(TYPES.string,   marshal.string )
    || c(TYPES.bytes,    () -> marshal.bytes().type,
                         (macro : ammer.ffi.Bytes),
                         e -> macro @:privateAccess new ammer.ffi.Bytes($e),
                         e -> macro @:privateAccess $e._ammer_native)
    || c(TYPES.this_,    () -> throw Reporting.error("ammer.ffi.This type not allowed here"))
       // Haxe shortcuts
    || c(TYPES.hxVoid,   marshal.void   )
    || c(TYPES.hxBool,   marshal.bool   )
    || c(TYPES.hxU32,    marshal.uint32 )
    || c(TYPES.hxI32,    marshal.int32  )
    || c(TYPES.hxI64,    marshal.int64  )
    || c(TYPES.hxF32,    marshal.float32)
    || c(TYPES.hxF64,    marshal.float64)
    || c(TYPES.hxString, marshal.string )
    //|| c(TYPES.hxBytes,  () -> marshal.bytes().type)
    || {
      // TODO: better handling of typarams, better errors...
      // TODO: cache ResolvedTypes directly in the relevant info structs?
      switch (type) {
        case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.structs.exists(id)):
          Ammer.mergedInfo.structs[id].marshalOpaque != null || throw 0;
          var ct = TypeTools.toComplexType(type);
          var tp = Utils.expectTypePath(ct);
          ret = {
            marshal: Ammer.mergedInfo.structs[id].marshalOpaque,
            haxeType: ct,
            wrap: e -> macro @:privateAccess new $tp($e),
            unwrap: e -> macro @:privateAccess $e._ammer_native,
          };
          true;
        case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.opaques.exists(id)):
          Ammer.mergedInfo.opaques[id].marshal != null || throw 0;
          var ct = TypeTools.toComplexType(type);
          var tp = Utils.expectTypePath(ct);
          ret = {
            marshal: Ammer.mergedInfo.opaques[id].marshal.type,
            haxeType: ct,
            wrap: e -> macro @:privateAccess new $tp($e),
            unwrap: e -> macro @:privateAccess $e._ammer_native,
          };
          true;
        case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.arrays.byTypeId.exists(id)):
          var array = Ammer.mergedInfo.arrays.byTypeId[id];
          var tp = Utils.expectTypePath(array.arrayCt);
          ret = {
            marshal: array.arrayMarshal.type,
            haxeType: TypeTools.toComplexType(type),
            wrap: e -> macro @:privateAccess new $tp($e),
            unwrap: e -> macro @:privateAccess $e._ammer_native,
          };
          true;
        case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.boxes.byTypeId.exists(id)):
          var box = Ammer.mergedInfo.boxes.byTypeId[id];
          var marshal = box.boxMarshal;
          var tp = Utils.expectTypePath(box.boxCt);
          ret = {
            marshal: marshal.type,
            haxeType: TypeTools.toComplexType(type),
            wrap: e -> macro @:privateAccess new $tp($e),
            unwrap: e -> macro @:privateAccess $e._ammer_native,
          };
          true;
        case TInst(Utils.typeId(_.get()) => id, []) if (Ammer.mergedInfo.haxeRefs.byTypeId.exists(id)):
          var haxeRef = Ammer.mergedInfo.haxeRefs.byTypeId[id];
          ret = {
            marshal: haxeRef.marshal.type,
            haxeType: haxeRef.marshal.refCt,
            wrap: e -> macro $e{haxeRef.marshal.restore(e)},
            unwrap: e -> macro $e{e}.handle,
          };
          true;
        case TAbstract(Utils.typeId(_.get()) => "ammer.internal.LibTypes.HaxeAnyRef", [el]):
          // var elId = Utils.typeId2(el);
          var ct = TypeTools.toComplexType(type);
          var elCt = TypeTools.toComplexType(el);
          var haxeRef = Ammer.mergedInfo.haxeRefs.byElementTypeId[".Any.Any"];
          haxeRef != null || throw 0;
          var refCt = haxeRef.marshal.refCt;
          ret = {
            marshal: haxeRef.marshal.type,
            haxeType: ct, // haxeRef.marshal.refCt,
            wrap: e -> macro new ammer.internal.LibTypes.HaxeAnyRef<$elCt>($e{haxeRef.marshal.restore(e)}),
            unwrap: e -> macro ($e{e}.toNative() : $refCt).handle,
          };
          true;
        case TInst(Utils.typeId(_.get()) => "ammer.ffi.Deref.Deref", [type = TInst(Utils.typeId(_.get()) => id, [])]) if (Ammer.mergedInfo.structs.exists(id)):
          Ammer.mergedInfo.structs[id].marshalOpaque != null || throw 0;
          var ct = TypeTools.toComplexType(type);
          var tp = Utils.expectTypePath(ct);
          ret = {
            marshal: Ammer.mergedInfo.structs[id].marshalDeref,
            haxeType: ct,
            wrap: e -> macro @:privateAccess new $tp($e),
            unwrap: e -> macro @:privateAccess $e._ammer_native,
          };
          true;
        case TAbstract(abs, _):
          var next = TypeTools.followWithAbstracts(type, true);
          if (Utils.typeId2(type) != Utils.typeId2(next)) return resolveType(next, lib);
          false;
        case TType(_): return resolveType(TypeTools.follow(type, true), lib);
        case TInst(Utils.typeId(_.get()) => id, []):
          trace("type id was", id);
          false;
        case _: false;
      }
    };
    if (ret == null) {
      // TODO: error
      trace("type:", type);
      throw 0;
    }
    return ret;
  }
}

#end
