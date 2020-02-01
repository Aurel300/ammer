package ammer;

import haxe.macro.Expr;

typedef FFIMethod = {
  name:String,
  native:String,
  cPrereturn:Null<String>,
  cReturn:Null<String>,
  args:Array<FFIType>,
  ret:FFIType,
  field:Field
};
