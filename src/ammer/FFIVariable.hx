package ammer;

import haxe.macro.Expr;

typedef FFIVariable = {
  name:String,
  index:Int,
  native:String,
  type:FFIType,
  field:Field
};
