package ammer.build;

import ammer.Config.AmmerLibraryConfig;

class BuildLua {
  public static function build(config:Config, libraries:Array<AmmerLibraryConfig>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai("all:");
    for (library in libraries) {
      lb.a(' ammer_${library.name}.dylib');
    }
    lb.a("\n");
    lb.ai("	@:\n\n"); // suppress empty output
    for (library in libraries) {
      var sourceExt = "c";
      var compiler = (switch (library.abi) {
        case C: "$(CC)";
        case Cpp: sourceExt = "cpp"; "$(CXX) -std=c++11";
      });
      if (config.useMSVC) {
        lb.ai('ammer_${library.name}.dll: ammer_${library.name}.lua.obj\n');
        lb.indent(() -> {
          lb.ai('${config.pathMSVC}cl /LD ammer_${library.name}.lua.obj /link /OUT:ammer_${library.name}.dll');
          if (config.lua.luaLibraryPath != null)
            lb.a(' /LIBPATH:"${config.lua.luaLibraryPath}"');
          lb.a(' liblua.lib /LIBPATH:"${library.libraryPath}" ${library.name}.lib\n\n');
        }, "\t");
        lb.ai('ammer_${library.name}.lua.obj: ammer_${library.name}.lua.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('${config.pathMSVC}cl /c ammer_${library.name}.lua.${sourceExt} /I "${library.includePath}"');
          if (config.lua.luaIncludePath != null)
            lb.a(' /I "${config.lua.luaIncludePath}"');
          lb.a('\n\n');
        }, "\t");
      } else {
        // TODO: dylib, so, dll depending on OS
        lb.ai('ammer_${library.name}.dylib: ammer_${library.name}.lua.o\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -dynamiclib -I "${library.includePath}" -o ammer_${library.name}.dylib ammer_${library.name}.lua.o');
          if (config.lua.luaLibraryPath != null)
            lb.a(' -L"${config.lua.luaLibraryPath}"');
          lb.a(' -llua -L"${library.libraryPath}" -l${library.name}\n\n');
        }, "\t");
        lb.ai('ammer_${library.name}.lua.o: ammer_${library.name}.lua.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -fPIC -o ammer_${library.name}.lua.o -c ammer_${library.name}.lua.${sourceExt} -I "${library.includePath}"');
          if (config.lua.luaIncludePath != null)
            lb.a(' -I "${config.lua.luaIncludePath}"');
          lb.a('\n\n');
        }, "\t");
      }
    }
    lb.ai(".PHONY: all\n");
    Utils.update('${config.lua.build}/Makefile.lua.ammer', lb.dump());
    if (config.useMSVC) {
      BuildTools.inDir(config.lua.build, () -> Sys.command(config.pathMSVC + "nmake", ["/f", "Makefile.lua.ammer"]));
    } else {
      Sys.command("make", ["-C", config.lua.build, "-f", "Makefile.lua.ammer"]);
    }
    if (config.lua.build != config.lua.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.lua.build}/ammer_${library.name}.dylib', '${config.lua.output}/ammer_${library.name}.dylib');
      }
    }
  }
}
