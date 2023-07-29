package test;

import ammer.ffi.This;

// TODO: "opaque" is now a misnomer
@:ammer.nativePrefix("opaque_")
@:ammer.alloc
class NativeOpaque extends ammer.def.Struct<"opaque_type_t", def.Native> {
  @:ammer.native("member_int") public var member_int:Int;
  @:ammer.native("member_float") public var member_float:Float;
  @:ammer.native("member_string") public var member_string:String;
  /*
  @:ammer.native("member_int_array_fixed") public var member_int_array_fixed:ammer.ffi.ArrayFixed<Int, 8>;
  #if (hl || cpp)
  @:ammer.native("member_int_array") public var member_int_array:ammer.ffi.ArrayDynamic<Int>;
  @:ammer.native("member_int_array_size") public var member_int_array_size:ammer.ffi.SizeOf<"member_int_array">;
  @:ammer.native("member_string_array") public var member_string_array:ammer.ffi.ArrayDynamic<String>;
  @:ammer.native("member_string_array_size") public var member_string_array_size:ammer.ffi.SizeOf<"member_string_array">;
  #end
*/
  public function get_int(_:This):Int;
  public function get_float(_:This):Float;
  public function get_string(_:This):String;
  public function get_int_alt(_:Int, _:This, _:Int):Int;
  //public function get_bytes(_:This, _:SizeOfReturn):Bytes;

  public function get_int_nested(_:ammer.ffi.Deref<This>):Int;
}
/*
class NativeOpaque2 extends ammer.def.PointerNoStar<"opaque_type_ptr", def.Native> {
  @:ammer.native("opaque_get_int") public function get_int(_:This):Int;
}
*/

@:ammer.sub((_ : test.TestDatatypes.NativeOpaque))
// @:ammer.sub((_ : test.TestDatatypes.NativeOpaque2))
@:ammertest.code("native.h", <x>
  typedef struct {
    int member_int;
    double member_float;
    const char *member_string;

    int member_int_array_fixed[8];
    int *member_int_array;
    int member_int_array_size;
    const char **member_string_array;
    int member_string_array_size;
  } opaque_type_t;
  typedef opaque_type_t *opaque_type_ptr;

  LIB_EXPORT opaque_type_ptr create_opaque(void);
  LIB_EXPORT int opaque_get_int(opaque_type_ptr a);
  LIB_EXPORT int opaque_get_int_nested(opaque_type_t a);
  LIB_EXPORT double opaque_get_float(opaque_type_ptr a);
  LIB_EXPORT const char *opaque_get_string(opaque_type_ptr a);
  LIB_EXPORT int opaque_get_int_alt(int a, opaque_type_ptr b, int c);
  LIB_EXPORT unsigned char *opaque_get_bytes(opaque_type_ptr a, size_t *b);
  LIB_EXPORT void opaque_indirect(opaque_type_ptr *out);
  LIB_EXPORT opaque_type_t create_opaque_noalloc(void);
  LIB_EXPORT bool opaque_take_nested(opaque_type_t a);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT opaque_type_ptr create_opaque(void) {
    opaque_type_ptr ret = malloc(sizeof(opaque_type_t));
    ret->member_int = 1;
    ret->member_float = 2.0f;
    ret->member_string = "3";
    for (int i = 0; i < 8; i++) {
      ret->member_int_array_fixed[i] = 0xB0057ED + i;
    }
    ret->member_int_array = (int *)calloc(17, sizeof(int));
    ret->member_int_array_size = 17;
    for (int i = 0; i < 17; i++) {
      ret->member_int_array[i] = 0xB00573D + i;
    }
    ret->member_string_array = (const char **)calloc(3, sizeof(char *));
    ret->member_string_array_size = 3;
    ret->member_string_array[0] = "arrfoo";
    ret->member_string_array[1] = "arrbar";
    ret->member_string_array[2] = "arrbaz";
    return ret;
  }
  LIB_EXPORT int opaque_get_int(opaque_type_ptr a) {
    return a->member_int;
  }
  LIB_EXPORT int opaque_get_int_nested(opaque_type_t a) {
    return a.member_int;
  }
  LIB_EXPORT double opaque_get_float(opaque_type_ptr a) {
    return a->member_float;
  }
  LIB_EXPORT const char *opaque_get_string(opaque_type_ptr a) {
    return a->member_string;
  }
  LIB_EXPORT int opaque_get_int_alt(int a, opaque_type_ptr b, int c) {
    return a + b->member_int + c;
  }
  LIB_EXPORT unsigned char *opaque_get_bytes(opaque_type_ptr a, size_t *b) {
    size_t len = strlen(a->member_string);
    unsigned char *ret = malloc(len);
    memcpy(ret, a->member_string, len);
    *b = len;
    return ret;
  }
  LIB_EXPORT void opaque_indirect(opaque_type_ptr *out) {
    opaque_type_ptr ret = malloc(sizeof(opaque_type_t));
    ret->member_int = 10;
    ret->member_float = 4.0f;
    ret->member_string = "indirect";
    *out = ret;
  }
  LIB_EXPORT opaque_type_t create_opaque_noalloc(void) {
    return (opaque_type_t){
      .member_int = 61,
      .member_float = 5.2f,
      .member_string = "noalloc",
      .member_int_array_fixed = {9, 10, 11, 12, 13, 14, 15, 16},
      .member_int_array = NULL,
      .member_int_array_size = 0,
      .member_string_array = NULL,
      .member_string_array_size = 0,
    };
  }
  LIB_EXPORT bool opaque_take_nested(opaque_type_t a) {
    float diff = a.member_float - 5.4f;
    return a.member_int == 62
      && (diff > -.0001f && diff < .0001f)
      && strcmp(a.member_string, "noalloc") == 0;
      //&& a.member_int_array_fixed[7] == 47
      //&& a.member_int_array == NULL
      //&& a.member_string_array == NULL;
  }
</x>)
class TestDatatypesNative extends ammer.def.Sublibrary<def.Native> {
  public static function create_opaque():NativeOpaque;
  //@:ammer.native("create_opaque") public static function create_opaque2():NativeOpaque2;

