package ammer.conv;

import String as HaxeString;

abstract CString(HaxeString) from HaxeString to HaxeString {
  public static inline function fromNative(ptr:hl.Bytes):HaxeString
    return ptr != null ? @:privateAccess String.fromUTF8(ptr) : null;

  public inline function toNative():hl.Bytes
    return this != null ? @:privateAccess this.toUtf8() : null;
}
