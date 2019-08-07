package test;

class TestStrings extends Test {
  function testId() {
    eq(Native.id_string(""), "");
    eq(Native.id_string("aaaa"), "aaaa");
    eq(Native.rev_string(""), "");
    eq(Native.rev_string("abc"), "cba");
  }

  function testUnicode() {
    eq(Native.id_string("\u0042\u0CA0\uABCD\u{1F404}"), "\u0042\u0CA0\uABCD\u{1F404}");
    eq(Native.rev_string("\u0042\u0CA0\uABCD\u{1F404}"), "\u{1F404}\uABCD\u0CA0\u0042");
  }
}
