package test;

class TestCallback extends Test {
  static var wasCalled = false;
  static var callA = -1;
  static var callB = -1;

  static function callback(a:Int, b:Int):Int {
    wasCalled = true;
    callA = a;
    callB = b;
    return a + b;
  }

  function testCallback() {
    #if (hl)
    Native.save_func(callback);
    eq(wasCalled, false);
    eq(Native.call_func(), 3);
    eq(wasCalled, true);
    #else
    noAssert();
    #end
  }
}
