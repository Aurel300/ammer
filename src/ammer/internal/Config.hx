package ammer.internal;

#if macro

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;

class Config {
  static final BOOL_YES = ["yes", "y", "true", "1", "on"];
  static final BOOL_NO = ["no", "n", "false", "0", "off"];

  public static function hasDefine(key:String):Bool {
    return Context.defined(key);
  }

  /**
    Gets a compile-time define by `key`. If the specified key is not defined,
    return the value `dv`, or throw an error if `doThrow` is `true`.
  **/
  public static function getString(key:String, ?dv:String, ?doThrow:Bool = false):String {
    if (Context.defined(key))
      return Context.definedValue(key);
    if (doThrow)
      Context.fatalError('missing required define: $key', Context.currentPos());
    return dv;
  }

  public static function getStringArray(key:String, sep:String, ?dv:Array<String>, ?doThrow:Bool = false):Array<String> {
    if (Context.defined(key))
      return Context.definedValue(key).split(sep);
    if (doThrow)
      Context.fatalError('missing required define: $key', Context.currentPos());
    return dv;
  }

  /**
    Gets a boolean from the compile-time define `key`.
  **/
  public static function getBool(key:String, ?dv:Bool, ?doThrow:Bool = false):Bool {
    if (Context.defined(key)) {
      if (BOOL_YES.indexOf(Context.definedValue(key)) != -1)
        return true;
      if (BOOL_NO.indexOf(Context.definedValue(key)) != -1)
        return false;
      Context.fatalError('invalid define (should be yes or no): $key', Context.currentPos());
    }
    if (doThrow)
      Context.fatalError('missing required define: $key', Context.currentPos());
    return dv;
  }

  public static function getInt(key:String, ?dv:Int, ?doThrow:Bool = false):Int {
    if (Context.defined(key))
      return Std.parseInt(Context.definedValue(key));
    if (doThrow)
      Context.fatalError('missing required define: $key', Context.currentPos());
    return dv;
  }

  /**
    Gets a path from the compile-time define `key`. If the path is relative,
    resolve it relative to the current working directory.
  **/
  public static function getPath(key:String, ?dv:String, ?doThrow:Bool = false):String {
    var p = getString(key, dv, doThrow);
    if (p != null && !Path.isAbsolute(p))
      p = Path.join([Sys.getCwd(), p]);
    return p;
  }

  public static function getEnum<T>(key:String, map:Map<String, T>, ?dv:T, ?doThrow:Bool = false):T {
    var p = getString(key, null, doThrow);
    if (p == null)
      return dv;
    if (!map.exists(p)) {
      var keys = [for (k in map.keys()) k];
      keys.sort(Reflect.compare);
      Context.fatalError('invalid define (should be one of ${keys.join(", ")})', Context.currentPos());
    }
    return map[p];
  }
}

#end
