package ammer.build;

import ammer.Config.AmmerLibraryConfig;
import ammer.build.BuildTools.MakeCommand;

using Lambda;

class BuildHl {
  public static function build(config:Config, libraries:Array<AmmerLibraryConfig>):Void {
    BuildTools.make([
      {target: "all", requires: libraries.map(l -> 'ammer_${l.name}.hdll'), command: Phony}
    ].concat([
      for (library in libraries) {
        var sourceExt = library.abi == Cpp ? "cpp" : "c";
        [
          {
            target: 'ammer_${library.name}.hdll',
            requires: [BuildTools.extensions('ammer_${library.name}.hl.%OBJ%')],
            command: LinkLibrary({
              defines: ["LIBHL_EXPORTS"],
              libraryPaths: (config.hl.hlLibraryPath != null ? [config.hl.hlLibraryPath] : []).concat([library.libraryPath]),
              libraries: [config.useMSVC ? "libhl" : "hl", library.name]
            })
          },
          {
            target: BuildTools.extensions('ammer_${library.name}.hl.%OBJ%'),
            requires: ['ammer_${library.name}.hl.${sourceExt}'],
            command: (library.abi == Cpp ? CompileObjectCpp : CompileObjectC)({
              includePaths: (config.hl.hlIncludePath != null ? [config.hl.hlIncludePath] : []).concat([library.includePath])
            })
          }
        ];
      }
    ].flatten()), config.hl.build, "Makefile.hl.ammer");
    if (config.hl.build != config.hl.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.hl.build}/ammer_${library.name}.hdll', '${config.hl.output}/ammer_${library.name}.hdll');
      }
    }
  }
}
