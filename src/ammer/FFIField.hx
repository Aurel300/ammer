package ammer;

import haxe.macro.Expr;

enum FFIField {
  Method(name:String, native:String, args:Array<FFIType>, ret:FFIType, impl:Field);
  // Value(name:String, type:FFIType);
}
