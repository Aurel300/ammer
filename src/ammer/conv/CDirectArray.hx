package ammer.conv;

abstract CDirectArray<T>(CDirectArrayImpl<T>) {
  @:arrayAccess public function get(idx:Int):T {
    return cpp.Pointer.arrayElem(this, idx);
  }
}

class CDirectArrayImpl<T> {
  
}
