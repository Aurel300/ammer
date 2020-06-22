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

  // library types
  This;
  LibType(id:String, argThis:Bool);
  LibEnum(id:String);
  LibSub(id:String);
  OutPointer(_:FFIType);

  // special types
  Derived(e:(arg:Int->Expr)->Expr, t:FFIType);
  Closure(typeIdx:Int, args:Array<FFIType>, ret:FFIType, mode:RootMode);
  ClosureDataUse;
  ClosureData(arg:Int);

  NoSize(t:FFIType);
  SameSizeAs(t:FFIType, arg:Int);
  SizeOf(arg:Int);
  SizeOfReturn;
}

enum RootMode {
  None;
  Forever;
  Once;
}
