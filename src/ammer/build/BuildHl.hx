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
      lb.ai('ammer_${library.libname}.hdll: ammer_${library.libname}.hl.o\n');
      lb.indent(() -> {
        lb.ai('$${CC} $${CFLAGS} -I ${library.includePath} -D LIBHL_EXPORTS -m64 -shared -o ammer_${library.libname}.hdll ammer_${library.libname}.hl.o -L${library.libraryPath} -lhl -l${library.libname}\n\n');
      }, "\t");
      lb.ai('ammer_${library.libname}.hl.o: ammer_${library.libname}.hl.c\n');
      lb.indent(() -> {
        lb.ai('$${CC} $${CFLAGS} -o ammer_${library.libname}.hl.o -c ammer_${library.libname}.hl.c -I ${library.includePath}\n\n');
      }, "\t");
    }
    lb.ai(".PHONY: all\n");
    Ammer.update('${config.hl.build}/Makefile.hl.ammer', lb.dump());
    Sys.command("make", ["-C", config.hl.build, "-f", "Makefile.hl.ammer"]);
    if (config.hl.build != config.hl.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.hl.build}/ammer_${library.libname}.hdll', '${config.hl.output}/ammer_${library.libname}.hdll');
      }
    }
  }
}
