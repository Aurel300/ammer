import ammer.Library;
import ammer.Opaque;
import ammer.ffi.*;
import haxe.io.Bytes;

class Native extends Library<"native"> {
  public static function take_0():Int;
  public static function take_1(_:Int):Int;
  public static function take_2(_:Int, _:Int):Int;
  public static function take_3(_:Int, _:Int, _:Int):Int;
  public static function take_4(_:Int, _:Int, _:Int, _:Int):Int;
  public static function take_5(_:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_6(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_7(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_8(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_9(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function take_10(_:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int, _:Int):Int;
  public static function nop():Void;

  public static function add_ints(_:Int, _:Int):Int;
  public static function add_uints(_:UInt, _:UInt):UInt;
  public static function add_floats(_:Float, _:Float):Float;
  public static function logic_and(_:Bool, _:Bool):Bool;
  public static function logic_or(_:Bool, _:Bool):Bool;
  public static function logic_ternary(_:Bool, _:Int, _:Int):Int;

  public static function id_string(_:String):String;
  public static function rev_string(_:String):String;

  public static function id_bytes(a:Bytes, b:SizeOf<"a">):SameSizeAs<Bytes, "a">;
  public static function id_bytes_1(a:Bytes, _:NoSize<Bytes>, b:SizeOf<"a">):SameSizeAs<Bytes, "a">;
  public static function id_bytes_2(_:NoSize<Bytes>, a:Bytes, b:SizeOf<"a">):SameSizeAs<Bytes, "a">;
  public static function id_bytes_3(a:Bytes, b:SizeOf<"a">, _:NoSize<Bytes>):SameSizeAs<Bytes, "a">;
  public static function id_bytes_4(_:NoSize<Bytes>, b:SizeOf<"a">, a:Bytes):SameSizeAs<Bytes, "a">;
  public static function id_bytes_5(b:SizeOf<"a">, a:Bytes, _:NoSize<Bytes>):SameSizeAs<Bytes, "a">;
  public static function id_bytes_6(b:SizeOf<"a">, _:NoSize<Bytes>, a:Bytes):SameSizeAs<Bytes, "a">;
  public static function give_bytes(_:Int, _:SizeOfReturn):Bytes;

  public static function create_opaque():NativeOpaque;
}

@:ammer.native("opaque_type_t")
class NativeOpaque extends Opaque<Native> {
  public function opaque_get_int(_:ammer.ffi.This):Int;
  public function opaque_get_float(_:ammer.ffi.This):Float;
  public function opaque_get_string(_:ammer.ffi.This):String;
}
