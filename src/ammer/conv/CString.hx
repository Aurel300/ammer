package ammer.conv;

import String as HaxeString;

abstract CString(HaxeString) from HaxeString to HaxeString {
  public static inline function fromNative(_)
    throw "not implemented";

  public inline function toNative()
    throw "not implemented";
}
