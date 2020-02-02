package ammer;

import haxe.macro.Expr;

typedef FFIMethod = {
  name:String,
  native:String,
  cPrereturn:Null<String>,
  cReturn:Null<String>,
  isMacro:Bool,
  args:Array<FFIType>,
  ret:FFIType,
  field:Field
};
