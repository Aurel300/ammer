package ammer.conv;

import haxe.macro.Context;
import haxe.macro.Expr;

class ArrayTools {
  public static function asShared(e:Expr):Expr {
    var expected = Context.getExpectedType();
    if (expected == null) {
      Context.fatalError("target type is not known", e.pos);
    }
    switch (expected) {
      case TAbstract(_.get().name => "ArrayWrapper", [
        TAbstract(_.get() => elemType, []),
        TInst(_.get() => arrayType, []),
      ]):
        var arrayTypeTp = {name: arrayType.name, pack: arrayType.pack, params: []};
        return (switch [Ammer.config.platform, elemType] {
          case [Cpp, {name: "Int", module: "StdTypes", pack: []}]:
            macro {
              var _ammer_vec = $e;
              @:privateAccess new ammer.conv.ArrayWrapper(
                new $arrayTypeTp(cast cpp.NativeArray.address(_ammer_vec.toData(), 0)),
                _ammer_vec.length
              );
            };
          case [Hl, {name: "Int", module: "StdTypes", pack: []}]:
            macro {
              var _ammer_vec = $e;
              @:privateAccess new ammer.conv.ArrayWrapper(
                $p{Utils.access(arrayType)}.ofNativeInt(_ammer_vec.toData()),
                _ammer_vec.length
              );
            };
          case _: Context.fatalError("asShared can only be applied to arrays of primitive types", e.pos);
        });
      case _:
        Context.fatalError("target type is not an array", e.pos);
    }
    throw "!";
  }

  public static function asCopy<T>(e:ExprOf<haxe.ds.Vector<T>>):Expr {
    var expected = Context.getExpectedType();
    if (expected == null) {
      Context.fatalError("target type is not known", e.pos);
    }
    switch (expected) {
      case TAbstract(_.get().name => "ArrayWrapper", [_, TInst(_.get() => arrayType, [])]):
        return macro {
          var _ammer_vec = $e;
          var _ammer_wrapper = @:privateAccess new ammer.conv.ArrayWrapper(
            $p{Utils.access(arrayType)}.alloc(_ammer_vec.length),
            _ammer_vec.length
          );
          // TODO: use faster platform-specific copy methods
          for (i in 0..._ammer_vec.length) {
            _ammer_wrapper[i] = _ammer_vec[i];
          }
          _ammer_wrapper;
        };
      case _:
        Context.fatalError("target type is not an array", e.pos);
    }
    throw "!";
  }
}
