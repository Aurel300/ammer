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
  #if !lua
  public static function add_singles(_:Single, _:Single):Single;
  #end
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

  @:ammer.c.prereturn("save_num(5);")
  public static function get_saved_num():Int;

  @:ammer.c.prereturn("save_num(11);")
  @:ammer.c.return("*(%CALL%)")
  public static function pointer_saved_num():Int;

  #if (hl || cpp)
  public static function save_func(f:Closure<(Int, Int, ClosureDataUse)->Int, "once">, _:ClosureData<"f">):Void;
  public static function call_func():Int;
  public static function call_func_2(_:ClosureData<"f">, f:Closure<(ClosureDataUse, String)->Int, "once">):Int;
  public static function call_func_3(_:ClosureData<"f">, f:Closure<(NativeCallbackData)->Int, "once">):Int;
  public static function call_func_4(_:ClosureData<"f">, f:Closure<(ClosureDataUse, NativeEnum)->NativeEnum, "once">):Bool;
  #end

  public static function create_opaque():NativeOpaque;

  #if (hl || cpp)
  public static function opaque_indirect(_:OutPointer<NativeOpaque>):Void;
  public static function create_opaque_noalloc():ammer.ffi.Alloc<NativeOpaque>;
  public static function opaque_take_nested(a:ammer.ffi.Nested<NativeOpaque>):Bool;

  public static function take_array_fixed(a:ammer.ffi.ArrayFixed<Int, 3>):Int;
  public static function take_array(a:ammer.ffi.ArrayDynamic<Int>, b:ammer.ffi.SizeOf<"a">):Int;
  public static function take_array_modify(a:NoSize<ammer.ffi.ArrayDynamic<Int>>):Void;
  #end

  public static function take_enum(a:NativeEnum, b:NativeEnum, c:NativeEnum):Bool;
  public static function give_enum():NativeEnum;

  public static function take_unsupported(a:Unsupported<"void *">, b:Unsupported<"double">):Bool;
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

// TODO: "opaque" is now a misnomer
@:ammer.nativePrefix("opaque_")
@:ammer.struct
class NativeOpaque extends Pointer<"opaque_type_t", Native> {
  @:ammer.native("member_int") public var member_int:Int;
  @:ammer.native("member_float") public var member_float:Float;
  @:ammer.native("member_string") public var member_string:String;

  @:ammer.native("member_int_array_fixed") public var member_int_array_fixed:ammer.ffi.ArrayFixed<Int, 8>;
  #if (hl || cpp)
  @:ammer.native("member_int_array") public var member_int_array:ammer.ffi.ArrayDynamic<Int>;
  @:ammer.native("member_int_array_size") public var member_int_array_size:ammer.ffi.SizeOf<"member_int_array">;
  @:ammer.native("member_string_array") public var member_string_array:ammer.ffi.ArrayDynamic<String>;
  @:ammer.native("member_string_array_size") public var member_string_array_size:ammer.ffi.SizeOf<"member_string_array">;
  #end

  public function get_int(_:This):Int;
  public function get_float(_:This):Float;
  public function get_string(_:This):String;
  public function get_int_alt(_:Int, _:This, _:Int):Int;
  public function get_bytes(_:This, _:SizeOfReturn):Bytes;

  #if (hl || cpp)
  public function get_int_nested(_:Nested<This>):Int;
  #end
}

#if (hl || cpp)
@:ammer.struct
class NativeCallbackData extends Pointer<"callback_data_t", Native> {
  public var user_data:ClosureDataUse;
  public var foo:Int;
}
#end

class NativeEnum extends IntEnum<"enum enum_constants", Native> {
  @:ammer.native("e_const0") public static var EConst0:NativeEnum;
  @:ammer.native("e_const1") public static var EConst1:NativeEnum;
  @:ammer.native("e_const10") public static var EConst10:NativeEnum;
}
