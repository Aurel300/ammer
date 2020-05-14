package test;

class TestCallback extends Test {
  var wasCalled = false;
  var callA = -1;
  var callB = -1;

  function callback(a:Int, b:Int):Int {
    wasCalled = true;
    callA = a;
    callB = b;
    return a + b;
  }

  function testCallback() {
    #if (hl || cpp)
    wasCalled = false;
    Native.save_func(callback);
    eq(wasCalled, false);
    eq(Native.call_func(), 3);
    eq(wasCalled, true);
    eq(callA, 1);
    eq(callB, 2);
    wasCalled = false;
    eq(Native.call_func_2(x -> {
      wasCalled = true;
      eq(x, "foobar");
      2;
    }), 4);
    eq(wasCalled, true);
    #else
    noAssert();
    #end
  }
}
