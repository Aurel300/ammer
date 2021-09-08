package ammer;

import haxe.macro.Expr;

@:using(ammer.FFITools)
enum FFIType {
  Void;

  // numeric types
  Bool; // == Integer(Bool) ?
  Integer(kind:IntegerKind);
  Float(kind:FloatKind);

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

  Unsupported(cName:String);

  // target specific
  NativeHl(t:ComplexType, ffiName:String, cName:String);
}

enum IntegerKind {
  Signed8;
  Signed16;
  Signed32;
  Signed64;
  Unsigned8;
  Unsigned16;
  Unsigned32;
  Unsigned64;
  //Custom(cName:String, signed:Bool, bits:Int);
}

enum FloatKind {
  Float32;
  Float64;
  //Custom(cName:String, bits:Int);
}

enum RootMode {
  None;
  Forever;
  Once;
}
