import ammer.Library;
import ammer.ffi.*;
import haxe.io.Bytes;

@:ammer.sub((_ : XTemplatesStruct))
class Templates extends Library<"templates"> {
  @:ammer.native("templated_add_ints") public static function templated_add_ints32(a:Int, b:Int):Int;

  public static function cpp_nop():Void;
}

@:ammer.struct
class XTemplatesStruct extends ammer.Pointer<"TemplatesStruct", Templates> {
  public var member_int:UInt32;

  @:ammer.native("TemplatesStruct")
  @:ammer.cpp.constructor
  public static function new_():XTemplatesStruct;

  @:ammer.cpp.member
  public function add(x:UInt32):UInt32;
}