  public static function opaque_indirect(_:ammer.ffi.Box<NativeOpaque>):Void;
  public static function create_opaque_noalloc():ammer.ffi.Alloc<NativeOpaque>;
  public static function opaque_take_nested(a:ammer.ffi.Deref<NativeOpaque>):Bool;
}

class TestDatatypes extends Test {
  function testOpaque() {
    var opaque = TestDatatypesNative.create_opaque();

    eq(opaque.get_int(), 1);
    feq(opaque.get_float(), 2.0);
    eq(opaque.get_string(), "3");
    eq(opaque.get_int_alt(3, 4), 8);
    /*
    var opaque = TestDatatypesNative.create_opaque2();
    eq(opaque.get_int(), 1);*/
  }

  function testVariables() {
    var opaque = TestDatatypesNative.create_opaque();
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
    //beq(opaque.get_bytes(), haxe.io.Bytes.ofHex("626172"));
  }

  function testAlloc() {
    var opaque = NativeOpaque.alloc();
    opaque.member_int = 7;
    eq(opaque.get_int(), 7);
    opaque.member_int = 49;
    eq(opaque.member_int, 49);
    opaque.free();
  }

  function testOutPointer() {
    var opaqueBox = ammer.Lib.allocBox(NativeOpaque);
    TestDatatypesNative.opaque_indirect(opaqueBox);
    var opaque = opaqueBox.get();
    eq(opaque.member_int, 10);
    feq(opaque.member_float, 4.0);
    eq(opaque.member_string, "indirect");
    opaque.free();
  }

  function testNested() {
    var opaque = TestDatatypesNative.create_opaque_noalloc();
    eq(opaque.get_int(), 61);
    feq(opaque.get_float(), 5.2);
    eq(opaque.get_string(), "noalloc");
    //for (i in 0...8) {
    //  eq(opaque.member_int_array_fixed[i], 9 + i);
    //}
    opaque.member_int = 62;
    eq(opaque.get_int_nested(), 62);
    opaque.member_float = 5.4;
    //opaque.member_int_array_fixed[7] = 47;
    eq(TestDatatypesNative.opaque_take_nested(opaque), true);
    opaque.free();
  }
  /*
  function testArray() {
    #if (hl || cpp)
    var opaque = TestDatatypesNative.create_opaque();
    var arr = opaque.member_int_array_fixed;
    eq(arr.length, 8);
    for (i in 0...8) {
      eq(arr[i], 0xB0057ED + i);
      arr[i] = 0xDE7500B + i;
    }
    for (i in 0...8) {
      eq(arr[i], 0xDE7500B + i);
    }
    var arr = opaque.member_int_array;
    eq(arr.length, 17);
    for (i in 0...17) {
      eq(arr[i], 0xB00573D + i);
    }
    var arr = opaque.member_string_array;
    eq(arr[0], "arrfoo");
    eq(arr[1], "arrbar");
    eq(arr[2], "arrbaz");
    #else
    noAssert();
    #end
  }*/
}
