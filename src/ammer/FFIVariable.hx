package ammer;

import haxe.macro.Expr;

typedef FFIVariable = {
  name:String,
  uniqueName:String,
  index:Int,
  native:String,
  type:FFIType,
  field:Field,
  target:{pack:Array<String>, module:String, cls:String, field:String}
};
