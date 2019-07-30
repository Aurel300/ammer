class Main {
  public static function main():Void {
    trace('3 + 9 = ${Adder.add_numbers(3, 9)}');
    trace('foo + bar = ${Adder.concat_strings("foo", "bar")}');
    trace('read("dummy.txt") = ${Adder.load_file("dummy.txt")}');
    trace('reverse_bytes("hello") = ${Adder.reverse_bytes(haxe.io.Bytes.ofString("hello"))}');
  }
}
