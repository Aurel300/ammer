package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;

typedef AmmerContext = {
  config:AmmerConfig,
  libname:String,
  // impl = the original class (extends Library ...)
  implType:ClassType,
  implFields:Array<Field>,
  // extern = field with extern functions, hlNative ...
  externName:String,
  externFields:Array<Field>,
  ffi:FFI,
  stub:ammer.stub.Stub
};
