package ammer;

import haxe.macro.Context;
import haxe.macro.Context.fatalError as fail;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import ammer.internal.*;
import ammer.internal.Ammer.mergedInfo as info;
import ammer.internal.Utils.access;
import ammer.internal.Utils.accessTp;
import ammer.internal.Utils.complexTypeExpr;
import ammer.internal.Utils.expectTypePath;
import ammer.internal.Utils.isNull;
import ammer.internal.Utils.triggerTyping;
import ammer.internal.Utils.typeId;
import ammer.internal.Utils.typeId2;

using Lambda;

class Lib {
  static function withPos<T>(pos:Position, f:()->T):T {
    return Reporting.withPosition(pos, f);
  }

  static function resolveType(ct:ComplexType, pos:Position):Type {
    return Reporting.withPosition(pos, () -> Reporting.resolveType(ct, pos));
  }

  // These methods are inserted into `Lib.macro.hx` when baking a library.
  // This avoids code duplication/synchronisation issues. Importantly, the code
  // is just string-pasted, so it is important that the `import`s that are
  // in `Lib.macro.baked.hx` are sufficient for the code to work.

// ammer-fragment-begin: lib-baked
  public static function allocStruct(cls:Expr, ?initVals:Expr):Expr {
    var ct = complexTypeExpr(cls);
    var clsType = withPos(cls.pos, () -> triggerTyping(ct));
    clsType != null || throw fail("invalid type in allocStruct call", cls.pos);
    var struct = info.structs[typeId(clsType)];
    struct != null || throw fail("not a struct type in allocStruct call", cls.pos);
    struct.gen.alloc != null || throw fail("struct type was not marked with @:ammer.alloc", cls.pos);
    var alloc = struct.gen.alloc;
    if (isNull(initVals)) {
      return macro @:privateAccess $p{access(clsType)}.$alloc();
    }
    var assigns = (switch (initVals) {
      case {expr: EObjectDecl(fields)}:
        [ for (field in fields) macro @:pos(field.expr.pos) $p{["_allocated", field.field]} = $e{field.expr} ];
      case _: throw fail("expected initial values (e.g. {a: 1, b: 2, ...}) as second argument of allocStruct call", initVals.pos);
    });
    return macro {
      var _allocated = @:privateAccess $p{access(clsType)}.$alloc();
      $b{assigns};
      _allocated;
    };
  }

  public static function nullPtrStruct(cls:Expr):Expr {
    var ct = complexTypeExpr(cls);
    var clsType = withPos(cls.pos, () -> triggerTyping(ct));
    clsType != null || throw fail("invalid type in nullPtrStruct call", cls.pos);
    var typeId = typeId(clsType);
    var struct = info.structs[typeId];
    //var opaque = info.opaques[typeId];
    //(struct != null || opaque != null) || throw fail("not a struct type or opaque type in nullPtrStruct call", cls.pos);
    struct != null || throw fail("not a struct type in nullPtrStruct call", cls.pos);
    struct.gen.nullPtr != null || throw fail("struct type was not marked with @:ammer.alloc", cls.pos);
    var nullPtr = struct.gen.nullPtr;
    return macro @:privateAccess $p{access(clsType)}.$nullPtr();
  }

  public static function allocBox(cls:Expr, ?initVal:Expr):Expr {
    var elCt = complexTypeExpr(cls);
    #if ammer
    var elType = resolveType(elCt, cls.pos);
    resolveType((macro : ammer.ffi.Box<$elCt>), cls.pos);
    var box = info.boxes.byElementTypeId[typeId2(elType)];
    #else
    // if baked, ammer.ffi.Box does not exist, only its monomorphisations
    var box = info.boxes.byElementTypeId[typeIdCt(elCt)];
    #end
    box != null || throw fail("not a known box type in allocBox call", cls.pos);
    var tp = expectTypePath(box.boxCt);
    if (isNull(initVal)) {
      return macro @:privateAccess new $tp($e{box.alloc});
    }
    return macro {
      var _allocated = @:privateAccess new $tp($e{box.alloc});
      _allocated.set($initVal);
      _allocated;
    };
  }

  public static function nullPtrBox(cls:Expr):Expr {
    var elCt = complexTypeExpr(cls);
    #if ammer
    var elType = resolveType(elCt, cls.pos);
    resolveType((macro : ammer.ffi.Box<$elCt>), cls.pos);
    var box = info.boxes.byElementTypeId[typeId2(elType)];
    #else
    // if baked, ammer.ffi.Box does not exist, only its monomorphisations
    var box = info.boxes.byElementTypeId[typeIdCt(elCt)];
    #end
    box != null || throw fail("not a known box type in nullPtrBox call", cls.pos);
    var tp = expectTypePath(box.boxCt);
    return macro @:privateAccess $p{accessTp(tp)}.nullPtr();
  }

  public static function allocArray(cls:Expr, size:Expr, ?initVal:Expr):Expr {
    var elCt = complexTypeExpr(cls);
    #if ammer
    var elType = resolveType(elCt, cls.pos);
    resolveType((macro : ammer.ffi.Array<$elCt>), cls.pos);
    var array = info.arrays.byElementTypeId[typeId2(elType)];
    #else
    // if baked, ammer.ffi.Array does not exist, only its monomorphisations
    var array = info.arrays.byElementTypeId[typeIdCt(elCt)];
    #end
    array != null || throw fail("not a known array type in allocArray call", cls.pos);
    var tp = expectTypePath(array.arrayCt);
    if (isNull(initVal)) {
      return macro {
        var _size = $size;
        @:privateAccess new $tp($e{array.alloc});
      }
    }
    return macro {
      var _size = $size;
      var _val = $initVal;
      var _allocated = @:privateAccess new $tp($e{array.alloc});
      for (i in 0..._size) {
        _allocated.set(i, _val);
      }
      _allocated;
    };
  }

