package test;

class TestSignature extends Test {
  function testArgCount() {
    eq(Native.take_0(), 0);
    eq(Native.take_1(1), 1);
    eq(Native.take_2(1, 2), 2);
    eq(Native.take_3(1, 2, 3), 3);
    eq(Native.take_4(1, 2, 3, 4), 4);
    eq(Native.take_5(1, 2, 3, 4, 5), 5);
    eq(Native.take_6(1, 2, 3, 4, 5, 6), 6);
    eq(Native.take_7(1, 2, 3, 4, 5, 6, 7), 7);
    eq(Native.take_8(1, 2, 3, 4, 5, 6, 7, 8), 8);
    eq(Native.take_9(1, 2, 3, 4, 5, 6, 7, 8, 9), 9);
    eq(Native.take_10(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 10);
  }

  function testVoid() {
    Native.nop();
    noAssert();
  }

  function testMultipleClasses() {
    eq(Native.Native2.take_0(), 0);
    eq(Native.Native2.take_0alt(), 0);
  }
}
