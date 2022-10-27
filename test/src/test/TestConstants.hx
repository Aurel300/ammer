package test;

@:ammertest.code("native.h", <x>
  #define DEFINE_INT 42
  #define DEFINE_INT_EXPR (8 * 9)
  #define DEFINE_STRING "foo"
  #define DEFINE_STRING_EXPR ("foo" "bar" "foo")
  #define DEFINE_BOOL 1
  #define DEFINE_BOOL_EXPR ((1 == 1) ? 1 : 0)
  #define DEFINE_FLOAT 5.3
  #define DEFINE_FLOAT_EXPR (5.3 * 2)
</x>)
class TestConstantsNative extends ammer.def.Sublibrary<def.Native> {
  @:ammer.native("DEFINE_INT") public static final define_int:Int;
  @:ammer.native("DEFINE_INT_EXPR") public static final define_int_expr:Int;
  @:ammer.native("DEFINE_STRING") public static final define_string:String;
  @:ammer.native("DEFINE_STRING_EXPR") public static final define_string_expr:String;
  @:ammer.native("DEFINE_BOOL") public static final define_bool:Bool;
  @:ammer.native("DEFINE_BOOL_EXPR") public static final define_bool_expr:Bool;
  @:ammer.native("DEFINE_FLOAT") public static final define_float:Float;
  @:ammer.native("DEFINE_FLOAT_EXPR") public static final define_float_expr:Float;

  // TODO: test globals (public static var)
  // TODO: add read-only/write-only meta
}

class TestConstants extends Test {
  function testDefines() {
    eq(TestConstantsNative.define_int, 42);
    eq(TestConstantsNative.define_int_expr, 72);
    eq(TestConstantsNative.define_string, "foo");
    eq(TestConstantsNative.define_string_expr, "foobarfoo");
    eq(TestConstantsNative.define_bool, true);
    eq(TestConstantsNative.define_bool_expr, true);
    feq(TestConstantsNative.define_float, 5.3);
    feq(TestConstantsNative.define_float_expr, 10.6);
  }
}
