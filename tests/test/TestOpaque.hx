package test;

class TestOpaque extends Test {
  function testOpaque() {
    #if (hl || cpp || lua)
    var opaque:Native.NativeOpaque = Native.create_opaque();
    eq(opaque.get_int(), 1);
    eq(opaque.get_float(), 2.0);
    eq(opaque.get_string(), "3");
    eq(opaque.get_int_alt(3, 4), 8);
    #else
    noAssert();
    #end
  }

  function testVariables() {
    #if (hl || cpp || lua)
    var opaque:Native.NativeOpaque = Native.create_opaque();
    opaque.member_int = 3;
    eq(opaque.get_int(), 3);
    opaque.member_int = 5;
    eq(opaque.member_int, 5);
    opaque.member_float = 3.12;
    eq(opaque.get_float(), 3.12);
    opaque.member_float = 5.12;
    eq(opaque.member_float, 5.12);
    // passing strings directly might be a bit dangerous
    opaque.member_string = "foo";
    eq(opaque.get_string(), "foo");
    opaque.member_string = "bar";
    eq(opaque.member_string, "bar");
    beq(opaque.get_bytes(), haxe.io.Bytes.ofHex("626172"));
    #else
    noAssert();
    #end
  }

  function testAlloc() {
    #if (hl || cpp || lua)
    var opaque:Native.NativeOpaque = Native.NativeOpaque.alloc();
    opaque.member_int = 7;
    eq(opaque.get_int(), 7);
    opaque.member_int = 49;
    eq(opaque.member_int, 49);
    opaque.free();
    #else
    noAssert();
    #end
  }

  function testOutPointer() {
    #if (hl || cpp)
    var opaque = Native.NativeOpaque.nullPointer();
    Native.opaque_indirect(opaque);
    eq(opaque.member_int, 10);
    eq(opaque.member_float, 4.0);
    eq(opaque.member_string, "indirect");
    opaque.free();
    #else
    noAssert();
    #end
  }

  #if cpp
  function testArray() {
    var opaque = Native.create_opaque();
    /*
    var arr = opaque.member_int_array;
    for (i in 0...17) {
      eq(arr[i], 0xB0057ED + i);
    }
    */
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
  }
  #end
}
