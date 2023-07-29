package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import ammer.core.utils.LineBuf;

using Lambda;
using StringTools;

// TODO: haxelib.json (extraParams for `--macro`)

class Bakery {
  public static final BAKE_PREFIX = "// ammer-bake: ";
  static var ammerRootPath:String = {
    var path = haxe.macro.PositionTools.getInfos((macro 0).pos).file;
    if (!Path.isAbsolute(path)) {
      path = Path.join([Sys.getCwd(), path]);
    }
    Path.normalize(Path.directory(Path.normalize(path)) + "/../");
  };

  public static var isBaking = false;
  public static var mainType:Type;
  static var bakeOutput:String;
  static var rootToBin:String;
  static var fileSources:Array<ammer.internal.v1.LibInfo.LibInfoFileSource>;

  static var downloadURL:Null<String>;
  static var description:Null<String>;
  static var os:Null<String>;
  static var architectures:Null<Array<String>>;
  static var minVersion:Null<String>;
  static var maxVersion:Null<String>;

  public static function init():Void {
    if (isBaking) return;
    if (!Config.getBool("ammer.bake", false)) return;
    isBaking = true;

    var mainTypeStr = Config.getString("ammer.bake.mainType", null, true);
    var mainTypePack = mainTypeStr.split(".");
    mainType = Context.resolveType(TPath({
      // TODO: support subtypes? merge somehow with Utils.complexTypeExpr?
      name: mainTypePack.pop(),
      pack: mainTypePack,
    }), Context.currentPos());

    bakeOutput = Config.getPath("ammer.bake.output", null, true);
    rootToBin = Config.getString("ammer.bake.rootToBin", null, true);
    var sourceCtr = 0;
    fileSources = [ while (true) {
      var prefix = 'ammer.bake.fileSource.${sourceCtr++}';
      var anyData = false;
      inline function c<T>(x: Null<T>):Null<T> {
        if (x != null) anyData = true;
        return x;
      }
      var source:ammer.internal.v1.LibInfo.LibInfoFileSource = {
        name: c(Config.getString('$prefix.name', null)),
        downloadFrom: c(Config.getString('$prefix.downloadFrom', null)),
        description: c(Config.getString('$prefix.description', null)),
        os: c(Config.getString('$prefix.os', null)),
        architectures: c(Config.getStringArray('$prefix.architectures', ",", null)),
        minVersion: c(Config.getString('$prefix.minVersion', null)),
        maxVersion: c(Config.getString('$prefix.maxVersion', null)),
      };
      if (!anyData) break;
      source;
    } ];

    Context.onAfterTyping(writeFiles);
  }

