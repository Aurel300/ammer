package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;

class CLibrary<Const> {
  public static function initLibrary():ComplexType {
    trace(Context.getLocalType());
    return (macro : ammer.CLibrary.CLibraryProcessed);
  }

  public static function build():Array<Field> {
    return Ammer.build("adder");
  }
}
