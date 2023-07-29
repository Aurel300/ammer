package test;

@:ammertest.code("native.h", <x>
  LIB_EXPORT const char *ident_string(const char *a);
  LIB_EXPORT const char *rev_string(const char *a);
  LIB_EXPORT bool check_string(const char *a, int id);
</x>)
@:ammertest.code("native.c", <x>
  LIB_EXPORT const char *ident_string(const char *a) {
    return strdup(a);
  }
  LIB_EXPORT const char *rev_string(const char *a) {
    int len = strlen(a);
    char *ret = malloc(len + 1);
    int *cc = malloc(len * sizeof(int));
    int pos = 0;
    while (*a != 0) cc[pos++] = utf8_decode((unsigned char **)&a);
    char *retcur = ret;
    while (pos > 0) utf8_encode((unsigned char **)&retcur, cc[--pos]);
    *retcur = '\0';
    return ret;
  }
  LIB_EXPORT bool check_string(const char *a, int id) {
    static const char *strings[] = {
      "foo",
      "\x42\xE0\xB2\xA0\xEA\xAF\x8D\xF0\x9F\x90\x84",
    };
    return strcmp(a, strings[id]) == 0;
  }
</x>)
class TestStringsNative extends ammer.def.Sublibrary<def.Native> {
  public static function ident_string(_:String):String;
  public static function rev_string(_:String):String;
  public static function check_string(_:String, _:Int):Bool;
}

class TestStrings extends Test {
  function testAscii() {
    eq(TestStringsNative.ident_string(""), "");
    eq(TestStringsNative.ident_string("aaaa"), "aaaa");
    eq(TestStringsNative.rev_string(""), "");
    eq(TestStringsNative.rev_string("abc"), "cba");
    eq(TestStringsNative.check_string("foo", 0), true);
  }

  #if !java
  function testUnicode() {
    eq(TestStringsNative.ident_string("\u0042\u0CA0\uABCD\u{1F404}"), "\u0042\u0CA0\uABCD\u{1F404}");
    eq(TestStringsNative.rev_string("\u0042\u0CA0\uABCD\u{1F404}"), "\u{1F404}\uABCD\u0CA0\u0042");
    eq(TestStringsNative.check_string("\u0042\u0CA0\uABCD\u{1F404}", 1), true);
  }
  #end
}
