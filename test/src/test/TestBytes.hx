package test;

import haxe.io.Bytes as HB;
import ammer.ffi.Bytes as AB;

@:ammertest.code("native.h", <x>
  LIB_EXPORT unsigned char *ident_bytes(unsigned char *a, size_t b);
  LIB_EXPORT unsigned char *give_bytes(size_t len);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT unsigned char *ident_bytes(unsigned char *a, size_t b) {
    return memcpy(malloc(b), a, b);
  }
  LIB_EXPORT unsigned char *give_bytes(size_t len) {
    unsigned char *ret = malloc(len);
    for (size_t i = 0; i < len; i++) {
      ret[i] = i + 1;
    }
    return ret;
  }
</x>)
class TestBytesNative extends ammer.def.Sublibrary<def.Native> {
  public static function ident_bytes(_:AB, _:Int):AB;

  @:ammer.native("ident_bytes") public static function ident_bytes_1(
    @:ammer.skip _:HB,
    @:ammer.derive(ammer.ffi.Bytes.fromHaxeCopy(arg0)) _:AB,
    @:ammer.derive(arg0.length) _:Int
  ):AB;

  @:ammer.ret.derive(ret.toHaxeCopy(arg1), (_ : HB))
  @:ammer.native("ident_bytes") public static function ident_bytes_2(
    _:AB,
    _:Int
  ):AB;

  @:ammer.ret.derive(ret.toHaxeCopy(arg0.length), (_ : HB))
  @:ammer.native("ident_bytes") public static function ident_bytes_3(
    @:ammer.skip _:HB,
    @:ammer.derive(AB.fromHaxeCopy(arg0)) _:AB,
    @:ammer.derive(arg0.length) _:Int
  ):AB;

  @:ammer.ret.derive(ret.toHaxeCopy(arg0), (_ : HB))
  public static function give_bytes(len:Int):AB;
}

class TestBytes extends Test {
  function testIdent() {
    beq(TestBytesNative.ident_bytes(AB.fromHaxeCopy(HB.ofHex("")), 0).toHaxeCopy(0), HB.ofHex(""));
    beq(TestBytesNative.ident_bytes(AB.fromHaxeCopy(HB.ofHex("00")), 1).toHaxeCopy(1), HB.ofHex("00"));

    var b = HB.ofHex("0001FEFF");
    var c = HB.ofHex("AA01FEFF");
    beq(TestBytesNative.ident_bytes_1(b).toHaxeCopy(4), b);
    beq(TestBytesNative.ident_bytes_2(AB.fromHaxeCopy(b), 4), b);
    beq(TestBytesNative.ident_bytes_3(b), b);
  }

  function testReturns() {
    beq(TestBytesNative.give_bytes(0), HB.ofHex(""));
    beq(TestBytesNative.give_bytes(1), HB.ofHex("01"));
    beq(TestBytesNative.give_bytes(10), HB.ofHex("0102030405060708090A"));
  }
}
