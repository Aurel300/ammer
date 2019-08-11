package ammer.conv;

import String as HaxeString;

abstract CString(HaxeString) from HaxeString to HaxeString {
  public static inline function fromNative(str:HaxeString):HaxeString
    return str;

  public inline function toNative():HaxeString
    return this;
}
