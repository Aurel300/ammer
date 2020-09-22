package ammer.conv;

import String as HaxeString;

abstract CString(HaxeString) from HaxeString to HaxeString {
  public static inline function fromNative(ptr:cpp.ConstCharStar):HaxeString
    return ptr.toString();

  public inline function toNative():cpp.ConstCharStar
    return cpp.ConstCharStar.fromString(this);
}
