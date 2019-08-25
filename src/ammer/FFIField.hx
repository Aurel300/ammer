package ammer;

enum FFIField {
  Method(name:String, native:String, args:Array<FFIType>, ret:FFIType);
  Value(name:String, type:FFIType);
}
