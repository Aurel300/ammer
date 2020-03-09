package ammer.build;

import ammer.Config.AmmerLibraryConfig;
import ammer.build.BuildTools.MakeCommand;

using Lambda;

class BuildLua {
  public static function build(config:Config, libraries:Array<AmmerLibraryConfig>):Void {
    BuildTools.make([
      {target: "all", requires: libraries.map(l -> BuildTools.extensions('ammer_${l.name}.%DLL%')), command: Phony}
    ].concat([
      for (library in libraries) {
        var sourceExt = library.abi == Cpp ? "cpp" : "c";
        [
          {
            target: BuildTools.extensions('ammer_${library.name}.%DLL%'),
            requires: [BuildTools.extensions('ammer_${library.name}.lua.%OBJ%')],
            command: LinkLibrary({
              defines: [],
              libraryPaths: (config.lua.luaLibraryPath != null ? [config.lua.luaLibraryPath] : []).concat([library.libraryPath]),
              libraries: [config.useMSVC ? "liblua" : "lua", library.name]
            })
          },
          {
            target: BuildTools.extensions('ammer_${library.name}.lua.%OBJ%'),
            requires: ['ammer_${library.name}.lua.${sourceExt}'],
            command: (library.abi == Cpp ? CompileObjectCpp : CompileObjectC)({
              includePaths: (config.lua.luaIncludePath != null ? [config.lua.luaIncludePath] : []).concat([library.includePath])
            })
          }
        ];
      }
    ].flatten()), config.lua.build, "Makefile.lua.ammer");
    if (config.lua.build != config.lua.output) {
      for (library in libraries) {
        sys.io.File.copy('${config.lua.build}/${BuildTools.extensions('ammer_${library.name}.%DLL%')}', '${config.lua.output}/${BuildTools.extensions('ammer_${library.name}.%DLL%')}');
      }
    }
  }
}
