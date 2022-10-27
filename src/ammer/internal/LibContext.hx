package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

typedef LibContextOptions = {
  name:String,
  headers:Array<ammer.core.SourceInclude>,
  defines:Array<String>,
  definesCodeOnly:Array<String>,
  includePaths:Array<{rel:String, abs:String}>,
  libraryPaths:Array<{rel:String, abs:String}>,
  frameworks:Array<String>,
  language:ammer.core.LibraryLanguage,
  linkNames:Array<String>,
};

class LibContext {
  public var name:String;
  public var originalOptions:LibContextOptions;
  public var libraryOptions:ammer.core.LibraryConfig;
  public var library:ammer.core.Library;
  public var marshal:ammer.core.Marshal;
  public var headers:Array<ammer.core.SourceInclude>;
  public var prebuild:Array<{
    code:String,
    process:String->Void,
  }> = [];
  public var done:Bool = false;

  public var info = new ammer.internal.v1.LibInfo();
  public var infoV1:Null<ammer.internal.v1.LibInfo>;

  public var isLibTypes:Bool = false;

  public function new(name:String, options:LibContextOptions) {
    this.name = name;
    originalOptions = options;

    var libName = 'ammer_${options.name}';
    libraryOptions = (switch (Context.definedValue("target.name")) {
      case "cpp": ({name: libName} : ammer.core.plat.Cpp.CppLibraryConfig);
      case "cs": ({name: libName} : ammer.core.plat.Cs.CsLibraryConfig);
      case "hl": ({name: libName} : ammer.core.plat.Hashlink.HashlinkLibraryConfig);
      case "java": ({
          name: libName,
          jvm: Context.defined("jvm"),
        } : ammer.core.plat.Java.JavaLibraryConfig);
      case "lua": ({name: libName} : ammer.core.plat.Lua.LuaLibraryConfig);
      case "neko": ({name: libName} : ammer.core.plat.Neko.NekoLibraryConfig);
      case "js": ({name: libName} : ammer.core.plat.Nodejs.NodejsLibraryConfig);
      case "python": ({name: libName} : ammer.core.plat.Python.PythonLibraryConfig);

      case _: ({name: libName} : ammer.core.plat.None.NoneLibraryConfig);
    });

    libraryOptions.language = options.language;
    libraryOptions.defines = options.defines;
    libraryOptions.definesCodeOnly = options.definesCodeOnly;
    libraryOptions.includePaths = options.includePaths.map(p -> p.abs);
    libraryOptions.libraryPaths = options.libraryPaths.map(p -> p.abs);
    libraryOptions.frameworks = options.frameworks;
    libraryOptions.linkNames = options.linkNames;
    libraryOptions.pos = Reporting.currentPos();

    // process configuration defines
    // TODO: -D for defines
    var prefix = 'ammer.lib.${options.name}';
    if (Config.hasDefine('$prefix.frameworks'))
      libraryOptions.frameworks = Config.getStringArray('$prefix.frameworks', ",");
    if (Config.hasDefine('$prefix.linkNames'))
      libraryOptions.linkNames = Config.getStringArray('$prefix.linkNames', ",");
    if (Config.hasDefine('$prefix.includePaths'))
      libraryOptions.includePaths = Config.getStringArray('$prefix.includePaths', ",");
    if (Config.hasDefine('$prefix.libraryPaths'))
      libraryOptions.libraryPaths = Config.getStringArray('$prefix.libraryPaths', ",");
    if (Config.hasDefine('$prefix.language'))
      libraryOptions.language = Config.getEnum('$prefix.language', [
        "c" => ammer.core.LibraryLanguage.C,
        "cpp" => Cpp,
        "objc" => ObjectiveC,
        "objcpp" => ObjectiveCpp,
      ], C);

    // process includes
    if (Config.hasDefine('$prefix.headers')
      || Config.hasDefine('$prefix.headers.includeLocal')
      || Config.hasDefine('$prefix.headers.includeGlobal')
      || Config.hasDefine('$prefix.headers.importLocal')
      || Config.hasDefine('$prefix.headers.importGlobal')) {
      headers = [];
      if (Config.hasDefine('$prefix.headers'))
        headers = headers.concat(Config.getStringArray('$prefix.headers', ",").map(ammer.core.SourceInclude.IncludeLocal));
      if (Config.hasDefine('$prefix.headers.includeLocal'))
        headers = headers.concat(Config.getStringArray('$prefix.headers.includeLocal', ",").map(ammer.core.SourceInclude.IncludeLocal));
      if (Config.hasDefine('$prefix.headers.includeGlobal'))
        headers = headers.concat(Config.getStringArray('$prefix.headers.includeGlobal', ",").map(ammer.core.SourceInclude.IncludeGlobal));
      if (Config.hasDefine('$prefix.headers.importLocal'))
        headers = headers.concat(Config.getStringArray('$prefix.headers.importLocal', ",").map(ammer.core.SourceInclude.ImportLocal));
      if (Config.hasDefine('$prefix.headers.importGlobal'))
        headers = headers.concat(Config.getStringArray('$prefix.headers.importGlobal', ",").map(ammer.core.SourceInclude.ImportGlobal));
    } else {
      headers = options.headers;
    }

    library = Ammer.platform.createLibrary(libraryOptions);
    for (header in headers) library.addInclude(header);
    marshal = library.marshal();
  }

  public function prebuildImmediate(code:String):String {
    // TODO: cache
    var ret:String = null;
    var program = new ammer.core.utils.LineBuf()
      .lmap(headers, header -> header.toCode())
      .a(code)
      .done();
    Ammer.builder.build(new ammer.core.build.BuildProgram([
      BOAlways(File('${Ammer.baseConfig.buildPath}/ammer_${name}'), EnsureDirectory),
      BOAlways(
        File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild.c'), // TODO: append cache key or delete?
        WriteContent(program)
      ),
      BODependent(
        File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild.o'), // TODO: should be .obj on MSVC
        File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild.c'),
        CompileObject(C, {
          defines: libraryOptions.defines,
          includePaths: libraryOptions.includePaths,
        })
      ),
      BODependent(
        File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild'),
        File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild.o'),
        LinkExecutable(C, {
          defines: libraryOptions.defines,
          libraryPaths: libraryOptions.libraryPaths, // unnecessary?
          libraries: [],
          linkName: null,
        })
      ),
      BOAlways(
        File(""),
        Command('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild', [], (code, process) -> {
          code == 0 || throw 0;
          ret = process.stdout.readAll().toString();
        })
      ),
    ]));
    return ret;
  }

  public function finalise():Void {
    Ammer.libraries.active.remove(this);

    if (prebuild.length > 0) {
      // var program = new ammer.core.utils.LineBuf();
      // program
      //   .ail("int main() {}");
      // Ammer.builder.build(new ammer.core.BuildProgram([
      //   BOAlways(File('${Ammer.baseConfig.buildPath}/ammer_${name}'), EnsureDirectory),
      //   BOAlways(
      //     File('${Ammer.baseConfig.buildPath}/ammer_${name}/prebuild.c'),
      //     WriteContent(program.done())
      //   ),
      // ]));
    }

    // the latest version is always generated, older ones can be generated on
    // demand by baked libraries using defines
    //if (Context.defined("ammer_baked_v1_needed")) { infoVX = ... }
    infoV1 = info;
    done = true;
    Ammer.platform.addLibrary(library);
  }

  public function toString():String {
    return 'LibContext($name)';
  }
}

#end
