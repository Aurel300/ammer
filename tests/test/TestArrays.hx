package test;

using ammer.conv.ArrayTools;

class TestArrays extends Test {
  function testArrays() {
    #if (hl || cpp)
    var arr = haxe.ds.Vector.fromArrayCopy([1, 2, 4]);
    eq(Native.take_array_fixed(arr.asCopy()), 7);
    eq(Native.take_array(arr.asCopy()), 7);
    eq(Native.take_array_fixed(arr.asShared()), 7);
    eq(Native.take_array(arr.asShared()), 7);

    Native.take_array_modify(arr.asShared());
    eq(arr[1], 42);
    #else
    noAssert();
    #end
  }
}
