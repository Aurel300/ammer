package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.PositionTools;

class Reporting {
  public static var positionStack:Array<Position> = [];
  static var debugStreams:Map<String, Bool>;
  static var imports:Map<String, {
    imports:Array<String>,
    usings:Array<String>,
    module:String,
  }> = [];

  static function shouldEmit(stream:String):Bool {
    if (debugStreams == null) {
      debugStreams = [
        "stage" => false,
        "stage-ffi" => false,
      ];
      switch (Config.getString("ammer.debug")) {
        case null:
        case "all": for (k in debugStreams.keys()) debugStreams[k] = true;
        case s: for (k in s.split(",")) debugStreams[k] = true;
      }
    }
    return debugStreams[stream];
  }

  public static function pushPosition(pos:Position):Void {
    positionStack.push(pos);
  }
  public static function popPosition():Void {
    positionStack.length > 0 || throw 0;
    positionStack.pop();
  }
  public static function withPosition<T>(pos:Position, f:()->T):T {
    pushPosition(pos);
    var ret = f();
    // TODO: throw does not reset the stack, implement catchable errors
    popPosition();
    return ret;
  }
  public static function withCurrentPos<T>(f:()->T, recordImports:Bool = true):T {
    if (recordImports) {
      var filename = Context.currentPos().getInfos().file;
      if (!imports.exists(filename)) {
        imports[filename] = {
          imports: [ for (imp in Context.getLocalImports()) {
            var path = imp.path.map(p -> p.name).join(".");
            switch (imp.mode) {
              case INormal: path;
              case IAsName(alias): '$path as $alias';
              case IAll: "*";
            };
          } ],
          usings: [ for (use in Context.getLocalUsing()) {
            var cls = use.get();
            cls.pack.concat([cls.module.split(".").pop(), cls.name]).join(".");
          } ],
          module: Context.getLocalModule(),
        };
      }
    }
    return withPosition(Context.currentPos(), f);
  }

  public static function currentPos():Position {
    positionStack.length > 0 || throw 0;
    return positionStack[positionStack.length - 1];
  }

  public static function log(msg:String, stream:String, ?pos:haxe.PosInfos):Void {
    if (shouldEmit(stream))
      Sys.println('[ammer:$stream] $msg (${pos.fileName}:${pos.lineNumber})');
  }

  public static function warning(msg:String):Void {
    Context.warning(msg, currentPos());
  }
  public static function error(msg:String):Void {
    Context.error(msg, currentPos());
  }

  public static function resolveType(ct:ComplexType, pos:Position):Type {
    var curPos = Context.currentPos();
    var curFilename = curPos.getInfos().file;
    var filename = pos.getInfos().file;
    if (curFilename != filename) {
      var importsForFile = imports[filename];
      importsForFile != null || throw 0;
      return Context.withImports(
        importsForFile.imports.concat([importsForFile.module]),
        importsForFile.usings,
        () -> Context.resolveType(ct, pos)
      );
    } else {
      return Context.resolveType(ct, pos);
    }
  }

  // TODO: catchable, emitted error that does not immediately abort?
  // throw Reporting.error("...") ?
}

#end
