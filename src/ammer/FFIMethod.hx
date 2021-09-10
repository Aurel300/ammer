package ammer;

import haxe.macro.Expr;

typedef FFIMethod = {
  name:String,
  uniqueName:String, // prefixed by type id if needed
  native:String,
  cPrereturn:Null<String>,
  cReturn:Null<String>,
  // TODO: instead of is* fields have an enum
  isMacro:Bool,
  isCppConstructor:Bool,
  isCppMemberCall:Bool,
  args:Array<FFIType>,
  ret:FFIType,
  field:Field
};
