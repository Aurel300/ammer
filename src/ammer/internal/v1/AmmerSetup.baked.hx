#if macro
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
class /*libname*/_AmmerSetup {
  public static function init():Void {
    var osName = (switch (Sys.systemName()) {
      case "Windows": "win";
      case "Linux": "linux";
      case "BSD": "bsd";
      case "Mac": "mac";
      case _: "unknown";
    });
    var extensionDll = (switch (Sys.systemName()) {
      case "Windows": "dll";
      case "Mac": "dylib";
      case _: "so";
    });
    var prefixLib = (switch (Sys.systemName()) {
      case "Windows": "";
      case _: "lib";
    });
    var info = new ammer.internal.v1.LibInfo();
    info.herePos = (macro 0).pos;
    /*libinfo*/
    ammer.internal.v1.AmmerBaked.registerBakedLibraryV1(info);
  }
}
#end
