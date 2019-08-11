package ammer.conv;

import haxe.io.Bytes as HaxeBytes;

abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
  public static inline function fromNative(ptr:hl.Bytes, size:Int):HaxeBytes
    return ptr.toBytes(size);

  public inline function toNative1():hl.Bytes
    return @:privateAccess this.b;

  public inline function toNative2():Int
    return this.length;
}