  static function writeFiles(_):Void {
    FileSystem.createDirectory(bakeOutput);
    var printer = new Printer("  ");
    var modules = BakeryOutput.withBufs();

    var extraParams:String;
    var targetId:String;
    var targetCondition:String;
    var targetDescription:String;
    switch (Ammer.platform.kind) {
      case Cpp:
        extraParams = "cpp";
        targetId = "cpp";
        targetCondition = 'Context.definedValue("target.name") == "cpp"';
        targetDescription = "Haxe/C++";
      case Cs:
        extraParams = "cs";
        targetId = "cs";
        targetCondition = 'Context.definedValue("target.name") == "cs"';
        targetDescription = "Haxe/C#";
      case Eval:
        extraParams = "eval";
        targetId = "eval";
        targetCondition = 'Context.definedValue("target.name") == "eval"';
        targetDescription = "Haxe interpreter";
      case Hashlink:
        // var platformConfig = (cast Ammer.platformConfig : ammer.core.plat.Hashlink.HashlinkConfig);
        // TODO: HL/C?
        extraParams = "hl";
        targetId = "hl";
        targetCondition = 'Context.definedValue("target.name") == "hl"';
        targetDescription = "Haxe/HashLink";
      case Java:
        // var platformConfig = (cast Ammer.platformConfig : ammer.core.plat.Java.JavaConfig);
        // TODO: JVM?
        extraParams = "java";
        targetId = "java";
        targetCondition = 'Context.definedValue("target.name") == "java"';
        targetDescription = "Haxe/Java";
      case Lua:
        extraParams = "lua";
        targetId = "lua";
        targetCondition = 'Context.definedValue("target.name") == "lua"';
        targetDescription = "Haxe/Lua";
      case Neko:
        extraParams = "neko";
        targetId = "neko";
        targetCondition = 'Context.definedValue("target.name") == "neko"';
        targetDescription = "Haxe/Neko";
      case Nodejs:
        extraParams = "js && nodejs";
        targetId = "nodejs";
        targetCondition = 'Context.definedValue("target.name") == "js" && Context.defined("nodejs")';
        targetDescription = "Haxe/Node.js";
      case Python:
        extraParams = "python";
        targetId = "python";
        targetCondition = 'Context.definedValue("target.name") == "python"';
        targetDescription = "Haxe/Python";
      case None: Context.fatalError("cannot bake without selecting platform", Context.currentPos());
    }

    // TODO: use as fragment in AmmerBaked?
    var osName = (switch (Sys.systemName()) {
      case "Windows": "win";
      case "Linux": "linux";
      case "BSD": "bsd";
      case "Mac": "mac";
      case _: "unknown"; // TODO: throw?
    });
    var extensionDll = (switch (Sys.systemName()) {
      case "Windows": "dll";
      case "Mac": "dylib";
      case _: "so";
    });
    var prefixLib = (switch (Sys.systemName()) {
      case "Windows": "";
      case _: "lib";
    });

    for (t in Utils.modifiedTypes) {
      switch (t.t.kind) {
        case KAbstractImpl(_.get() => abs):
          var typeId = Utils.typeId(abs);
          var output = modules.outputSub(abs.pack, abs.module.split(".").pop(), abs.name);
          output
            .ail("#if !macro");
          var isEnum = false;
          for (meta in t.t.meta.get()) {
            if (meta.name == ":build" || meta.name == ":autoBuild")
              continue;
            if (meta.name.startsWith(":ammer."))
              continue;
            if (meta.name == ":enum") {
              isEnum = true;
              continue;
            }
            output.ail(printer.printMetadata(meta));
          }
          output
            .ai('${isEnum ? "enum " : ""}abstract ${abs.name}(${printer.printComplexType(TypeTools.toComplexType(abs.type))})')
            .map(abs.from, t -> t.field == null ? ' from ${printer.printComplexType(TypeTools.toComplexType(t.t))}' : "")
            .map(abs.to, t -> t.field == null ? ' to ${printer.printComplexType(TypeTools.toComplexType(t.t))}' : "")
            .al(' {')
            .lmap(t.fields, field -> printer.printField(field) + ";")
            .ail("}")
            .ail("#end /*!macro*/");
        case KNormal:
          var typeId = Utils.typeId(t.t);
          var isLibrary = Ammer.libraries.byTypeId.exists(typeId);
          var output = modules.outputSub(t.t.pack, t.t.module.split(".").pop(), t.t.name);
          output
            .ail("#if !macro");
          for (meta in t.t.meta.get()) {
            if (meta.name == ":build" || meta.name == ":autoBuild")
              continue;
            if (meta.name.startsWith(":ammer."))
              continue;
            output.ail(printer.printMetadata(meta));
          }
          output
            .ail('${t.t.isExtern ? "extern " : ""}class ${t.t.name} {')
            .lmap(t.fields, field -> printer.printField(field) + ";")
            .ail("}")
            .ail("#end /*!macro*/");

          if (isLibrary) {
            var outputMacro = modules.outputSub(t.t.pack, t.t.module.split(".").pop() + ".macro", t.t.name);
            var ctx = Ammer.libraries.byTypeId[typeId];
            var targetScript = "";
            if (Ammer.platform.kind == Cpp) {
              var extc = ctx.libraryOptions.language.extension();
              var exth = ctx.libraryOptions.language.extensionHeader();
              targetScript = new LineBuf()
                .ail('var outputPath = haxe.macro.Compiler.getOutput();')
                .ail('sys.FileSystem.createDirectory(outputPath + "/ammer_build/ammer_${ctx.name}");')
                .ail('var herePath = haxe.macro.PositionTools.getInfos(info.herePos).file;')
                .ail('if (!haxe.io.Path.isAbsolute(herePath)) herePath = haxe.io.Path.join([Sys.getCwd(), herePath]);')
                .ail('herePath = haxe.io.Path.normalize(haxe.io.Path.directory(herePath));')
                .ail('sys.io.File.copy(herePath + "/lib.${ctx.name}.cpp_static.$extc", outputPath + "/ammer_build/ammer_${ctx.name}/lib.cpp_static.$extc");')
                .ail('sys.io.File.copy(herePath + "/lib.${ctx.name}.cpp_static.$exth", outputPath + "/ammer_build/ammer_${ctx.name}/lib.cpp_static.$exth");')
                .done();
            }

            if (typeId != "ammer.internal.LibTypes.LibTypes") {
              function sortedKeys<T>(map:Map<String, T>):Array<String> {
                var keys = [ for (k in map.keys()) k ];
                keys.sort(Reflect.compare);
                return keys;
              }
              var sortedArrayNames = sortedKeys(ctx.info.arrays.byElementTypeId);
              var sortedBoxNames = sortedKeys(ctx.info.boxes.byElementTypeId);
              var sortedCallbackNames = sortedKeys(ctx.info.callbacks.byElementTypeId);
              var sortedEnumNames = sortedKeys(ctx.info.enums);
              var sortedHaxeRefNames = sortedKeys(ctx.info.haxeRefs.byElementTypeId);
              var sortedOpaqueNames = sortedKeys(ctx.info.opaques);
              var sortedStructNames = sortedKeys(ctx.info.structs);
              var sortedSublibraryNames = sortedKeys(ctx.info.sublibraries);

              // TODO: share this with ammer-core somehow? or else make outputPathRelative private again
              //var outputPathRelative = ctx.library.outputPathRelative();
              //var sourcePath = 'prebuilt-$$osName-$targetId.bin';
              var destPath = (switch (Ammer.platform.kind) {
                // C++ (static) does not put the glue code into a dynamic lib.
                case Cpp: null;

                case Cs: 'ammer_${ctx.name}.dll';
                case Hashlink: 'ammer_${ctx.name}.hdll'; // TODO: HL/C uses the standard DLL naming
                case Neko: 'ammer_${ctx.name}.ndll';
                case Nodejs: 'ammer_${ctx.name}.node';
                case Python: 'ammer_${ctx.name}.$${osName == "win" ? "pyd" : "so"}';
                case _: '$${prefixLib}ammer_${ctx.name}.$${extensionDll}';
              });
              //var outputPathRelative = Ammer.baseConfig.outputPath + "/" + destPath;

              function printString(s:String):String {
                // not quote safe!
                return s == null ? "null" : '"$s"';
              }
              function printStringArray(s:Array<String>):String {
                return s == null ? "null" : '[${s.map(printString).join(", ")}]';
              }
              function printExpr(e:Expr):String {
                return e == null ? "null" : '(macro ${printer.printExpr(e)})';
              }
              function printCt(ct:ComplexType):String {
                return '(macro : ${printer.printComplexType(ct)})';
              }
              /*function printType(t:Type):String {
                return 'ComplexTypeTools.toType((macro : ${printer.printComplexType(TypeTools.toComplexType(t))}))';
              }*/

              outputMacro.a(
                File.getContent('$ammerRootPath/internal/v1/AmmerSetup.baked.hx')
                  .replace("/*libname*/", '${t.t.module.split(".").pop()}_${t.t.name}')
                  .replace("/*libinfo*/", new LineBuf()
                      .al("// ammer-bake-common")
                      .ail('/*ammer-bake-common-start*/ if ($targetCondition) {').i()
                        .ail(targetScript)
                        .ail('info.name = "${ctx.name}";')
                        .ail('info.arrays.byElementTypeId = [').i()
                          .lmap(sortedArrayNames, name -> {
                            var info = ctx.info.arrays.byElementTypeId[name];
                            '"$name" => {\n' +
                              'arrayCt: ${printCt(info.arrayCt)},\n' +
                              'arrayRefCt: ${printCt(info.arrayRefCt)},\n' +
                              'alloc: ${printExpr(info.alloc)},\n' +
                              'fromHaxeCopy: ${printExpr(info.fromHaxeCopy)},\n' +
                              'fromHaxeRef: ${printExpr(info.fromHaxeRef)},\n' +
                            '},';
                          })
                        .d().ail('];')
                        .ail('info.boxes.byElementTypeId = [').i()
                          .lmap(sortedBoxNames, name -> {
                            var info = ctx.info.boxes.byElementTypeId[name];
                            '"$name" => {\n' +
                              'boxCt: ${printCt(info.boxCt)},\n' +
                              'alloc: ${printExpr(info.alloc)},\n' +
                            '},';
                          })
                        .d().ail('];')
                        .ail('info.callbacks.byElementTypeId = [').i()
                          .lmap(sortedCallbackNames, name -> {
                            var info = ctx.info.callbacks.byElementTypeId[name];
                            '"$name" => {\n' +
                              'isGlobal: ${info.isGlobal},\n' +
                              'callbackCt: ${printCt(info.callbackCt)},\n' +
                              'funCt: ${printCt(info.funCt)},\n' +
                              'callbackName: ${printString(info.callbackName)},\n' +
                            '},';
                          })
                        .d().ail('];')
                        .ail('info.enums = [').i()
                          .lmap(sortedEnumNames, name -> {
                            var info = ctx.info.enums[name];
                            '"$name" => {},\n';
                          })
                        .d().ail('];')
                        .ail('info.haxeRefs.byElementTypeId = [').i()
                          .lmap(sortedHaxeRefNames, name -> {
                            var info = ctx.info.haxeRefs.byElementTypeId[name];
                            '"$name" => {' +
                              'create: ${printExpr(info.create)},\n' +
                            '},\n';
                          })
                        .d().ail('];')
                        .ail('info.opaques = [').i()
                          .lmap(sortedOpaqueNames, name -> {
                            var info = ctx.info.opaques[name];
                            '"$name" => {\n' +
                              'opaqueName: "${info.opaqueName}",\n' +
                            '},';
                          })
                        .d().ail('];')
                        .ail('info.structs = [').i()
                          .lmap(sortedStructNames, name -> {
                            var info = ctx.info.structs[name];
                            '"$name" => {\n' +
                              'alloc: ${info.alloc},\n' +
                              'gen: {\n' +
                                'alloc: ${printString(info.gen.alloc)},\n' +
                                'free: ${printString(info.gen.free)},\n' +
                                'nullPtr: ${printString(info.gen.nullPtr)},\n' +
                              '},\n' +
                              'structName: "${info.structName}",\n' +
                            '},';
                          })
                        .d().ail('];')
                        .ail('info.sublibraries = [').i()
                          .lmap(sortedSublibraryNames, name -> {
                            var info = ctx.info.sublibraries[name];
                            '"$name" => {},';
                          })
                        .d().ail('];')
                        .ail('info.setupToBin = "${t.t.pack.map(_ -> "..").concat(rootToBin.split("/")).join("/")}";')
                        .ifi(destPath != null)
                          .ail("info.files.push({").i()
                            .ail('dst: \'$destPath\',')
                            .ail("sources: [").i()
                              .map(fileSources, source -> new LineBuf().ail("{").i()
                                .ail('name: ${printString(source.name)},')
                                //.ail('digest: ${printString(haxe.crypto.Sha256.make(File.getBytes('$bakeOutput/$rootToBin/${extensions(outputPathRelative)}')).toHex())},')
                                .ail('description: "pre-compiled library for $targetDescription",')
                                .ail('downloadFrom: ${printString(source.downloadFrom)},')
                                .ail('os: ${printString(source.os)},')
                                .ail('architectures: ${printStringArray(source.architectures)},')
                                .ail('minVersion: ${printString(source.minVersion)},')
                                .ail('maxVersion: ${printString(source.maxVersion)},')
                                .d().ail("},").done())
                            .d().ail("],")
                          .d().ail("});")
                        .ifd()
                      .d().ail("/*ammer-bake-common-end*/ }")
                    .done())
              );
            }
            outputMacro.al('class ${t.t.name} {}');
          }
        case _: throw 0;
      }
    }
    for (t in ammer.core.utils.TypeUtils.definedTypes) {
      var extraMeta = [];
      t.meta = [ for (meta in t.meta) {
        if (meta.name == ":buildXml") switch (meta.params) {
          case [{expr: EConst(CString(val))}] if (val.startsWith("<!--ammer_core_paths:ammer_")):
            var libname = val.substr("<!--ammer_core_paths:ammer_".length).split("-->")[0];
            var ctx = Ammer.libraries.byLibraryName[libname];
            ctx != null || throw 0;
            var includePaths = ctx.originalOptions.includePaths.map(p -> macro $v{p.rel});
            var libraryPaths = ctx.originalOptions.libraryPaths.map(p -> macro $v{p.rel});
            var includePathsArr = macro $a{includePaths};
            var libraryPathsArr = macro $a{libraryPaths};
            extraMeta.push({
              name: ":build",
              params: [macro ammer.internal.v1.RelativePathsHelper.build($includePathsArr, $libraryPathsArr)],
              pos: meta.pos,
            });
            continue;
          case _:
        }
        meta;
      } ];
      t.meta = t.meta.concat(extraMeta);
      modules.outputSub(t.pack, t.name, t.name)
        .ail(printer.printTypeDefinition(t, false));
    }
    for (t in Utils.definedTypes) {
      modules.outputSub(t.pack, t.name, t.name)
        .ail(printer.printTypeDefinition(t, false));
    }

    modules.outputCombined(extraParams, bakeOutput);

    // TODO: paths (handle backslashes etc on Windows)
    // This is a little "preprocessor" system to reduce code duplication.
    // It isn't great!
    FileSystem.createDirectory('$bakeOutput/ammer/internal/v1');
    for (req in [
      ["internal/v1/AmmerBaked.hx", "internal/v1/AmmerBaked.hx"],
      ["internal/v1/LibInfo.hx", "internal/v1/LibInfo.hx"],
      ["internal/v1/OsInfo.hx", "internal/v1/OsInfo.hx"],
      ["internal/v1/RelativePathsHelper.hx", "internal/v1/RelativePathsHelper.hx"],
      ["Lib.hx", "Lib.hx"],
      ["Lib.macro.baked.hx", "Lib.macro.hx"],
      ["internal/FilePtrOutput.hx", "internal/FilePtrOutput.hx"],
    ]) {
      var content = File.getContent('$ammerRootPath/${req[0]}')
        .split("\n")
        .map(l -> {
          var lt = l.trim();
          if (!lt.startsWith("// ammer-include: ")) return l;
          var params = lt.substr("// ammer-include: ".length).split(" ");
          var refContent = File.getContent('$ammerRootPath/${params[0]}');
          var spl = refContent.split('// ammer-fragment-begin: ${params[1]}');
          spl.length == 2 || throw 'expected fragment begin ${params[1]} in ${params[0]}';
          spl = spl[1].split('// ammer-fragment-end: ${params[1]}');
          spl.length == 2 || throw 'expected fragment end ${params[1]} in ${params[0]}';
          spl[0];
        })
        .join("\n");
      File.saveContent('$bakeOutput/ammer/${req[1]}', content);
    }
  }

