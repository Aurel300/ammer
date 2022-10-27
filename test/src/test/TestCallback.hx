package test;

import ammer.ffi.Callback;
import ammer.ffi.Haxe;
import ammer.ffi.Int32;

@:build(ammer.def.Enum.build("enum enum_constants_cb", ammer.ffi.Int32, TestCallbackNative))
enum abstract NativeEnum2(Int) from Int to Int {
  @:ammer.native("e_const_cb0") var EConst0;
  @:ammer.native("e_const_cb1") var EConst1;
  @:ammer.native("e_const_cb10") var EConst10;
}

@:ammer.alloc
// TODO: this should be added automatically on cpp-static
@:headerCode('#include "/DevProjects/Repos/ammer/test/native-src/native.h"')
class NativeCallbackData extends ammer.def.Struct<"callback_data_t", TestCallbackNative> {
  public var user_data:Haxe<(NativeCallbackData)->Int>;
  public var foo:Int;
}

@:ammer.sub((_ : test.TestCallback.NativeCallbackData))
@:ammertest.code("native.h", <x>
  enum enum_constants_cb {
    e_const_cb0 = 0,
    e_const_cb1 = 1,
    e_const_cb10 = 10
  };

  typedef struct {
    void *user_data;
    int foo;
  } callback_data_t;
  LIB_EXPORT void save_func(int (* func)(int, int, void*), void *user_data);
  LIB_EXPORT int call_func(void);
  LIB_EXPORT int call_func_2(void *user_data, int (* func)(void *, const char *));
  LIB_EXPORT int call_func_3(void *user_data, int (* func)(callback_data_t *));
  LIB_EXPORT bool call_func_4(void *user_data, enum enum_constants_cb (* func)(void *, enum enum_constants_cb));

  LIB_EXPORT void save_static_func(const char* (* func)(int, const char*));
  LIB_EXPORT const char* call_static_func(int, const char*);
</x>)
@:ammertest.code("native.c", <x>
  static int (* cached_func)(int, int, void *);
  static void *cached_user_data;
  LIB_EXPORT void save_func(int (* func)(int, int, void *), void *user_data) {
    cached_func = func;
    cached_user_data = user_data;
  }
  LIB_EXPORT int call_func(void) {
    return cached_func(1, 2, cached_user_data);
  }
  LIB_EXPORT int call_func_2(void *user_data, int (* func)(void *, const char *)) {
    return func(user_data, "foobar") * 2;
  }
  static callback_data_t call_func_3_data;
  LIB_EXPORT int call_func_3(void *user_data, int (* func)(callback_data_t *)) {
    call_func_3_data.user_data = user_data;
    call_func_3_data.foo = 59;
    return func(&call_func_3_data);
  }
  LIB_EXPORT bool call_func_4(void *user_data, enum enum_constants_cb (* func)(void *, enum enum_constants_cb)) {
    return func(user_data, e_const_cb1) == e_const_cb10;
  }

  static const char* (* cached_static_func)(int, const char*);
  LIB_EXPORT void save_static_func(const char* (* func)(int, const char*)) {
    cached_static_func = func;
  }
  LIB_EXPORT const char* call_static_func(int a, const char* b) {
    return cached_static_func(a, b);
  }
</x>)
class TestCallbackNative extends ammer.def.Sublibrary<def.Native> {
  public static function save_func(
    _:ammer.ffi.Callback<
      (Int32, Int32, Haxe<(Int, Int)->Int>)->Int32,
      (Int, Int)->Int,
      [arg2],
      [arg0, arg1],
      TestCallbackNative
    >,
    _:Haxe<(Int, Int)->Int>
  ):Void;
  public static function call_func():Int;
  public static function call_func_2(
    _:Haxe<(String)->Int>,
    _:Callback<
      (Haxe<(String)->Int>, String)->Int32,
      (String)->Int32,
      [arg0],
      [arg1],
      TestCallbackNative
    >
  ):Int32;
  public static function call_func_3(
    _:Haxe<(NativeCallbackData)->Int>,
    _:Callback<
      (NativeCallbackData)->Int32,
      (NativeCallbackData)->Int32,
      [arg0.user_data],
      [arg0],
      TestCallbackNative
    >
  ):Int32;
  public static function call_func_4(
    _:Haxe<(NativeEnum2)->NativeEnum2>,
    _:Callback<
      (Haxe<(NativeEnum2)->NativeEnum2>, NativeEnum2)->NativeEnum2,
      (NativeEnum2)->NativeEnum2,
      [arg0],
      [arg1],
      TestCallbackNative
    >
  ):Bool;

