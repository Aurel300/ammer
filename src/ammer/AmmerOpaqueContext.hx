package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;

typedef AmmerOpaqueContext = {
  implType:ClassType,
  implTypePath:TypePath,
  nativeName:String,
  nativePrefix:String,
  nativeType:ComplexType,
  originalFields:Array<Field>,
  library:ComplexType,
  processed:Array<Field>,
  libraryCtx:AmmerContext // only set when patching
};
