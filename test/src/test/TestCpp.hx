package test;

@:ammer.sub((_ : XTemplatesStruct))
@:ammertest.code("templates.hpp", <x>
  template<typename int_t = uint32_t>
  LIB_EXPORT int_t templated_add_ints(int_t a, int_t b);

  LIB_EXPORT void cpp_nop(void);

  struct TemplatesStruct {
    uint32_t member_int;
  public:
    TemplatesStruct() : member_int(5) {}
    uint32_t add(uint32_t x);
  };
</x>)
@:ammertest.code("templates.cpp", <x>
  template<typename int_t>
  LIB_EXPORT int_t templated_add_ints(int_t a, int_t b) {
    return a + b;
  }

  template LIB_EXPORT int templated_add_ints(int a, int b);
  template LIB_EXPORT uint64_t templated_add_ints(uint64_t a, uint64_t b);

  LIB_EXPORT void cpp_nop(void) {}

  uint32_t TemplatesStruct::add(uint32_t x) {
    return this->member_int + x;
  }
</x>)
class TestCppNative extends ammer.def.Sublibrary<def.Templates> {
  @:ammer.native("templated_add_ints") public static function templated_add_ints32(a:Int, b:Int):Int;
  public static function cpp_nop():Void;
}

@:ammer.alloc
class XTemplatesStruct extends ammer.def.Struct<"TemplatesStruct", def.Templates> {
  public var member_int:UInt32;

  // @:ammer.native("TemplatesStruct")
  // @:ammer.cpp.constructor
  // public static function new_():XTemplatesStruct;

  // @:ammer.cpp.member
  // public function add(x:UInt32):UInt32;
}

class TestCpp extends Test {
  function testTemplates() {
    eq(TestCppNative.templated_add_ints32(0, 0), 0);
    eq(TestCppNative.templated_add_ints32(1, 2), 3);
    eq(TestCppNative.templated_add_ints32(-1, 1), 0);
    eq(TestCppNative.templated_add_ints32(0xFFFFFFFF, 1), 0);
    eq(TestCppNative.templated_add_ints32(0x7F000000, 0xFFFFFF), 0x7FFFFFFF);
    eq(TestCppNative.templated_add_ints32(-0x7FFFFFFF, 0x7FFFFFFF), 0);
  }

  function testCppLinkage() {
    TestCppNative.cpp_nop();
    eq(1, 1);
  }
  /*
  function testStructMembers() {
    var obj = XTemplatesStruct.new_();
    eq(obj.member_int, 5);
    obj.member_int = 7;
    eq(obj.member_int, 7);
    eq(obj.add(13), 20);
  }*/
}
