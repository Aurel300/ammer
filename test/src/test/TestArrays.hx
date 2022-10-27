package test;

@:ammertest.code("native.h", <x>
  LIB_EXPORT int take_array_fixed(int a[3]);
  LIB_EXPORT int take_array(int *a, size_t b);
  LIB_EXPORT void take_array_modify(int *a);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT int take_array_fixed(int a[3]) {
    if (a[0] != 1 || a[1] != 2 || a[2] != 4)
      return -1;
    return a[0] + a[1] + a[2];
  }
  LIB_EXPORT int take_array(int *a, size_t b) {
    if (b != 3 || a[0] != 1 || a[1] != 2 || a[2] != 4)
      return -1;
    return a[0] + a[1] + a[2];
  }
  LIB_EXPORT void take_array_modify(int *a) {
    a[1] = 42;
  }
</x>)
class TestArraysNative extends ammer.def.Sublibrary<def.Native> {
  public static function take_array_fixed(a:ammer.ffi.Array<Int>):Int;
  public static function take_array(
    @:ammer.skip _:haxe.ds.Vector<Int>,
    @:ammer.derive(ammer.Lib.vecToArrayCopy(arg0)) _:ammer.ffi.Array<Int>,
    @:ammer.derive(arg0.length) _:ammer.ffi.Size
  ):Int;
  public static function take_array_modify(a:ammer.ffi.Array<Int>):Void;
}

class TestArrays extends Test implements ammer.Syntax {
  function testArrays() {
    var arr = ammer.Lib.allocArray(Int, 3);
    arr.set(0, 1);
    arr.set(1, 2);
    arr.set(2, 4);
    eq(TestArraysNative.take_array_fixed(arr), 7);
  
    var vec:haxe.ds.Vector<Int> = haxe.ds.Vector.fromArrayCopy([1, 2, 4]);
    var arr = ammer.Lib.vecToArrayCopy(vec);
    eq(TestArraysNative.take_array_fixed(arr), 7);

    eq(TestArraysNative.take_array(vec), 7);

    #if !(lua || neko || js || python)
    eq(@ret TestArraysNative.take_array_fixed(@ref vec), 7);

    var arrRef = ammer.Lib.vecToArrayRefForce(vec);
    eq(TestArraysNative.take_array_fixed(arrRef.array), 7);
    TestArraysNative.take_array_modify(arrRef.array);
    arrRef.unref();
    eq(vec[1], 42);
    #end

    vec[1] = 2;

    TestArraysNative.take_array_modify(@copyfree vec);
    eq(vec[1], 2);

    TestArraysNative.take_array_modify(@copy vec);
    eq(vec[1], 2);

    #if !(lua || neko || js || python)
    TestArraysNative.take_array_modify(@ref vec);
    eq(vec[1], 42);
    #end
  }
}
