package ammer.conv;

abstract ArrayWrapper<T, U:{
  function get(idx:Int):T;
  function set(idx:Int, val:T):Void;
}>({
  array: U,
  length: Int,
}) {
  public var length(get, never):Int;
  private inline function get_length():Int {
    return this.length;
  }

  private inline function new(array:U, length:Int) {
    this = {
      array: array,
      length: length,
    };
  }

  public inline function toNative():U {
    return this.array;
  }

  @:arrayAccess
  private inline function wrapperGet(idx:Int):T {
    return this.array.get(idx);
  }

  @:arrayAccess
  private inline function wrapperSet(idx:Int, val:T):Void {
    this.array.set(idx, val);
  }

  public function toVector():haxe.ds.Vector<T> {
    var ret = new haxe.ds.Vector(this.length);
    for (i in 0...this.length) {
      ret[i] = this.array.get(i);
    }
    return ret;
  }

  public function toArray():Array<T> {
    return [ for (i in 0...this.length) this.array.get(i) ];
  }

  // TODO: add (optional) exceptions when writing outside bounds
}
