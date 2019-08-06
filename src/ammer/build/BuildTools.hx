package ammer.build;

class BuildTools {
  public static function inDir(path:String, f:() -> Void):Void {
    var cwd = Sys.getCwd();
    Sys.setCwd(path);
    f();
    Sys.setCwd(cwd);
  }
}