  public static function multiBake(platforms:Array<String>, output:String):Void {
    var modules = new BakeryOutput(
      () -> {
        platforms: ([] : Map<String, String>),
        common: ([] : Array<String>),
      },
      mod -> {
        var platNames = [ for (k in mod.platforms.keys()) k ];
        platNames.sort(Reflect.compare);
        var merged = new LineBuf();
        for (p in platNames) {
          merged
            .al('#if (${p})')
            .al(mod.platforms[p]
              .replace("// ammer-bake-common", mod.common.join("\n")))
            .al('#end /*(${p})*/');
        }
        merged.done();
      }
    );

    function walkPath(base:String, ext:String):Void {
      var path = '$base$ext';
      if (FileSystem.isDirectory(path)) {
        FileSystem.readDirectory(path).iter(f -> {
          if (f.startsWith(".")) return;
          walkPath(base, '$ext/$f');
        });
      } else {
        if (!path.endsWith(".hx")) return;
        var content = File.getContent(path);
        if (!content.startsWith(BAKE_PREFIX))
          throw Context.fatalError('unexpected file in bake path: $path', Context.currentPos());
        var lines = content.split("\n");
        var bakeParams = lines[0].substr(BAKE_PREFIX.length).split(" ");

        var bakePack = bakeParams[0].split(".");
        var bakeModule = bakeParams[1];
        var bakeExtra = bakeParams.slice(2).join(" ");
        if (path.endsWith(".macro.hx")) bakeExtra = "true"; // join macro files

        var content = [];
        var bakeCommon = [];
        var isCommon = false;
        for (lnum => line in lines) {
          if (line.contains("/*ammer-bake-common-start*/")) isCommon = true;
          if (isCommon) bakeCommon.push(line);
          else if (lnum >= 2) {
            // remove bake prefix, package, and common lines (will be merged later)
            content.push(line);
          }
          if (line.contains("/*ammer-bake-common-end*/")) isCommon = false;
        }

        var outputSub = modules.outputSub(bakePack, bakeModule, "true");
        outputSub.platforms[bakeExtra] = content.join("\n");
        outputSub.common = outputSub.common.concat(bakeCommon);
      }
    }
    platforms.iter(p -> walkPath(p, ""));

    modules.outputCombined("combined", output);
  }
}

