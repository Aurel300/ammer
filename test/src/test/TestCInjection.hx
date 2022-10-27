package test;

@:ammertest.code("native.h", <x>
  LIB_EXPORT void save_num(int);
  LIB_EXPORT int get_saved_num(void);
  LIB_EXPORT int *pointer_saved_num(void);
</x>)
@:ammertest.code("native.c", <x>
  static int saved_num = 0;
  LIB_EXPORT void save_num(int num) {
    saved_num = num;
  }
  LIB_EXPORT int get_saved_num(void) {
    return saved_num;
  }
  LIB_EXPORT int *pointer_saved_num(void) {
    return &saved_num;
  }
</x>)
class TestCInjectionNative extends ammer.def.Sublibrary<def.Native> {
  @:ammer.c.prereturn("save_num(5);")
  public static function get_saved_num():Int;

  @:ammer.c.prereturn("save_num(11);")
  @:ammer.c.return("*(%CALL%)")
  public static function pointer_saved_num():Int;
}

class TestCInjection extends Test {
  function testInjection() {
    eq(TestCInjectionNative.get_saved_num(), 5);
    eq(TestCInjectionNative.pointer_saved_num(), 11);
  }
}
