package test;

class TestMaths extends Test {
  function testInts() {
    eq(Native.add_ints(0, 0), 0);
    eq(Native.add_ints(1, 2), 3);
    eq(Native.add_ints(-1, 1), 0);
    eq(Native.add_ints(0xFFFFFFFF, 1), 0);
    eq(Native.add_ints(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    eq(Native.add_ints(-0x7FFFFFFF, 0x7FFFFFFF), 0);
  }

  function testUInts() {
    eq(Native.add_uints(0, 0), 0);
    eq(Native.add_uints(1, 2), 3);
    eq(Native.add_uints(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    eq(Native.add_uints(0x7FFFFFFF, 0x7FFFFFFF), 0xFFFFFFFE);
  }

  #if !lua
  function testSingles() {
    eq(Native.add_singles(0., 0.), (0.:Single));
    feq(Native.add_singles(1., 2.), (3.:Single));
    feq(Native.add_singles(-1., 1.), (0.:Single));
    feq(Native.add_singles(-1e10, 1e10), (0.:Single));
    feq(Native.add_singles(-1e10, 1e9), (-9e9:Single));
  }
  #end
  
  function testFloats() {
    eq(Native.add_floats(0., 0.), 0.);
    feq(Native.add_floats(1., 2.), 3.);
    feq(Native.add_floats(-1., 1.), 0.);
    feq(Native.add_floats(-1e10, 1e10), 0.);
    feq(Native.add_floats(-1e10, 1e9), -9e9);
  }

  function testBools() {
    eq(Native.logic_and(false, false), false);
    eq(Native.logic_and(true, false), false);
    eq(Native.logic_and(false, true), false);
    eq(Native.logic_and(true, true), true);
    eq(Native.logic_or(false, false), false);
    eq(Native.logic_or(true, false), true);
    eq(Native.logic_or(false, true), true);
    eq(Native.logic_or(true, true), true);
    eq(Native.logic_ternary(true, 3, 5), 3);
    eq(Native.logic_ternary(false, 3, 5), 5);
  }

  function testBitWidths() {
    eq(Native.add_u8(142, 193), 79);
    eq(Native.add_u16(25679, 49565), 9708);
    eq(Native.add_u32(0xBF86404F, 0xBF863D5D), 0x7F0C7DAC);
    #if cpp
    var a = haxe.Int64.make(0xBBFBCDC4, 0x2397F34F);
    var b = haxe.Int64.make(0x5ADF2061, 0x3E99B3E1);
    var c = haxe.Int64.make(0x16DAEE25, 0x6231A730);
    eq(Native.add_u64(a, b), c);
    #end
  }
}