class BakeryOutput<T> {
  public static function withBufs():BakeryOutput<LineBuf> {
    return new BakeryOutput(() -> new LineBuf(), buf -> buf.done());
  }

  var modules:Map<String, Map<String, T>> = [];
  var create:()->T;
  var finish:T->String;

  public function new(create:()->T, finish:T->String) {
    this.create = create;
    this.finish = finish;
  }

  public function outputSub(pack:Array<String>, module:String, sub:String):T {
    var mid = pack.concat([module]).join(".");
    if (!modules.exists(mid)) modules[mid] = new Map();
    if (!modules[mid].exists(sub)) modules[mid][sub] = create();
    return modules[mid][sub];
  }

  public function outputCombined(extraParams:String, outputPath:String):Void {
    for (module => types in modules) {
      var pack = module.split(".");
      var module = pack.pop();
      if (module == "macro") {
        module = '${pack.pop()}.$module';
      }
      var subNames = [ for (k in types.keys()) k ];
      subNames.sort(Reflect.compare);
      var moduleOutput = new LineBuf()
        .ail('${Bakery.BAKE_PREFIX}${pack.join(".")} $module $extraParams')
        .ail('package ${pack.join(".")};');
      for (subName in subNames) {
        moduleOutput.al(finish(types[subName]));
      }

      var out = outputPath + "/" + pack.join("/");
      FileSystem.createDirectory(out);
      File.saveContent('${out}/${module}.hx', moduleOutput.done());
    }
  }
}

#end
