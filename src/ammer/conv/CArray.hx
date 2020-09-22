package ammer.conv;

import haxe.ds.Vector;

abstract CArray<T>(Vector<T>) from Vector<T> to Vector<T> {
  public static inline function fromNative(_, _)
    throw "not implemented";

  public inline function toNative1()
    throw "not implemented";

  public inline function toNative2()
    throw "not implemented";
}
