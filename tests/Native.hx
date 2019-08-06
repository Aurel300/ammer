import ammer.Library;
import ammer.ffi.*;
import haxe.io.Bytes;

class Native extends Library<"native"> {
  // TestSignature.testArgCount
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

  // TestMaths.testInts
  public static function add_ints(_:Int, _:Int):Int;

  // TestMaths.testFloats
  public static function add_floats(_:Float, _:Float):Float;

  // TestMaths.testBools
  public static function logic_and(_:Bool, _:Bool):Bool;
  public static function logic_or(_:Bool, _:Bool):Bool;
  public static function logic_ternary(_:Bool, _:Int, _:Int):Int;
}
