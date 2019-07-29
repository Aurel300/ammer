class Adder extends ammer.Library<"adder"> {
  public static function add_numbers(a:Int, b:Int):Int;
  public static function load_file(filename:String, @:ammer.returnSizePtr loaded:Int):haxe.io.Bytes;
  public static function concat_strings(a:String, b:String):String;
  @:ammer.returnSizeSameAs(data) public static function reverse_bytes(data:haxe.io.Bytes, @:ammer.sizeOf(data) dataLen:Int):haxe.io.Bytes;
}
