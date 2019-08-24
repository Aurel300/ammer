package ammer.build;

import ammer.*;

class BuildHl {
  public static function build(config:AmmerConfig, libraries:Array<AmmerContext>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai("all:");
    for (library in libraries) {
      lb.a(' ammer_${library.libraryConfig.name}.hdll');
    }
    lb.a("\n");
    lb.ai("	@:\n\n"); // suppress empty output
    for (library in libraries) {
      var sourceExt = "c";
      var compiler = (switch (library.libraryConfig.abi) {
        case C: "$(CC)";
        case Cpp: sourceExt = "cpp"; "$(CXX) -std=c++11";
      });
      if (config.useMSVC) {
        lb.ai('ammer_${library.libraryConfig.name}.hdll: ammer_${library.libraryConfig.name}.hl.obj\n');
        lb.indent(() -> {
          lb.ai('cl /LD ammer_${library.libraryConfig.name}.hl.obj /DLIBHL_EXPORTS /link /OUT:ammer_${library.libraryConfig.name}.hdll');
          if (config.hl.hlLibraryPath != null)
            lb.a(' /LIBPATH:${config.hl.hlLibraryPath}');
          lb.a(' libhl.lib /LIBPATH:${library.libraryConfig.libraryPath} ${library.libraryConfig.name}.lib\n\n');
        }, "\t");
        lb.ai('ammer_${library.libraryConfig.name}.hl.obj: ammer_${library.libraryConfig.name}.hl.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('cl /c ammer_${library.libraryConfig.name}.hl.${sourceExt} /I ${library.libraryConfig.includePath}');
          if (config.hl.hlIncludePath != null)
            lb.a(' /I ${config.hl.hlIncludePath}');
          lb.a('\n\n');
        }, "\t");
      } else {
        lb.ai('ammer_${library.libraryConfig.name}.hdll: ammer_${library.libraryConfig.name}.hl.o\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -I ${library.libraryConfig.includePath} -D LIBHL_EXPORTS -m64 -shared -o ammer_${library.libraryConfig.name}.hdll ammer_${library.libraryConfig.name}.hl.o');
          if (config.hl.hlLibraryPath != null)
            lb.a(' -L${config.hl.hlLibraryPath}');
          lb.a(' -lhl -L${library.libraryConfig.libraryPath} -l${library.libraryConfig.name}\n\n');
        }, "\t");
        lb.ai('ammer_${library.libraryConfig.name}.hl.o: ammer_${library.libraryConfig.name}.hl.${sourceExt}\n');
        lb.indent(() -> {
          lb.ai('$compiler $$(CFLAGS) -fPIC -o ammer_${library.libraryConfig.name}.hl.o -c ammer_${library.libraryConfig.name}.hl.${sourceExt} -I ${library.libraryConfig.includePath}');
          if (config.hl.hlIncludePath != null)
            lb.a(' -I ${config.hl.hlIncludePath}');
          lb.a('\n\n');
        }, "\t");
      }
    }
    lb.ai(".PHONY: all\n");
    Ammer.update('${config.hl.build}/Makefile.hl.ammer', lb.dump());
    if (config.useMSVC) {
      BuildTools.inDir(config.hl.build, () -> Sys.command("nmake", ["/f", "Makefile.hl.ammer"]));
    } else {
      Sys.command("make", ["-C", config.hl.build, "-f", "Makefile.hl.ammer"]);
    }
    if (config.hl.build != config.hl.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.hl.build}/ammer_${library.libraryConfig.name}.hdll', '${config.hl.output}/ammer_${library.libraryConfig.name}.hdll');
      }
    }
  }
}