  public static function save_static_func(
    _:Callback<
      (Int32, ammer.ffi.String) -> ammer.ffi.String,
      (Int, String) -> String,
      "global",
      [arg0, arg1],
      TestCallbackNative
    >
  ):Void;
  public static function call_static_func(a:Int, b:String):String;
}

class TestCallback extends Test implements ammer.Syntax {
  var wasCalled = false;
  var counterSet = false;
  var callA = -1;
  var callB = -1;

  function callback(a:Int, b:Int):Int {
    wasCalled = true;
    callA = a;
    callB = b;
    return a + b;
  }

  function createClosure():((Int, Int)->Int) {
    var counter = 0;
    return ((a, b) -> {
      counter++;
      if (counter >= 3)
        counterSet = true;
      return a + b;
    });
  }

  function testCallback() {
    wasCalled = false;
    var clRef = ammer.Lib.createHaxeRef((_ : (Int, Int)->Int), callback);
    clRef.incref();
    TestCallbackNative.save_func(clRef);
    eq(wasCalled, false);
    eq(TestCallbackNative.call_func(), 3);
    clRef.decref();
    eq(wasCalled, true);
    eq(callA, 1);
    eq(callB, 2);

    var clRef = ammer.Lib.createHaxeRef((_ : (Int, Int)->Int), (a:Int, b:Int) -> {
      wasCalled = true;
      callA = a;
      callB = b;
      a + b;
    });
    wasCalled = false;
    clRef.incref();
    TestCallbackNative.save_func(clRef);
    eq(wasCalled, false);
    eq(TestCallbackNative.call_func(), 3);
    clRef.decref();
    eq(wasCalled, true);
    eq(callA, 1);
    eq(callB, 2);

    wasCalled = false;
    var clRef = ammer.Lib.createHaxeRef((_ : (String)->Int), (x:String) -> {
      wasCalled = true;
      eq(x, "foobar");
      2;
    });
    clRef.incref();
    eq(TestCallbackNative.call_func_2(clRef), 4);
    clRef.decref();
    eq(wasCalled, true);

    counterSet = false;
    var clRef2 = ammer.Lib.createHaxeRef((_ : (Int, Int)->Int), createClosure());
    clRef2.incref();
    TestCallbackNative.save_func(clRef2);
    eq(TestCallbackNative.call_func(), 3);
    eq(TestCallbackNative.call_func(), 3);
    eq(TestCallbackNative.call_func(), 3);
    clRef2.decref();
    eq(counterSet, true);

    wasCalled = false;
    var clRef = ammer.Lib.createHaxeRef((_ : NativeCallbackData -> Int), (data:NativeCallbackData) -> {
      eq(data.foo, 59);
      wasCalled = true;
      77;
    });
    clRef.incref();
    eq(TestCallbackNative.call_func_3(clRef), 77);
    clRef.decref();
    eq(wasCalled, true);

    wasCalled = false;
    var clRef = ammer.Lib.createHaxeRef((_ : NativeEnum2 -> NativeEnum2), (data:NativeEnum2) -> {
      eq(data, NativeEnum2.EConst1);
      wasCalled = true;
      NativeEnum2.EConst10;
    });
    clRef.incref();
    TestCallbackNative.call_func_4(clRef);
    clRef.decref();
    eq(wasCalled, true);
  }

  static function staticCallback(a:Int, b:String):String {
    return '$a$b';
  }

  function testStaticCallback():Void {
    TestCallbackNative.save_static_func(staticCallback);
    eq(TestCallbackNative.call_static_func(2, "foo"), "2foo");
  }
}
