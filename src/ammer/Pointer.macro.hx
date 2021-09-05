package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class Pointer<Const, T> {
  public static function initType(star:Bool):ComplexType {
    switch (Context.getLocalType()) {
      case TInst(_, [TInst(_.get() => {kind: KExpr(e = {expr: EConst(CString(_))})}, []), lib]):
        return TPath({
          name: star ? "Pointer" : "PointerNoStar",
          pack: ["ammer"],
          sub: star ? "PointerProcessed" : "PointerNoStarProcessed",
          params: [TPExpr(e), TPType(TypeTools.toComplexType(lib))]
        });
      case _:
        throw Context.fatalError("ammer.Pointer first type parameter should be a string", Context.currentPos());
    }
  }
}
