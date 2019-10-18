package test;

class TestOpaque extends Test {
  function testOpaque() {
    #if hl
    var opaque = Native.create_opaque();
    eq(opaque.opaque_get_int(), 1);
    eq(opaque.opaque_get_float(), 2.0);
    eq(opaque.opaque_get_string(), "3");
    #else
    noAssert();
    #end
  }
}
