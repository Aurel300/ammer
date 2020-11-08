package ammer;

import haxe.macro.Expr;

typedef FFIConstant = {
  name:String,
  uniqueName:String,
  index:Int,
  native:String,
  type:FFIType,
  nativeType:FFIType,
  field:Field,
  target:{pack:Array<String>, module:String, cls:String, field:String}
};
