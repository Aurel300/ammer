package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;

/**
  This object is created once per `ammer` library. It is updated during the
  various processing stages.
**/
typedef AmmerContext = {
  /**
    Configuration stage.
  **/
  config:AmmerConfig,
  libname:String,
  includePath:String,
  libraryPath:String,
  headers:Array<String>,
  /**
    FFI mapping stage.
  **/
  ffi:FFI,
  /**
    Patching stage.
  **/
  // the original class
  implType:ClassType,
  implFields:Array<Field>,
  // class with `extern` functions, `@:hlNative` ...
  externName:String,
  externFields:Array<Field>,
  externIsExtern:Bool,
  externMeta:Array<MetadataEntry>
};
