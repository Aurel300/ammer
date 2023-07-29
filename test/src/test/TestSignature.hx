package test;

import ammer.ffi.Unsupported;

@:ammer.sub((_ : test.TestSignature.TestSignatureNative2))
@:ammer.sub((_ : test.TestSignature.TestSignatureNative3))
@:ammertest.code("native.h", <x>
  LIB_EXPORT int take_0(void);
  LIB_EXPORT int take_1(int a1);
  LIB_EXPORT int take_2(int a1, int a2);
  LIB_EXPORT int take_3(int a1, int a2, int a3);
  LIB_EXPORT int take_4(int a1, int a2, int a3, int a4);
  LIB_EXPORT int take_5(int a1, int a2, int a3, int a4, int a5);
  LIB_EXPORT int take_6(int a1, int a2, int a3, int a4, int a5, int a6);
  LIB_EXPORT int take_7(int a1, int a2, int a3, int a4, int a5, int a6, int a7);
  LIB_EXPORT int take_8(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8);
  LIB_EXPORT int take_9(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9);
  LIB_EXPORT int take_10(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9, int a10);
  LIB_EXPORT void nop(void);
  LIB_EXPORT bool take_unsupported(void *a, double b);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT int take_0(void) {
    return 0;
  }
  LIB_EXPORT int take_1(int a1) {
    return 1;
  }
  LIB_EXPORT int take_2(int a1, int a2) {
    return 2;
  }
  LIB_EXPORT int take_3(int a1, int a2, int a3) {
    return 3;
  }
  LIB_EXPORT int take_4(int a1, int a2, int a3, int a4) {
    return 4;
  }
  LIB_EXPORT int take_5(int a1, int a2, int a3, int a4, int a5) {
    return 5;
  }
  LIB_EXPORT int take_6(int a1, int a2, int a3, int a4, int a5, int a6) {
    return 6;
  }
  LIB_EXPORT int take_7(int a1, int a2, int a3, int a4, int a5, int a6, int a7) {
    return 7;
  }
  LIB_EXPORT int take_8(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8) {
    return 8;
  }
  LIB_EXPORT int take_9(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9) {
    return 9;
  }
  LIB_EXPORT int take_10(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9, int a10) {
    return 10;
  }
  LIB_EXPORT void nop(void) {}
  LIB_EXPORT bool take_unsupported(void *a, double b) {
    return a == 0 && abs(b) < .0001;
  }
</x>)
class TestSignatureNative extends ammer.def.Sublibrary<def.Native> {
  public static function take_0():Int;
  public static function take_1(_:Int):Int;
  public static function take_2(_:Int, _:Int):Int;
  public static function take_3(_:Int, _:Int, _:Int):Int;
  public static function take_4(_:Int, _:Int, _:Int, _:Int):Int;
  public static function take_5(_:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_6(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_7(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_8(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_9(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_10(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function nop():Void;
  public static function take_unsupported(_:Unsupported<"(void *)0">, _:Unsupported<"(double)0">):Bool;
}

@:ammertest.code("native.h", <x>
  LIB_EXPORT int take_0alt(void);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT int take_0alt(void) {
    return 0;
  }
</x>)
class TestSignatureNative2 extends ammer.def.Sublibrary<def.Native> {
  public static function take_0():Int;
  public static function take_0alt():Int;
}

@:ammer.nativePrefix("prefixed_")
@:ammertest.code("native.h", <x>
  LIB_EXPORT void prefixed_nop2(void);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT void prefixed_nop2(void) {}
</x>)
class TestSignatureNative3 extends ammer.def.Sublibrary<def.Native> {
  public static function nop2():Void;
  @:ammer.native("take_0") public static function take_0():Int;
}

class TestSignature extends Test {
  function testArgCount() {
    eq(TestSignatureNative.take_0(), 0);
    eq(TestSignatureNative.take_1(1), 1);
    eq(TestSignatureNative.take_2(1, 2), 2);
    eq(TestSignatureNative.take_3(1, 2, 3), 3);
    eq(TestSignatureNative.take_4(1, 2, 3, 4), 4);
    eq(TestSignatureNative.take_5(1, 2, 3, 4, 5), 5);
    eq(TestSignatureNative.take_6(1, 2, 3, 4, 5, 6), 6);
    eq(TestSignatureNative.take_7(1, 2, 3, 4, 5, 6, 7), 7);
    eq(TestSignatureNative.take_8(1, 2, 3, 4, 5, 6, 7, 8), 8);
    eq(TestSignatureNative.take_9(1, 2, 3, 4, 5, 6, 7, 8, 9), 9);
    eq(TestSignatureNative.take_10(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 10);
  }

  function testVoid() {
    TestSignatureNative.nop();
    noAssert();
  }

  function testMultipleClasses() {
    eq(TestSignatureNative2.take_0(), 0);
    eq(TestSignatureNative2.take_0alt(), 0);
  }

  function testPrefix() {
    TestSignatureNative3.nop2();
    eq(TestSignatureNative3.take_0(), 0);
  }

  function testUnsupported() {
    t(TestSignatureNative.take_unsupported());
  }
}
