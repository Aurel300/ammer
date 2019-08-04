package ammer.build;

import ammer.*;

class BuildEval {
  public static function build(config:AmmerConfig, libraries:Array<AmmerContext>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai('HAXE=${config.eval.haxeDir}\n');
    lb.ai("-include $(HAXE)/Makefile\n");
    lb.ai("ALL_CFLAGS:=$(subst -I _build/src/,-I $(HAXE)/_build/src/,$(ALL_CFLAGS))\n");
    lb.ai("ALL_CFLAGS:=$(subst -I libs/,-I $(HAXE)/libs/,$(ALL_CFLAGS))\n");
    lb.ai("all_ammer_bytecode:");
    for (library in libraries)
      lb.a(' ammer_${library.libname}.cmo');
    lb.a("\n\t@:\n");
    lb.ai("all_ammer_native:");
    for (library in libraries)
      lb.a(' ammer_${library.libname}.cmxs');
    lb.a("\n\t@:\n");
    for (library in libraries) {
      lb.ai('ammer_${library.libname}.cmo: ammer_${library.libname}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.libname}.eval.o -cclib -L${library.libraryPath} -cclib -l${library.libname} \\\n');
        lb.ai('-o ammer_${library.libname}.cmo ammer_${library.libname}.ml\n');
      }, "\t");
      lb.ai('ammer_${library.libname}.cmxs: ammer_${library.libname}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.libname}.eval.o -cclib -L${library.libraryPath} -cclib -l${library.libname} \\\n');
        lb.ai('-shared -o ammer_${library.libname}.cmxs ammer_${library.libname}.ml\n');
      }, "\t");
      lb.ai('ammer_${library.libname}.eval.o: ammer_${library.libname}.eval.c\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) ammer_${library.libname}.eval.c -I ${library.includePath}\n');
      }, "\t");
    }
    Ammer.update('${config.eval.build}/Makefile.eval.ammer', lb.dump());
    Sys.command("make", ["-C", config.eval.build, "-f", "Makefile.eval.ammer", config.eval.bytecode ? "all_ammer_bytecode" : "all_ammer_native"]);
    if (config.eval.build != config.eval.output) {
      var ext = config.eval.bytecode ? "cmo" : "cmxs";
      for (library in libraries) {
        sys.io.File.copy('${config.eval.build}/ammer_${library.libname}.$ext', '${config.eval.output}/ammer_${library.libname}.$ext');
      }
    }
  }
}
