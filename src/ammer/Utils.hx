package ammer;

import haxe.macro.Expr;

class Utils {
  public static var posStack = [];
  public static var argNames:Array<String>;

  public static function withPos(f:()->Void, p:Position):Void {
    posStack.push(p);
    f();
    posStack.pop();
  }

  public static function an(name:String):Expr {
    if (argNames.indexOf(name) == -1)
      throw "no such arg";
    return Utils.id('_arg${argNames.indexOf(name)}');
  }

  public static inline function e(e:ExprDef):Expr {
    return {expr: e, pos: posStack[posStack.length - 1]};
  }

  public static inline function id(s:String):Expr {
    return e(EConst(CIdent(s)));
  }
}
