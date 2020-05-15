package test;

class TestCallback extends Test {
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

    counterSet = false;
    Native.save_func(createClosure());
    eq(Native.call_func(), 3);
    eq(Native.call_func(), 3);
    eq(Native.call_func(), 3);
    eq(counterSet, true);

    wasCalled = false;
    eq(Native.call_func_3(data -> {
      eq(data.foo, 59);
      wasCalled = true;
      77;
    }), 77);
    eq(wasCalled, true);
    #else
    noAssert();
    #end
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
}
