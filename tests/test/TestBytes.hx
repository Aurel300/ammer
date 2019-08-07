package test;

import haxe.io.Bytes;

class TestBytes extends Test {
  function testId() {
    beq(Native.id_bytes(Bytes.ofHex("")), Bytes.ofHex(""));
    beq(Native.id_bytes(Bytes.ofHex("00")), Bytes.ofHex("00"));

    var b = Bytes.ofHex("0001FEFF");
    var c = Bytes.ofHex("AA01FEFF");

    beq(Native.id_bytes(b), b);
    beq(Native.id_bytes_1(b, c), b);
    beq(Native.id_bytes_2(c, b), b);
    beq(Native.id_bytes_3(b, c), b);
    beq(Native.id_bytes_4(c, b), b);
    beq(Native.id_bytes_5(b, c), b);
    beq(Native.id_bytes_6(c, b), b);

    // should not have been modified
    beq(b, Bytes.ofHex("0001FEFF"));
  }

  function testReturns() {
    beq(Native.give_bytes(0), Bytes.ofHex(""));
    beq(Native.give_bytes(1), Bytes.ofHex("01"));
    beq(Native.give_bytes(10), Bytes.ofHex("0102030405060708090A"));
  }
}
