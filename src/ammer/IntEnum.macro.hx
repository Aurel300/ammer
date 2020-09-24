package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class IntEnum<Const, T> {
  public static function initType():ComplexType {
    switch (Context.getLocalType()) {
      case TInst(_, [TInst(_.get() => {kind: KExpr(e = {expr: EConst(CString(_))})}, []), lib]):
        return TPath({
          name: "IntEnum",
          pack: ["ammer"],
          sub: "IntEnumProcessed",
          params: [TPExpr(e), TPType(TypeTools.toComplexType(lib))]
        });
      case _:
        throw Context.fatalError("ammer.IntEnum first type parameter should be a string", Context.currentPos());
    }
  }
}
