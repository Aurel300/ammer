package test;

import utest.Assert;
import utest.Async;
import haxe.io.Bytes;

// some methods from Test class in Haxe unit test sources
class Test implements utest.ITest {
  public function new() {}

  function eq<T>(v:T, v2:T, ?pos:haxe.PosInfos) {
    Assert.equals(v, v2, pos);
  }

  function feq(v:Float, v2:Float, ?pos:haxe.PosInfos) {
    Assert.floatEquals(v, v2, pos);
  }

  function aeq<T>(expected:Array<T>, actual:Array<T>, ?pos:haxe.PosInfos) {
    Assert.same(expected, actual, pos);
  }

  function beq(a:Bytes, b:Bytes, ?pos:haxe.PosInfos) {
    Assert.isTrue(a.compare(b) == 0, pos);
  }

  function t(v:Bool, ?pos:haxe.PosInfos) {
    Assert.isTrue(v, pos);
  }

  function f(v:Bool, ?pos:haxe.PosInfos) {
    Assert.isFalse(v, pos);
  }

  function noAssert(?pos:haxe.PosInfos) {
    t(true, pos);
  }
}
