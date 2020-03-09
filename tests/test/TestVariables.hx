package test;

class TestVariables extends Test {
  function testDefines() {
    #if (hl || cpp || lua)
    eq(Native.define_int, 42);
    eq(Native.define_int_expr, 72);
    eq(Native.define_string, "foo");
    eq(Native.define_string_expr, "foobarfoo");
    eq(Native.define_bool, true);
    eq(Native.define_bool_expr, true);
    eq(Native.define_float, 5.3);
    eq(Native.define_float_expr, 10.6);
    #else
    noAssert();
    #end
  }
}
