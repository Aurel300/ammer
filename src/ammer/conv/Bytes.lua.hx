package ammer.conv;

import haxe.io.Bytes as HaxeBytes;

abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
  // TODO: proper bytes (Array<Int> in Haxelua???)
  public static inline function fromNative(ptr:HaxeBytes, size:Int):HaxeBytes
    return ptr;

  public inline function toNative1():HaxeBytes
    return this;

  public inline function toNative2():Int
    return this.length;
}
