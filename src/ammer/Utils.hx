package ammer;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Utils {
  /**
    Metadata allowed for the class defining a library.
  **/
  public static final META_LIBRARY_CLASS = [
    "nativePrefix"
  ];

  /**
    Metadata allowed for a method of a library.
  **/
  public static final META_LIBRARY_METHOD = [
    "native", "macroCall", "c.prereturn", "c.return"
  ];

  /**
    Metadata allowed for a variable of a library.
  **/
  public static final META_LIBRARY_VARIABLE = [
    "native"
  ];

  /**
    Metadata allowed for the class defining an opaque type.
  **/
  public static final META_OPAQUE_CLASS = [
    "native", "nativePrefix"
  ];

  public static var posStack = [];

  public static function withPos(f:()->Void, p:Position):Void {
    posStack.push(p);
    f();
    posStack.pop();
  }

  public static inline function e(e:ExprDef):Expr {
    return {expr: e, pos: posStack[posStack.length - 1]};
  }

  public static inline function id(s:String):Expr {
    return e(EConst(CIdent(s)));
  }

  public static inline function arg(n:Int):Expr {
    return id('_arg$n');
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
        Context.fatalError('unsupported or incorrectly specified ammer metadata ${meta.name} (should be one of ${ids.join(", ")})', meta.pos);
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

  /**
    Ensure `path` exists and is a directory. Create it if it does not exist.
  **/
  public static function ensureDirectory(path:String):Void {
    if (!FileSystem.exists(path))
      FileSystem.createDirectory(path);
    if (!FileSystem.isDirectory(path))
      Context.fatalError('$path should be a directory', Context.currentPos());
  }

  public static function opaqueId(t:ClassType):String {
    return '${t.pack.join(".")}.${t.module.split(".").pop()}.${t.name}';
  }
}

#end
