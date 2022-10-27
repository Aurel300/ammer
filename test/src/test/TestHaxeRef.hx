package test;

import ammer.ffi.Haxe;

@:structInit
class HaxeType {
  public var val:Array<Int>;
}

@:ammertest.code("native.h", <x>
  LIB_EXPORT void save_haxe(void* a);
  LIB_EXPORT void *load_haxe(void);
</x>)
@:ammertest.code("native.c", <x>
  static void *saved_haxe = 0;
  LIB_EXPORT void save_haxe(void* a) {
    saved_haxe = a;
  }
  LIB_EXPORT void *load_haxe(void) {
    return saved_haxe;
  }
</x>)
@:ammer.sub((_ : ammer.ffi.Haxe<HaxeType>))
class TestHaxeRefNative extends ammer.def.Sublibrary<def.Native> {
  public static function save_haxe(_:Haxe<HaxeType>):Void;
  public static function load_haxe():Haxe<HaxeType>;
}

class TestHaxeRef extends Test {
  function testHaxe() {
    function nested() {
      TestHaxeRefNative.save_haxe(ammer.Lib.createHaxeRef(HaxeType, ({
        val: [1, 2, 3],
      } : HaxeType)));
    }
    nested();
    aeq(TestHaxeRefNative.load_haxe().value.val, [1, 2, 3]);
  }
}
