package ammer;

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;

class Config {
  static final BOOL_YES = ["yes", "y", "true", "1", "on"];
  static final BOOL_NO = ["no", "n", "false", "0", "off"];

  public final eval:Null<AmmerConfigEval> = null;
  public final hl:Null<AmmerConfigHl> = null;
  public final lua:Null<AmmerConfigLua> = null;
  public final debug:Array<String>;
  public final platform:AmmerPlatform;
  public final useMSVC:Bool;
  public final pathMSVC:String;
  public final useMakefiles:Bool;

  public function new() {
    debug = (switch (getDefine("ammer.debug")) {
      case null: [];
      case "all": ["stage", "gen-library", "gen-type", "msg"];
      case s: s.split(",");
    });
    platform = (switch (Context.definedValue("target.name")) {
      case "hl": AmmerPlatform.Hl;
      case "cpp": AmmerPlatform.Cpp;
      case "eval": AmmerPlatform.Eval;
      case "lua": AmmerPlatform.Lua;
      case "cross": AmmerPlatform.Cross;
      case _:
        Context.fatalError("unsupported ammer platform", Context.currentPos());
        null;
    });
    useMSVC = getBool("ammer.msvc", Sys.systemName() == "Windows");
    pathMSVC = getPath("ammer.msvcPath");
    if (pathMSVC == null) {
      pathMSVC = "";
    } else if (pathMSVC != "" && pathMSVC.substr(-1) != "/") {
      pathMSVC += "/";
    }
    useMakefiles = getBool("ammer.makefiles", true);

    // create platform-specific config
    switch (platform) {
      case Eval:
        eval = {
          build: getPath("ammer.eval.build", Sys.getCwd()),
          output: getPath("ammer.eval.output", Sys.getCwd()),
          haxeDir: getPath("ammer.eval.haxeDir", true),
          bytecode: getBool("ammer.eval.bytecode", false)
        };
      case Hl:
        var outputDir = Path.directory(Compiler.getOutput());
        hl = {
          build: getPath("ammer.hl.build", outputDir),
          output: getPath("ammer.hl.output", outputDir),
          hlIncludePath: getPath("ammer.hl.hlInclude", null),
          hlLibraryPath: getPath("ammer.hl.hlLibrary", null)
        };
      case Lua:
        var outputDir = Path.directory(Compiler.getOutput());
        lua = {
          build: getPath("ammer.lua.build", outputDir),
          output: getPath("ammer.lua.output", outputDir),
          luaIncludePath: getPath("ammer.lua.luaInclude", null),
          luaLibraryPath: getPath("ammer.lua.luaLibrary", null)
        };
      case _:
    }
  }

  /**
    Gets a compile-time define by `key`. If the specified key is not defined,
    return the value `dv`, or throw an error if `doThrow` is `true`.
  **/
  public function getDefine(key:String, ?dv:String, ?doThrow:Bool = false):String {
    if (Context.defined(key))
      return Context.definedValue(key);
    if (doThrow)
      Context.fatalError('required define: $key', Context.currentPos());
    return dv;
  }

  /**
    Gets a boolean from the compile-time define `key`.
  **/
  public function getBool(key:String, ?dv:Bool, ?doThrow:Bool = false):Bool {
    if (Context.defined(key)) {
      if (BOOL_YES.indexOf(Context.definedValue(key)) != -1)
        return true;
      if (BOOL_NO.indexOf(Context.definedValue(key)) != -1)
        return false;
      Context.fatalError('invalid define (should be yes or no): $key', Context.currentPos());
    }
    if (doThrow)
      Context.fatalError('required define: $key', Context.currentPos());
    return dv;
  }

  /**
    Gets a path from the compile-time define `key`. If the path is relative,
    resolve it relative to the current working directory.
  **/
  public function getPath(key:String, ?dv:String, ?doThrow:Bool = false):String {
    var p = getDefine(key, dv, doThrow);
    if (p != null && !Path.isAbsolute(p))
      p = Path.join([Sys.getCwd(), p]);
    return p;
  }

  public function getEnum<T>(key:String, map:Map<String, T>, ?dv:T, ?doThrow:Bool = false):T {
    var p = getDefine(key, null, doThrow);
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

enum AmmerPlatform {
  Cpp;
  Eval;
  Hl;
  Lua;
  Cross;
}

typedef AmmerConfigEval = {
  build:String,
  output:String,
  haxeDir:String,
  bytecode:Bool
};

typedef AmmerConfigHl = {
  build:String,
  output:String,
  hlIncludePath:String,
  hlLibraryPath:String
};

typedef AmmerConfigLua = {
  build:String,
  output:String,
  luaIncludePath:String,
  luaLibraryPath:String
};

typedef AmmerLibraryConfig = {
  name:String,
  includePath:String,
  libraryPath:String,
  headers:Array<String>,
  abi:AmmerAbi,
  contexts:Array<AmmerContext>
};

enum AmmerAbi {
  C;
  Cpp;
}
