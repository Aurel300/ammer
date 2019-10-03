package ammer;

import haxe.macro.Expr;

typedef FFIMethod = {
  name:String,
  native:String,
  args:Array<FFIType>,
  ret:FFIType,
  field:Field
};
