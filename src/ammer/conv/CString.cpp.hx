package ammer.conv;

import String as HaxeString;

abstract CString(HaxeString) from HaxeString to HaxeString {
  public static inline function fromNative(ptr:cpp.Pointer<cpp.Char>):HaxeString
    return cpp.NativeString.fromPointer(ptr);

  public inline function toNative():cpp.ConstPointer<cpp.Char>
    return cpp.NativeString.c_str(this);
}
