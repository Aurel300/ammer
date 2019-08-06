package ammer;

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

  // special types
  SameSizeAs(t:FFIType, arg:String);
  SizeOf(arg:String);
  SizeOfReturn;
}
