package test;

import haxe.io.Bytes;

// some methods from Test class in Haxe unit test sources
@:autoBuild(NativeGen.deleteFields())
class Test {
  public function new() {}
  function eq<T>(v:T, v2:T, ?pos:haxe.PosInfos) {}
  function feq(v:Float, v2:Float, ?pos:haxe.PosInfos) {}
  function aeq<T>(expected:Array<T>, actual:Array<T>, ?pos:haxe.PosInfos) {}
  function beq(a:Bytes, b:Bytes, ?pos:haxe.PosInfos) {}
  function t(v:Bool, ?pos:haxe.PosInfos) {}
  function f(v:Bool, ?pos:haxe.PosInfos) {}
  function noAssert(?pos:haxe.PosInfos) {}
}
