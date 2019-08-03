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
    for (library in libraries) {
      lb.ai('ammer_${library.libname}.hdll: ammer_${library.libname}.o\n');
      lb.ai('	$${CC} $${CFLAGS} -I ${library.includePath} -D LIBHL_EXPORTS -m64 -shared -o ammer_${library.libname}.hdll ammer_${library.libname}.o -L${library.libraryPath} -lhl -l${library.libname}\n\n');
      lb.ai('ammer_${library.libname}.o: ammer_${library.libname}.c\n');
      lb.ai('	$${CC} $${CFLAGS} -o ammer_${library.libname}.o -c ammer_${library.libname}.c -I ${library.includePath}\n\n');
    }
    lb.ai(".PHONY: all\n");
    Ammer.update('${config.hlBuild}/Makefile.ammer', lb.dump());
    Sys.command("make", ["-C", config.hlBuild, "-f", "Makefile.ammer"]);
    if (config.hlBuild != config.hlOutput) {
      for (library in libraries) {
        sys.io.File.copy('${config.hlBuild}/ammer_${library.libname}.hdll', '${config.hlOutput}/ammer_${library.libname}.hdll');
      }
    }
  }
}
