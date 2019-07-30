package ammer;

enum FFIField {
  Method(name:String, args:Array<FFIType>, ret:FFIType);
  Value(name:String, type:FFIType);
}
