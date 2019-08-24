package test;

class TestCpp extends Test {
  function testCppLinkage() {
    Templates.foobar();
    eq(1, 1);
  }
}
