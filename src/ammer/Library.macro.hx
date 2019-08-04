package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;

class Library<Const> {
  public static function initLibrary():ComplexType {
    switch (Context.getLocalType()) {
      case TInst(_, [TInst(_.get() => {kind: KExpr(e)}, [])]):
        return TPath({
          name: "Library",
          pack: ["ammer"],
          sub: "LibraryProcessed",
          params: [TPExpr(e)]
        });
      case _:
        throw Context.fatalError("ammer.Library type parameter should be a string", Context.currentPos());
    }
  }
}
