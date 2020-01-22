package ammer.build;

import ammer.AmmerConfig.AmmerLibraryConfig;

class BuildHl {
  public static function build(config:AmmerConfig, libraries:Array<AmmerLibraryConfig>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai("all:");
    for (library in libraries) {
      lb.a(' ammer_${library.name}.hdll');
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
        lb.ai('ammer_${library.name}.hdll: ammer_${library.name}.hl.obj\n');
        lb.indent(() -> {
          lb.ai('cl /LD ammer_${library.name}.hl.obj /DLIBHL_EXPORTS /link /OUT:ammer_${library.name}.hdll');
          if (config.hl.hlLibraryPath != null)
            lb.a(' /LIBPATH:${config.hl.hlLibraryPath}');
          lb.a(' libhl.lib /LIBPATH:${library.libraryPath} ${library.name}.lib\n\n');
        }, "\t");
        lb.ai('ammer_${library.name}.hl.obj: ammer_${library.name}.hl.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('cl /c ammer_${library.name}.hl.${sourceExt} /I ${library.includePath}');
          if (config.hl.hlIncludePath != null)
            lb.a(' /I ${config.hl.hlIncludePath}');
          lb.a('\n\n');
        }, "\t");
      } else {
        lb.ai('ammer_${library.name}.hdll: ammer_${library.name}.hl.o\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -I ${library.includePath} -D LIBHL_EXPORTS -m64 -shared -o ammer_${library.name}.hdll ammer_${library.name}.hl.o');
          if (config.hl.hlLibraryPath != null)
            lb.a(' -L${config.hl.hlLibraryPath}');
          lb.a(' -lhl -L${library.libraryPath} -l${library.name}\n\n');
        }, "\t");
        lb.ai('ammer_${library.name}.hl.o: ammer_${library.name}.hl.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -fPIC -o ammer_${library.name}.hl.o -c ammer_${library.name}.hl.${sourceExt} -I ${library.includePath}');
          if (config.hl.hlIncludePath != null)
            lb.a(' -I ${config.hl.hlIncludePath}');
          lb.a('\n\n');
        }, "\t");
      }
    }
    lb.ai(".PHONY: all\n");
    Utils.update('${config.hl.build}/Makefile.hl.ammer', lb.dump());
    if (config.useMSVC) {
      BuildTools.inDir(config.hl.build, () -> Sys.command("nmake", ["/f", "Makefile.hl.ammer"]));
    } else {
      Sys.command("make", ["-C", config.hl.build, "-f", "Makefile.hl.ammer"]);
    }
    if (config.hl.build != config.hl.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.hl.build}/ammer_${library.name}.hdll', '${config.hl.output}/ammer_${library.name}.hdll');
      }
    }
  }
}
