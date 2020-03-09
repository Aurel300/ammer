package test;

class TestCInjection extends Test {
  function testInjection() {
    #if (hl || lua)
    eq(Native.get_saved_num(), 5);
    eq(Native.pointer_saved_num(), 11);
    #else
    noAssert();
    #end
  }
}
