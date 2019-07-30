import ammer.Library;
import ammer.ffi.*;
import haxe.io.Bytes;

class Adder extends Library<"adder"> {
  public static function add_numbers(a:Int, b:Int):Int;
  public static function load_file(filename:String, loaded:SizeOfReturn):Bytes;
  public static function concat_strings(a:String, b:String):String;
  public static function reverse_bytes(data:Bytes, dataLen:SizeOf<"data">):SameSizeAs<Bytes, "data">;
}
