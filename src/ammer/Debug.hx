package ammer;

import haxe.macro.Expr;
import haxe.macro.Printer;

class Debug {
  static var printer:Printer = new Printer();

  public static function logP(message:() -> String, stream:String, ?pos:haxe.PosInfos):Void {
    if (Ammer.config.debug.indexOf(stream) == -1)
      return;
    Sys.println('[ammer:$stream] ${message()} (${pos.fileName}:${pos.lineNumber})');
  }

  public static function log(message:Dynamic, stream:String, ?pos:haxe.PosInfos):Void {
    if (Ammer.config.debug.indexOf(stream) == -1)
      return;
    Sys.println('[ammer:$stream] $message (${pos.fileName}:${pos.lineNumber})');
  }

  public static function typeDefinition(t:TypeDefinition):String {
    return printer.printTypeDefinition(t);
  }

  public static function field(f:Field):String {
    return printer.printField(f);
  }
}
