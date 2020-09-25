package test;

class TestEnums extends Test {
  function testEnums() {
    eq(Native.take_enum(Native.NativeEnum.EConst10, Native.NativeEnum.EConst1, Native.NativeEnum.EConst0), true);
    eq(Native.give_enum(), Native.NativeEnum.EConst10);
  }
}