  public static function nullPtrArray(cls:Expr):Expr {
    var elCt = complexTypeExpr(cls);
    #if ammer
    var elType = resolveType(elCt, cls.pos);
    resolveType((macro : ammer.ffi.Array<$elCt>), cls.pos);
    var array = info.arrays.byElementTypeId[typeId2(elType)];
    #else
    // if baked, ammer.ffi.Array does not exist, only its monomorphisations
    var array = info.arrays.byElementTypeId[typeIdCt(elCt)];
    #end
    array != null || throw fail("not a known array type in allocArray call", cls.pos);
    var tp = expectTypePath(array.arrayCt);
    return macro @:privateAccess $p{accessTp(tp)}.nullPtr();
  }

  public static function vecToArrayCopy(vec:Expr):Expr {
    var typed = withPos(vec.pos, () -> Context.typeExpr(vec));
    var elType = (switch (typed.t) {
      case TInst(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case TAbstract(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case _: throw fail("argument should be a haxe.ds.Vector", vec.pos);
    });
    var elCt = TypeTools.toComplexType(elType);
    var stored = Context.storeTypedExpr(typed);
    #if ammer
    // if baked, ammer.ffi.Array does not exist, only its monomorphisations
    resolveType((macro : ammer.ffi.Array<$elCt>), vec.pos);
    #end
    var array = info.arrays.byElementTypeId[typeId2(elType)];
    array != null || throw fail("not a known array type in vecToArrayCopy call", vec.pos);
    var tp = expectTypePath(array.arrayCt);
    return macro {
      var _vec = $vec;
      @:privateAccess new $tp($e{array.fromHaxeCopy});
    };
  }

  public static function vecToArrayRef(vec:Expr):Expr {
    var typed = withPos(vec.pos, () -> Context.typeExpr(vec));
    var elType = (switch (typed.t) {
      case TInst(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case TAbstract(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case _: throw fail("argument should be a haxe.ds.Vector", vec.pos);
    });
    var elCt = TypeTools.toComplexType(elType);
    var stored = Context.storeTypedExpr(typed);
    #if ammer
    // if baked, ammer.ffi.Array does not exist, only its monomorphisations
    resolveType((macro : ammer.ffi.Array<$elCt>), vec.pos);
    #end
    var array = info.arrays.byElementTypeId[typeId2(elType)];
    array != null || throw fail("not a known array type in vecToArrayRef call", vec.pos);
    var tp = expectTypePath(array.arrayRefCt);
    if (array.fromHaxeRef != null) {
      // if references are supported, create an array ref
      return macro {
        var _vec = $vec;
        @:privateAccess new $tp($e{array.fromHaxeRef}, _vec);
      };
    }
    // if not, create a fake ref with the same API
    return macro {
      var _vec = $vec;
      @:privateAccess new $tp($e{array.fromHaxeCopy}, _vec);
    };
  }

  public static function vecToArrayRefForce(vec:Expr):Expr {
    var typed = withPos(vec.pos, () -> Context.typeExpr(vec));
    var elType = (switch (typed.t) {
      case TInst(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case TAbstract(typeId(_.get()) => "haxe.ds.Vector.Vector", [el]): el;
      case _: throw fail("argument should be a haxe.ds.Vector", vec.pos);
    });
    var elCt = TypeTools.toComplexType(elType);
    var stored = Context.storeTypedExpr(typed);
    #if ammer
    // if baked, ammer.ffi.Array does not exist, only its monomorphisations
    resolveType((macro : ammer.ffi.Array<$elCt>), vec.pos);
    #end
    var array = info.arrays.byElementTypeId[typeId2(elType)];
    array != null || throw fail("not a known array type in vecToArrayRefForce call", vec.pos);
    var tp = expectTypePath(array.arrayRefCt);
    array.fromHaxeRef != null || throw fail("platform does not support non-copy references to Vector", vec.pos);
    return macro {
      var _vec = $vec;
      @:privateAccess new $tp($e{array.fromHaxeRef}, _vec);
    };
  }

  public static function createHaxeRef(cls:Expr, e:Expr):Expr {
    var elCt = complexTypeExpr(cls);
    var elType = resolveType(elCt, cls.pos);
    #if ammer
    // if baked, ammer.ffi.Haxe does not exist, only its monomorphisations
    resolveType((macro : ammer.ffi.Haxe<$elCt>), cls.pos);
    #end
    var elId = typeId2(elType);
    if (info.haxeRefs.byElementTypeId.exists(elId)) {
      var haxeRef = info.haxeRefs.byElementTypeId[elId];
      return macro {
        var _hxval = $e;
        $e{haxeRef.create};
      };
    }
    info.haxeRefs.byElementTypeId.exists(".Any.Any") || throw 0;
    return macro {
      var _hxval = $e;
      new ammer.internal.LibTypes.HaxeAnyRef<$elCt>($e{info.haxeRefs.byElementTypeId[".Any.Any"].create});
    };
  }
// ammer-fragment-end: lib-baked
}
