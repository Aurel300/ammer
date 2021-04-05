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
  ArrayDynamic(typeIdx:Int, type:FFIType);
  ArrayFixed(typeIdx:Int, type:FFIType, size:Int); // TODO: change index to instance, same in closure

  // library types
  This;
  LibType(_:AmmerTypeContext, argThis:Bool);
  LibIntEnum(_:AmmerTypeContext, argThis:Bool);
  LibSub(_:AmmerTypeContext);
  OutPointer(_:FFIType);
  Nested(_:FFIType);
  Alloc(_:FFIType);

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

  // target specific
  NativeHl(t:ComplexType, ffiName:String, cName:String);
}

enum RootMode {
  None;
  Forever;
  Once;
}
