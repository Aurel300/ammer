package test;

@:build(ammer.def.Enum.build("enum enum_constants", ammer.ffi.Int32, def.Native))
enum abstract NativeEnum(Int) from Int to Int {
  @:ammer.native("e_const0") var EConst0;
  @:ammer.native("e_const1") var EConst1;
  @:ammer.native("e_const10") var EConst10;
}

@:ammertest.code("native.h", <x>
  enum enum_constants {
    e_const0 = 0,
    e_const1 = 1,
    e_const10 = 10
  };

  //enum enum_flags {
  //  e_foo = 1,
  //  e_bar = 2,
  //  e_baz = 4
  //};

  LIB_EXPORT bool take_enum(enum enum_constants a, enum enum_constants b, enum enum_constants c);
  LIB_EXPORT enum enum_constants give_enum(void);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT bool take_enum(enum enum_constants a, enum enum_constants b, enum enum_constants c) {
    return (a == e_const10)
      && (b == e_const1)
      && (c == e_const0);
  }
  LIB_EXPORT enum enum_constants give_enum(void) {
    return e_const10;
  }
</x>)
class TestEnumsNative extends ammer.def.Sublibrary<def.Native> {
  public static function take_enum(a:NativeEnum, b:NativeEnum, c:NativeEnum):Bool;
  public static function give_enum():NativeEnum;
}

class TestEnums extends Test {
  function testEnums() {
    eq(TestEnumsNative.take_enum(NativeEnum.EConst10, NativeEnum.EConst1, NativeEnum.EConst0), true);
    eq(TestEnumsNative.give_enum(), NativeEnum.EConst10);
  }
}
