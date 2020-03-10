import ammer.*;
import ammer.ffi.*;
import haxe.io.Bytes;

class Native extends Library<"native"> {
  @:ammer.native("DEFINE_INT") public static var define_int:Int;
  @:ammer.native("DEFINE_INT_EXPR") public static var define_int_expr:Int;
  @:ammer.native("DEFINE_STRING") public static var define_string:String;
  @:ammer.native("DEFINE_STRING_EXPR") public static var define_string_expr:String;
  @:ammer.native("DEFINE_BOOL") public static var define_bool:Bool;
  @:ammer.native("DEFINE_BOOL_EXPR") public static var define_bool_expr:Bool;
  @:ammer.native("DEFINE_FLOAT") public static var define_float:Float;
  @:ammer.native("DEFINE_FLOAT_EXPR") public static var define_float_expr:Float;

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

  #if (hl || lua)
  @:ammer.c.prereturn("save_num(5);")
  public static function get_saved_num():Int;

  @:ammer.c.prereturn("save_num(11);")
  @:ammer.c.return("*(%CALL%)")
  public static function pointer_saved_num():Int;
  #end

  #if (hl)
  public static function save_func(_:ammer.ffi.Gc.RootOnce<(Int, Int)->Int>):Void;
  public static function call_func():Int;
  #end

  #if (hl || cpp || lua)
  public static function create_opaque():NativeOpaque;
  #end
}

class Native2 extends Library<"native"> {
  public static function take_0():Int;
  public static function take_0alt():Int;
}

@:ammer.nativePrefix("prefixed_")
class NativePrefixed extends Library<"native"> {
  public static function nop2():Void;
  @:ammer.native("take_0") public static function take_0():Int;
}

#if (hl || cpp || lua)
@:ammer.nativePrefix("opaque_")
class NativeOpaque extends Pointer<"opaque_type_t", Native> {
  public function get_int(_:ammer.ffi.This):Int;
  public function get_float(_:ammer.ffi.This):Float;
  public function get_string(_:ammer.ffi.This):String;
  public function get_int_alt(_:Int, _:ammer.ffi.This, _:Int):Int;
}
#end
