package ammer.def;

#if macro

import haxe.macro.Expr;

class Enum {
  public static function build(name:String, ffi:Expr, lib:Expr):Array<Field> {
    return ammer.internal.Entrypoint.buildEnum(name, ffi, lib);
  }
}

#end
