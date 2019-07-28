package ammer;

class FFI {
  public var name:String;
  public var headers:Array<String> = [];
  public var fields:Array<FFIField> = [];

  public function new(name:String) {
    this.name = name;
  }
}

typedef FFIField = {
  kind:FFIFieldKind,
  annotations:Array<FFIFieldAnnotation>
};

enum FFIFieldAnnotation {
  ReturnSizeSameAs(arg:String);
}

enum FFIFieldKind {
  Method(name:String, args:Array<FFIType>, ret:FFIType);
  Value(name:String, type:FFIType);
}

enum FFIType {
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

  // markers
  ReturnSizePtr(t:FFIType);
  SizePtr(t:FFIType, of:String);
}
