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

  // pointer types
  Bytes;
  String;

  // opaque types
  This;
  Opaque(name:String, argThis:Bool);

  // special types
  Derived(e:(arg:Int->Expr)->Expr, t:FFIType);
  Function(args:Array<FFIType>, ret:FFIType, mode:RootMode);

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
