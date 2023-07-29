// ammer-bake: ammer.internal.v1 OsInfo true
package ammer.internal.v1;

#if macro

/**
  Provides more complete info about the operating system. Possible values for
  the data fields are as follows:

  - `os`: "windows", "mac", "linux"
  - `version` (for "windows"): (TODO)
  - `version` (for "mac"): "11.2.3", "10.9.5", etc
  - `version` (for "linux"): (TODO)
  - `architecture`: "x86_64", etc

  Keys are `null` when unknown.

  Additionally, `versionCompare` provides a function with the same signature
  as `Reflect.compare` to compare two version strings for the given OS.
**/
class OsInfo {
  public static var info(get, never):OsInfo;
  static var infoL:OsInfo;
  static function get_info():OsInfo {
    if (infoL != null)
      return infoL;
    return infoL = new OsInfo();
  }

  public var os(default, null):Null<String>;
  public var version(default, null):Null<String>;
  public var architecture(default, null):Null<String>;
  public var versionCompare(default, null):(a:String, b:String)->Int;

  function new() {
    var osRaw = Sys.systemName();
    versionCompare = (a:String, b:String) -> Reflect.compare(a, b);
    function run(cmd:String, args:Array<String>):String {
      var proc = new sys.io.Process(cmd, args);
      var code = proc.exitCode();
      var stdout = proc.stdout.readAll().toString();
      proc.close();
      return stdout;
    }
    // simplified semver: only accepts X.Y.Z format
    function semverCompare(a:String, b:String):Int {
      var as = a.split(".").map(Std.parseInt);
      var bs = b.split(".").map(Std.parseInt);
      (as.length == 3
        && as[0] != null && as[0] >= 0
        && as[1] != null && as[1] >= 0
        && as[2] != null && as[2] >= 0) || throw 'invalid semver $a';
      (bs.length == 3
        && bs[0] != null && bs[0] >= 0
        && bs[1] != null && bs[1] >= 0
        && bs[2] != null && bs[2] >= 0) || throw 'invalid semver $b';
      for (i in 0...3) {
        if (as[0] != bs[0])
          return as[0] < bs[0] ? -1 : 1;
      }
      return 0;
    }
    switch (osRaw) {
      case "Mac":
        os = "mac";
        version = run("sw_vers", ["-productVersion"]);
        architecture = run("uname", ["-m"]);
        versionCompare = semverCompare;
      case _:
        os = osRaw.toLowerCase();
        // TODO
    }
  }
}

#end
