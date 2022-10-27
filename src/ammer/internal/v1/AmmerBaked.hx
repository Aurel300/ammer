// ammer-bake: ammer.internal.v1 AmmerBaked true
package ammer.internal.v1;

#if macro

import haxe.macro.Context;
import haxe.macro.PositionTools;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

#if ammer
typedef AmmerBaked = Ammer;
#else
class AmmerBaked {
  // copied from ammer.core.BuildProgram
  // TODO: configurable MSVC and system
  static var useMSVC = Sys.systemName() == "Windows";
  static var extensionDll = (switch (Sys.systemName()) {
    case "Windows": "dll";
    case "Mac": "dylib";
    case _: "so";
  });
  static function extensions(path:String):String {
    return path
      .replace("%OBJ%", useMSVC ? "obj" : "o")
      .replace("%LIB%", useMSVC ? "" : "lib")
      .replace("%DLL%", extensionDll);
  }

  public static var mergedInfo = new ammer.internal.v1.LibInfo();
  public static function registerBakedLibraryV1(info:ammer.internal.v1.LibInfo):Void {
    var fail = Context.fatalError.bind(_, Context.currentPos());
    // ammer-include: internal/Ammer.hx register-v1
  }
}
#end

#end
