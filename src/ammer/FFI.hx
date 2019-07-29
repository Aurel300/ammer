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
