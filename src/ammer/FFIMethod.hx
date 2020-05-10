package ammer;

import haxe.macro.Expr;

typedef FFIMethod = {
  name:String,
  uniqueName:String, // prefixed by type id if needed
  native:String,
  cPrereturn:Null<String>,
  cReturn:Null<String>,
  isMacro:Bool,
  args:Array<FFIType>,
  ret:FFIType,
  field:Field
};
