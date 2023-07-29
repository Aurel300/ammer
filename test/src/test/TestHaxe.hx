package test;

@:ammertest.code("native.h", <x>
  LIB_EXPORT int func_under_haxe(int a, int b);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT int func_under_haxe(int a, int b) {
    return a + b;
  }
</x>)
class TestHaxeNative extends ammer.def.Sublibrary<def.Native> {
  private static function func_under_haxe(a:Int, b:Int):Int;
  @:ammer.haxe public static function func(a:Int, b:Int):Int {
    return 42 + func_under_haxe(a, b);
  }
}

class TestHaxe extends Test {
  function testHaxe() {
    eq(TestHaxeNative.func(1, 2), 45);
  }
}
