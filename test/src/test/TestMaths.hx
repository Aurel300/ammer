package test;

import ammer.ffi.Int8;
import ammer.ffi.Int16;
import ammer.ffi.Int32;
import ammer.ffi.Int64;
import ammer.ffi.UInt8;
import ammer.ffi.UInt16;
import ammer.ffi.UInt32;
import ammer.ffi.UInt64;

@:ammertest.code("native.h", <x>
  LIB_EXPORT int add_ints(int a, int b);
  LIB_EXPORT unsigned int add_uints(unsigned int a, unsigned int b);
  LIB_EXPORT float add_singles(float a, float b);
  LIB_EXPORT double add_floats(double a, double b);
  LIB_EXPORT bool logic_and(bool a, bool b);
  LIB_EXPORT bool logic_or(bool a, bool b);
  LIB_EXPORT int logic_ternary(bool a, int b, int c);

  LIB_EXPORT int8_t add_i8(int8_t a, int8_t b);
  LIB_EXPORT int16_t add_i16(int16_t a, int16_t b);
  LIB_EXPORT int32_t add_i32(int32_t a, int32_t b);
  LIB_EXPORT int64_t add_i64(int64_t a, int64_t b);
  LIB_EXPORT uint8_t add_u8(uint8_t a, uint8_t b);
  LIB_EXPORT uint16_t add_u16(uint16_t a, uint16_t b);
  LIB_EXPORT uint32_t add_u32(uint32_t a, uint32_t b);
  LIB_EXPORT uint64_t add_u64(uint64_t a, uint64_t b);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT int add_ints(int a, int b) {
    return a + b;
  }
  LIB_EXPORT unsigned int add_uints(unsigned int a, unsigned int b) {
    return a + b;
  }
  LIB_EXPORT float add_singles(float a, float b) {
    return a + b;
  }
  LIB_EXPORT double add_floats(double a, double b) {
    return a + b;
  }
  LIB_EXPORT bool logic_and(bool a, bool b) {
    return a && b;
  }
  LIB_EXPORT bool logic_or(bool a, bool b) {
    return a || b;
  }
  LIB_EXPORT int logic_ternary(bool a, int b, int c) {
    return a ? b : c;
  }

  LIB_EXPORT int8_t add_i8(int8_t a, int8_t b) {
    return a + b;
  }
  LIB_EXPORT int16_t add_i16(int16_t a, int16_t b) {
    return a + b;
  }
  LIB_EXPORT int32_t add_i32(int32_t a, int32_t b) {
    return a + b;
  }
  LIB_EXPORT int64_t add_i64(int64_t a, int64_t b) {
    return a + b;
  }
  LIB_EXPORT uint8_t add_u8(uint8_t a, uint8_t b) {
    return a + b;
  }
  LIB_EXPORT uint16_t add_u16(uint16_t a, uint16_t b) {
    return a + b;
  }
  LIB_EXPORT uint32_t add_u32(uint32_t a, uint32_t b) {
    return a + b;
  }
  LIB_EXPORT uint64_t add_u64(uint64_t a, uint64_t b) {
    return a + b;
  }
</x>)
class TestMathsNative extends ammer.def.Sublibrary<def.Native> {
  public static function add_ints(_:Int, _:Int):Int;
  public static function add_uints(_:UInt, _:UInt):UInt;
  #if !(lua || neko || js || python)
  public static function add_singles(_:Single, _:Single):Single;
  #end
  public static function add_floats(_:Float, _:Float):Float;
  public static function logic_and(_:Bool, _:Bool):Bool;
  public static function logic_or(_:Bool, _:Bool):Bool;
  public static function logic_ternary(_:Bool, _:Int, _:Int):Int;

  public static function add_i8(_:Int8, _:Int8):Int8;
  public static function add_i16(_:Int16, _:Int16):Int16;
  public static function add_i32(_:Int32, _:Int32):Int32;
  public static function add_i64(_:Int64, _:Int64):Int64;
  public static function add_u8(_:UInt8, _:UInt8):UInt8;
  public static function add_u16(_:UInt16, _:UInt16):UInt16;
  public static function add_u32(_:UInt32, _:UInt32):UInt32;
  public static function add_u64(_:UInt64, _:UInt64):UInt64;
}

class TestMaths extends Test {
  function testInts() {
    eq(TestMathsNative.add_ints(0, 0), 0);
    eq(TestMathsNative.add_ints(1, 2), 3);
    eq(TestMathsNative.add_ints(-1, 1), 0);
    eq(TestMathsNative.add_ints(0xFFFFFFFF, 1), 0);
    eq(TestMathsNative.add_ints(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    eq(TestMathsNative.add_ints(-0x7FFFFFFF, 0x7FFFFFFF), 0);
  }

  function testUInts() {
    eq(TestMathsNative.add_uints(0, 0), 0);
    eq(TestMathsNative.add_uints(1, 2), 3);
    eq(TestMathsNative.add_uints(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    // RHS is 0xFFFFFFFE but Haxe compiles the literal to -2
    eq(TestMathsNative.add_uints(0x7FFFFFFF, 0x7FFFFFFF), ((0x7FFFFFFF + 0x7FFFFFFF): UInt));
  }

  #if !(lua || neko || js || python)
  function testSingles() {
    eq(TestMathsNative.add_singles(0., 0.), (0.:Single));
    feq(TestMathsNative.add_singles(1., 2.), (3.:Single));
    feq(TestMathsNative.add_singles(-1., 1.), (0.:Single));
    feq(TestMathsNative.add_singles(-1e10, 1e10), (0.:Single));
    feq(TestMathsNative.add_singles(-1e10, 1e9), (-9e9:Single));
  }
  #end

  function testFloats() {
    eq(TestMathsNative.add_floats(0., 0.), 0.);
    feq(TestMathsNative.add_floats(1., 2.), 3.);
    feq(TestMathsNative.add_floats(-1., 1.), 0.);
    feq(TestMathsNative.add_floats(-1e10, 1e10), 0.);
    feq(TestMathsNative.add_floats(-1e10, 1e9), -9e9);
  }

  function testBools() {
    eq(TestMathsNative.logic_and(false, false), false);
    eq(TestMathsNative.logic_and(true, false), false);
    eq(TestMathsNative.logic_and(false, true), false);
    eq(TestMathsNative.logic_and(true, true), true);
    eq(TestMathsNative.logic_or(false, false), false);
    eq(TestMathsNative.logic_or(true, false), true);
    eq(TestMathsNative.logic_or(false, true), true);
    eq(TestMathsNative.logic_or(true, true), true);
    eq(TestMathsNative.logic_ternary(true, 3, 5), 3);
    eq(TestMathsNative.logic_ternary(false, 3, 5), 5);
  }

  function testBitWidths() {
    eq(TestMathsNative.add_u8(142, 193), 79);
    eq(TestMathsNative.add_u16(25679, 49565), 9708);
    eq(TestMathsNative.add_u32(0xBF86404F, 0xBF863D5D), 0x7F0C7DAC);
    var a = haxe.Int64.make(0xBBFBCDC4, 0x2397F34F);
    var b = haxe.Int64.make(0x5ADF2061, 0x3E99B3E1);
    var c = haxe.Int64.make(0x16DAEE25, 0x6231A730);
    t(TestMathsNative.add_u64(a, b) == c); // see #10760
  }
}
