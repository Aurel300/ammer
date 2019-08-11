package ammer.conv;

import haxe.io.Bytes as HaxeBytes;

abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
  public static inline function fromNative(ptr:cpp.Pointer<cpp.UInt8>, size:Int):HaxeBytes
    return @:privateAccess new HaxeBytes(size, ptr.toUnmanagedArray(size));

  public inline function toNative1():cpp.Pointer<cpp.UInt8>
    return cpp.Pointer.ofArray(@:privateAccess this.b);

  public inline function toNative2():Int
    return this.length;
}
