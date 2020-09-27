package ammer;

typedef FFIClosureSignature = {
  index:Int,
  args:Array<FFIType>,
  ret:FFIType,
  dataAccess:Array<String>
};
