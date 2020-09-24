package ammer.conv;

import haxe.io.Bytes as HaxeBytes;
import lua.NativeStringTools;
import lua.Table;

abstract Bytes(HaxeBytes) from HaxeBytes to HaxeBytes {
  public static function fromNative(ptr:String, size:Int):HaxeBytes {
    var data = [];
    for (i in 0...ptr.length) {
      data.push(NativeStringTools.byte(ptr, i + 1));
    }
    return @:privateAccess new HaxeBytes(ptr.length, data);
  }

  public function toNative1():String {
    var b = this.getData();
    var t:Table<Int, String> = Table.create();
    for (i in 0...b.length) {
      Table.insert(t, NativeStringTools.char(b[i]));
    }
    return Table.concat(t);
  }

  public inline function toNative2():Int
    return this.length;
}
