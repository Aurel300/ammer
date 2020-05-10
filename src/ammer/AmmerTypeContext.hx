package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;

typedef AmmerTypeContext = {
  implType:ClassType,
  implTypePath:TypePath,
  nativeName:String,
  nativePrefix:String,
  nativeType:ComplexType,
  originalFields:Array<Field>,
  library:ComplexType,
  processed:Array<Field>,
  isStruct:Bool,
  ffiMethods:Array<FFIMethod>,
  ffiVariables:Array<FFIStructVariable>,
  libraryCtx:AmmerContext // only set when patching
};
