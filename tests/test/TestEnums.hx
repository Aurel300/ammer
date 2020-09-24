package test;

class TestEnums extends Test {
  function testEnums() {
    #if (hl || cpp)
    eq(Native.take_enum(Native.NativeEnum.EConst10, Native.NativeEnum.EConst1, Native.NativeEnum.EConst0), true);
    eq(Native.give_enum(), Native.NativeEnum.EConst10);
    #else
    noAssert();
    #end
  }
}
