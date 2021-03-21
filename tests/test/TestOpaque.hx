package test;

import Native.NativeOpaque;

class TestOpaque extends Test {
  function testOpaque() {
    var opaque:NativeOpaque = Native.create_opaque();
    eq(opaque.get_int(), 1);
    feq(opaque.get_float(), 2.0);
    eq(opaque.get_string(), "3");
    eq(opaque.get_int_alt(3, 4), 8);
  }

  function testVariables() {
    var opaque:NativeOpaque = Native.create_opaque();
    opaque.member_int = 3;
    eq(opaque.get_int(), 3);
    opaque.member_int = 5;
    eq(opaque.member_int, 5);
    opaque.member_float = 3.12;
    feq(opaque.get_float(), 3.12);
    opaque.member_float = 5.12;
    feq(opaque.member_float, 5.12);
    // passing strings directly might be a bit dangerous
    opaque.member_string = "foo";
    eq(opaque.get_string(), "foo");
    opaque.member_string = "bar";
    eq(opaque.member_string, "bar");
    beq(opaque.get_bytes(), haxe.io.Bytes.ofHex("626172"));
  }

  function testAlloc() {
    var opaque:NativeOpaque = NativeOpaque.alloc();
    opaque.member_int = 7;
    eq(opaque.get_int(), 7);
    opaque.member_int = 49;
    eq(opaque.member_int, 49);
    opaque.free();
  }

  function testOutPointer() {
    #if (hl || cpp)
    var opaque = NativeOpaque.nullPointer();
    Native.opaque_indirect(opaque);
    eq(opaque.member_int, 10);
    feq(opaque.member_float, 4.0);
    eq(opaque.member_string, "indirect");
    opaque.free();
    #else
    noAssert();
    #end
  }

  function testNested() {
    #if (hl || cpp)
    var opaque:NativeOpaque = Native.create_opaque_noalloc();
    eq(opaque.get_int(), 61);
    feq(opaque.get_float(), 5.2);
    eq(opaque.get_string(), "noalloc");
    for (i in 0...8) {
      eq(opaque.member_int_array[i], 9 + i);
    }
    opaque.member_int = 62;
    opaque.member_float = 5.4;
    opaque.member_int_array[7] = 47;
    eq(Native.opaque_take_nested(opaque), true);
    opaque.free();
    #else
    noAssert();
    #end
  }

  function testArray() {
    var opaque = Native.create_opaque();
    var arr = opaque.member_int_array;
    for (i in 0...8) {
      eq(arr[i], 0xB0057ED + i);
      arr[i] = 0xDE7500B + i;
    }
    for (i in 0...8) {
      eq(arr[i], 0xDE7500B + i);
    }
    /*
    var arr = opaque.member_string_array;
    eq(arr[0], "arrfoo");
    eq(arr[1], "arrbar");
    eq(arr[2], "arrbaz");
    opaque.member_string_array = haxe.ds.Vector.fromArrayCopy(["xxx", "yyy", "zzz", "www"]);
    var arr = opaque.member_string_array;
    eq(arr[0], "xxx");
    eq(arr[1], "yyy");
    eq(arr[2], "zzz");
    eq(arr[3], "www");
    */
  }
}
