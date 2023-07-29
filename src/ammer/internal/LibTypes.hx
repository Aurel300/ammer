package ammer.internal;

#if !macro

// TODO: version LibTypes as well?

@:ammer.lib.linkNames([])
@:ammer.sub((_ : ammer.ffi.Bytes))
@:ammer.sub((_ : ammer.ffi.FilePtr))
@:ammer.sub((_ : ammer.ffi.FilePtr.FilePos))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Bool>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.UInt8>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.UInt16>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.UInt32>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.UInt64>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Int8>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Int16>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Int32>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Int64>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Float32>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.Float64>))
@:ammer.sub((_ : ammer.ffi.Box<ammer.ffi.String>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Bool>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.UInt8>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.UInt16>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.UInt32>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.UInt64>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Int8>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Int16>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Int32>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Int64>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Float32>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Float64>))
@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.String>))
//@:ammer.sub((_ : ammer.ffi.Array<ammer.ffi.Bytes>))
@:ammer.sub((_ : ammer.ffi.Haxe<Any>))
class LibTypes extends ammer.def.Library<"libtypes"> {}

abstract HaxeAnyRef<T>({
  var value(get, never):Any;
  function incref():Void;
  function decref():Void;
}/*ammer.ffi.Haxe<Any>*/)/* to ammer.ffi.Haxe<Any>*/ {
  public inline function new(r:ammer.ffi.Haxe<Any>) {
    this = r;
  }

  public var value(get, never):T;
  inline function get_value():T {
    return (cast this.value : T);
  }
  //inline function set_value(value:T):T {
  //  return (cast (this.value = value) : T);
  //}

  public inline function incref():Void this.incref();
  public inline function decref():Void this.decref();

  public inline function toNative():Any return this;
}

#else
class LibTypes {}
class LibTypes_LibTypes_AmmerSetup {
  public static function init():Void {}
}
#end
