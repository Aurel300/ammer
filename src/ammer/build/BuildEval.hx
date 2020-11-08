package ammer.build;

import ammer.Config.AmmerLibraryConfig;

class BuildEval {
  public static function build(config:Config, libraries:Array<AmmerLibraryConfig>):Void {
    var lb:LineBuf = new LineBuf();
    lb.ai('HAXE=${config.eval.haxeDir}\n');
    lb.ai("-include $(HAXE)/Makefile\n");
    lb.ai("ALL_CFLAGS:=$(subst -I _build/src/,-I $(HAXE)/_build/src/,$(ALL_CFLAGS))\n");
    lb.ai("ALL_CFLAGS:=$(subst -I libs/,-I $(HAXE)/libs/,$(ALL_CFLAGS))\n");
    lb.ai("all_ammer_bytecode:");
    for (library in libraries)
      lb.a(' ammer_${library.name}.cmo');
    lb.a("\n\t@:\n");
    lb.ai("all_ammer_native:");
    for (library in libraries)
      lb.a(' ammer_${library.name}.cmxs');
    lb.a("\n\t@:\n");
    for (library in libraries) {
      lb.ai('ammer_${library.name}.cmo: ammer_${library.name}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.name}.eval.o -cclib -L"${library.libraryPath}" -cclib -l${library.linkName} \\\n');
        lb.ai('-o ammer_${library.name}.cmo ammer_${library.name}.ml\n');
      }, "\t");
      lb.ai('ammer_${library.name}.cmxs: ammer_${library.name}.eval.o\n');
      lb.indent(() -> {
        lb.ai('$$(COMPILER) $$(ALL_CFLAGS) \\\n');
        lb.ai('-cclib ammer_${library.name}.eval.o -cclib -L"${library.libraryPath}" -cclib -l${library.linkName} \\\n');
        lb.ai('-shared -o ammer_${library.name}.cmxs ammer_${library.name}.ml\n');
      }, "\t");
      var compiler = (switch (library.abi) {
        case C: "$(COMPILER)";
        case Cpp: "$(COMPILER) -ccopt -xc++ -cclib -lstdc++ -ccopt -std=c++11";
      });
      lb.ai('ammer_${library.name}.eval.o: ammer_${library.name}.eval.c\n');
      lb.indent(() -> {
        lb.ai('$compiler $$(ALL_CFLAGS) ammer_${library.name}.eval.c -I "${library.includePath}"\n');
      }, "\t");
    }
    Utils.update('${config.eval.build}/Makefile.eval.ammer', lb.dump());
    Sys.command("make", ["-C", config.eval.build, "-f", "Makefile.eval.ammer", config.eval.bytecode ? "all_ammer_bytecode" : "all_ammer_native"]);
    if (config.eval.build != config.eval.output) {
      var ext = config.eval.bytecode ? "cmo" : "cmxs";
      for (library in libraries) {
        sys.io.File.copy('${config.eval.build}/ammer_${library.name}.$ext', '${config.eval.output}/ammer_${library.name}.$ext');
      }
    }
  }
}
