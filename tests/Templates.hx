import ammer.Library;
import ammer.ffi.*;
import haxe.io.Bytes;

class Templates extends Library<"templates"> {
  @:ammer.native("templated_add_ints") public static function templated_add_ints32(a:Int, b:Int):Int;

  public static function cpp_nop():Void;
}
