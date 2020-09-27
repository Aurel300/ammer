package ammer;

import haxe.macro.Expr;

@:using(ammer.FFITools)
enum FFIType {
  Void;

  // integer types
  Bool; // == I32("bool") ?
  Int; // == I32(null)
  I8(?aliasTo:String);
  I16(?aliasTo:String);
  I32(?aliasTo:String);
  I64(?aliasTo:String);
  UI8(?aliasTo:String);
  UI16(?aliasTo:String);
  UI32(?aliasTo:String);
  UI64(?aliasTo:String);

  // numeric types
  Float;
  Single;

  // pointer types
  Bytes;
  String;
  Array(_:FFIType);

  // library types
  This;
  LibType(_:AmmerTypeContext, argThis:Bool);
  LibIntEnum(_:AmmerTypeContext);
  LibSub(_:AmmerTypeContext);
  OutPointer(_:FFIType);
  Nested(_:FFIType);

  // special types
  Derived(e:Expr, t:FFIType);
  WithSize(e:Expr, t:FFIType);

  Closure(typeIdx:Int, args:Array<FFIType>, ret:FFIType, mode:RootMode);
  ClosureDataUse;
  ClosureData(arg:Int);

  NoSize(t:FFIType);
  SameSizeAs(t:FFIType, arg:Int);
  SizeOf(arg:Int);
  SizeOfReturn;
  SizeOfField(name:String);
}

enum RootMode {
  None;
  Forever;
  Once;
}
