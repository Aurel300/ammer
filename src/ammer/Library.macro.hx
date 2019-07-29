package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;

class Library<Const> {
  public static function initLibrary():ComplexType {
    trace(Context.getLocalType());
    return (macro : ammer.Library.LibraryProcessed);
  }

  public static function build():Array<Field> {
    return Ammer.build("adder");
  }
}
