package ammer.conv;

abstract ArrayWrapper<T, U:{
  function get(idx:Int):T;
  function set(idx:Int, val:T):Void;
}>(U) from U to U {
  @:arrayAccess
  public inline function wrapperGet(idx:Int):T {
    return this.get(idx);
  }

  @:arrayAccess
  public inline function wrapperSet(idx:Int, val:T):Void {
    this.set(idx, val);
  }

  // TODO: figure out how to remember array length
  // TODO: toVector, toArray, copyFromVector, copyFromArray
  // TODO: add (optional) exceptions when writing outside bounds
}
