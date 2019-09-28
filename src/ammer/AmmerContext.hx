package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;
import ammer.AmmerConfig.AmmerLibraryConfig;

/**
  This object is created once per `ammer` library. It is updated during the
  various processing stages.
**/
typedef AmmerContext = {
  /**
    Configuration stage.
  **/
  config:AmmerConfig,
  libraryConfig:AmmerLibraryConfig,
  /**
    FFI mapping stage.
  **/
  ffi:FFI,
  nativePrefix:String,
  opaqueTypes:Map<String, AmmerOpaqueContext>,
  methodContexts:Array<AmmerMethodPatchContext>,
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
