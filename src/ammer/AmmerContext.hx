package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;

typedef AmmerContext = {
  config:AmmerConfig,
  libname:String,
  includePath:String,
  libraryPath:String,
  headers:Array<String>,
  // impl = the original class (extends Library ...)
  implType:ClassType,
  implFields:Array<Field>,
  // extern = field with extern functions, hlNative ...
  externName:String,
  externFields:Array<Field>,
  externIsExtern:Bool,
  externMeta:Array<MetadataEntry>,
  ffi:FFI,
  stub:ammer.stub.Stub
};
