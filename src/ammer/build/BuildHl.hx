package ammer.build;

import ammer.*;

class BuildHl {
  public static function build(config:AmmerConfig, libraries:Array<AmmerContext>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai("all:");
    for (library in libraries) {
      lb.a(' ammer_${library.libname}.hdll');
    }
    lb.a("\n");
    lb.ai("	@:\n\n"); // suppress empty output
    if (config.useMSVC) {
      for (library in libraries) {
        lb.ai('ammer_${library.libname}.hdll: ammer_${library.libname}.hl.obj\n');
        lb.indent(() -> {
          lb.ai('cl /LD ammer_${library.libname}.hl.obj /DLIBHL_EXPORTS /link /OUT:ammer_${library.libname}.hdll');
          if (config.hl.hlLibraryPath != null)
            lb.a(' /LIBPATH:${config.hl.hlLibraryPath}');
          lb.a(' libhl.lib /LIBPATH:${library.libraryPath} ${library.libname}.lib\n\n');
        }, "\t");
        lb.ai('ammer_${library.libname}.hl.obj: ammer_${library.libname}.hl.c\n');
        lb.indent(() -> {
          lb.ai('cl /c ammer_${library.libname}.hl.c /I ${library.includePath}');
          if (config.hl.hlIncludePath != null)
            lb.a(' /I ${config.hl.hlIncludePath}');
          lb.a('\n\n');
        }, "\t");
      }
    } else {
      for (library in libraries) {
        lb.ai('ammer_${library.libname}.hdll: ammer_${library.libname}.hl.o\n');
        lb.indent(() -> {
          lb.ai('$$(CC) $$(CFLAGS) -I ${library.includePath} -D LIBHL_EXPORTS -m64 -shared -o ammer_${library.libname}.hdll ammer_${library.libname}.hl.o');
          if (config.hl.hlLibraryPath != null)
            lb.a(' -L${config.hl.hlLibraryPath}');
          lb.a(' -lhl -L${library.libraryPath} -l${library.libname}\n\n');
        }, "\t");
        lb.ai('ammer_${library.libname}.hl.o: ammer_${library.libname}.hl.c\n');
        lb.indent(() -> {
          lb.ai('$$(CC) $$(CFLAGS) -o ammer_${library.libname}.hl.o -c ammer_${library.libname}.hl.c -I ${library.includePath}\n\n');
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
        sys.io.File.copy('${config.hl.build}/ammer_${library.libname}.hdll', '${config.hl.output}/ammer_${library.libname}.hdll');
      }
    }
  }
}
