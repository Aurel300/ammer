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
      lb.a(' ammer_${library.libraryConfig.name}.cmo');
    lb.a("\n\t@:\n");
    lb.ai("all_ammer_native:");
    for (library in libraries)
      lb.a(' ammer_${library.libraryConfig.name}.cmxs');
    lb.a("\n\t@:\n");
    for (library in libraries) {
      lb.ai('ammer_${library.libraryConfig.name}.cmo: ammer_${library.libraryConfig.name}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.libraryConfig.name}.eval.o -cclib -L${library.libraryConfig.libraryPath} -cclib -l${library.libraryConfig.name} \\\n');
        lb.ai('-o ammer_${library.libraryConfig.name}.cmo ammer_${library.libraryConfig.name}.ml\n');
      }, "\t");
      lb.ai('ammer_${library.libraryConfig.name}.cmxs: ammer_${library.libraryConfig.name}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.libraryConfig.name}.eval.o -cclib -L${library.libraryConfig.libraryPath} -cclib -l${library.libraryConfig.name} \\\n');
        lb.ai('-shared -o ammer_${library.libraryConfig.name}.cmxs ammer_${library.libraryConfig.name}.ml\n');
      }, "\t");
      var compiler = (switch (library.libraryConfig.abi) {
        case C: "$(COMPILER)";
        case Cpp: "$(COMPILER) -ccopt -xc++ -cclib -lstdc++ -ccopt -std=c++11";
      });
      lb.ai('ammer_${library.libraryConfig.name}.eval.o: ammer_${library.libraryConfig.name}.eval.c\n');
      lb.indent(() -> {
        lb.ai('$compiler $$(ALL_CFLAGS) ammer_${library.libraryConfig.name}.eval.c -I ${library.libraryConfig.includePath}\n');
      }, "\t");
    }
    Ammer.update('${config.eval.build}/Makefile.eval.ammer', lb.dump());
    Sys.command("make", ["-C", config.eval.build, "-f", "Makefile.eval.ammer", config.eval.bytecode ? "all_ammer_bytecode" : "all_ammer_native"]);
    if (config.eval.build != config.eval.output) {
      var ext = config.eval.bytecode ? "cmo" : "cmxs";
      for (library in libraries) {
        sys.io.File.copy('${config.eval.build}/ammer_${library.libraryConfig.name}.$ext', '${config.eval.output}/ammer_${library.libraryConfig.name}.$ext');
      }
    }
  }
}
