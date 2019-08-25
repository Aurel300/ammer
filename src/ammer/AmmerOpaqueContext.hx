package ammer;

import haxe.macro.Expr;
import haxe.macro.Type;
import ammer.AmmerConfig.AmmerLibraryConfig;

typedef AmmerOpaqueContext = {
  implType:ClassType,
  implTypePath:TypePath,
  nativeName:String,
  nativeType:ComplexType,
  originalFields:Array<Field>,
  library:ComplexType,
  processed:Array<Field>
};
