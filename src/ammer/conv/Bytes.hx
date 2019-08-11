package ammer.conv;

import haxe.io.Bytes as HaxeBytes;

abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
  public static inline function fromNative(_, _)
    throw "not implemented";

  public inline function toNative1()
    throw "not implemented";

  public inline function toNative2()
    throw "not implemented";
}
