package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;
import ammer.Config.AmmerLibraryConfig;

/**
  This object is created once per `ammer` library. It is updated during the
  various processing stages.
**/
typedef AmmerContext = {
  /**
    Configuration stage.
  **/
  index:Int,
  config:Config,
  libraryConfig:AmmerLibraryConfig,
  subtypes:Array<ComplexType>,
  /**
    FFI mapping stage.
  **/
  ffiMethods:Array<FFIMethod>,
  ffiConstants:Map<FFIType, Array<FFIConstant>>,
  closureTypes:Array<FFIClosureSignature>,
  arrayTypes:Array<FFIArrayType>,
  nativePrefix:String,
  types:Map<String, AmmerTypeContext>,
  methodContexts:Array<AmmerMethodPatchContext>,
  /**
    Patching stage.
  **/
  // the original class
  implType:ClassType,
  implComplexType:ComplexType,
  implFields:Array<Field>,
  // class with `extern` functions, `@:hlNative` ...
  externName:String,
  externFields:Array<Field>,
  externIsExtern:Bool,
  externMeta:Array<MetadataEntry>
};
