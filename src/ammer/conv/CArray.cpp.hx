package ammer.conv;

import haxe.ds.Vector;

abstract CArray<T>(Vector<T>) from Vector<T> to Vector<T> {
  public static inline function fromNative<T>(ptr:cpp.Star<T>, size:Int):Vector<T>
    return cpp.Pointer.fromStar(ptr).toUnmanagedVector(size);

  public inline function toNative1():cpp.Star<T>
    return cpp.Pointer.ofArray(this.toData()).ptr;

  public inline function toNative2():Int
    return this.length;
}

/*
abstract CArray<T>(Vector<T>) from Vector<T> to Vector<T> {
  public static inline function fromNative<T>(ptr:Array<T>, size:Int):Vector<T>
    return cpp.Pointer.ofArray(ptr).toUnmanagedVector(size);

  public inline function toNative1():Array<T>
    return this.toData();

  public inline function toNative2():Int
    return this.length;
}
*/