package ammer;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Utils {
  public static var posStack = [];
  public static var argNames:Array<String>;

  public static function withPos(f:()->Void, p:Position):Void {
    posStack.push(p);
    f();
    posStack.pop();
  }

  public static function an(name:String):Expr {
    if (argNames.indexOf(name) == -1)
      throw "no such arg";
    return Utils.id('_arg${argNames.indexOf(name)}');
  }

  public static inline function e(e:ExprDef):Expr {
    return {expr: e, pos: posStack[posStack.length - 1]};
  }

  public static inline function id(s:String):Expr {
    return e(EConst(CIdent(s)));
  }

  /**
    Iterate through the given `metas`. Any entries that do not start with
    `:ammer` will be ignored. All other entries must be present in the `ids`
    whitelist to be accepted. For example, `ids` must contain `"native"` to
    allow the metadata `:ammer.native`. Metadata that are not in the whitelist
    but start with `:ammer` will cause a compile-time error.
  **/
  public static function meta(metas:Metadata, ids:Array<String>):Array<{id:String, params:Array<Expr>}> {
    return [ for (meta in metas) {
      if (!meta.name.startsWith(":ammer"))
        continue;
      var id = meta.name.substr(":ammer.".length);
      if (ids.indexOf(id) == -1)
        Context.fatalError('unsupported or incorrectly specified ammer metadata ${meta.name}', meta.pos);
      {id: id, params: meta.params};
    } ];
  }

  /**
    Save `content` into `path`. Do not rewrite the file if it already exists
    and has the same content.
  **/
  public static function update(path:String, content:String):Void {
    if (!FileSystem.exists(path) || File.getContent(path) != content)
      File.saveContent(path, content);
  }
}

#end
