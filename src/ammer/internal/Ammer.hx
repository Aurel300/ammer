package ammer.internal;

#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

using StringTools;

typedef AmmerConfig = {
  buildPath:String,
  outputPath:String,
};

typedef QueuedSubtype = {
  subId:String,
  lib:Type,
  pos:Position,
  process:(ctx:LibContext)->Any,
  result:Null<Any>,
  done:Bool,
  prev:Null<QueuedSubtype>,
  next:Null<QueuedSubtype>,
};

class Ammer {
  public static var baseConfig(get, never):AmmerConfig;
  public static var builder(get, never):ammer.core.Builder;
  public static var platform(get, never):ammer.core.Platform;
  public static var platformConfig(default, null):ammer.core.plat.BaseConfig;

  public static var mergedInfo = new ammer.internal.v1.LibInfo();
  public static var libraries:{
    byLibraryName:Map<String, LibContext>,
    byTypeId:Map<String, LibContext>,
    active:Array<LibContext>,
  } = {
    byLibraryName: [],
    byTypeId: [],
    active: [],
  };

  static var queuedSubtypes:{
    first:QueuedSubtype,
    last:QueuedSubtype,
  } = {
    first: null,
    last: null,
  };
  static function enqueueSubtype(s:QueuedSubtype):Void {
    s.prev == null || throw 0;
    s.next == null || throw 0;
    if (queuedSubtypes.last == null) {
      queuedSubtypes.first == null || throw 0;
      queuedSubtypes.first = s;
      queuedSubtypes.last = s;
      return;
    }
    queuedSubtypes.first != null || throw 0;
    queuedSubtypes.last.next == null || throw 0;
    s.prev = queuedSubtypes.last;
    queuedSubtypes.last.next = s;
    queuedSubtypes.last = s;
  }
  static function dequeueSubtype(s:QueuedSubtype):Void {
    if (s.prev == null) {
      queuedSubtypes.first = s.next;
    } else {
      s.prev.next = s.next;
    }
    if (s.next == null) {
      queuedSubtypes.last = s.prev;
    } else {
      s.next.prev = s.prev;
    }
  }

  static var baseConfigL:AmmerConfig;
  static var builderL:ammer.core.Builder;
  static var platformL:ammer.core.Platform;

  static function get_baseConfig():AmmerConfig {
    if (baseConfigL != null)
      return baseConfigL;
    return baseConfigL = {
      buildPath: Config.getPath("ammer.buildPath", null, true),
      outputPath: Config.getPath("ammer.outputPath", null, true),
    };
  }

  static function get_builder():ammer.core.Builder {
    if (builderL != null)
      return builderL;

    // TODO: allow selection of toolchain, configuration, etc
    return ammer.core.Builder.createCurrentBuilder(({} : ammer.core.build.BaseBuilderConfig));
  }

  static function get_platform():ammer.core.Platform {
    if (platformL != null)
      return platformL;

    Bakery.init();

    function getPaths(key:String):Array<String> {
      var paths = Config.getStringArray(key, ";");
      if (paths == null) return [];
      return paths.filter(v -> v != "");
    }
    platformConfig = (switch (Context.definedValue("target.name")) {
      case "cpp": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          staticLink: Config.getBool("ammer.cpp.staticLink", false),
        } : ammer.core.plat.Cpp.CppConfig);
      case "cs": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
        } : ammer.core.plat.Cs.CsConfig);
      // TODO: eval?
      case "hl": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          hlc: Config.getBool("ammer.hl.hlc", !Compiler.getOutput().endsWith(".hl")),
          hlIncludePaths: getPaths("ammer.hl.includePaths"),
          hlLibraryPaths: getPaths("ammer.hl.libraryPaths"),
        } : ammer.core.plat.Hashlink.HashlinkConfig);
      case "java": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          javaIncludePaths: getPaths("ammer.java.includePaths"),
          javaLibraryPaths: getPaths("ammer.java.libraryPaths"),
        } : ammer.core.plat.Java.JavaConfig);
      case "lua": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          luaIncludePaths: getPaths("ammer.lua.includePaths"),
          luaLibraryPaths: getPaths("ammer.lua.libraryPaths"),
        } : ammer.core.plat.Lua.LuaConfig);
      case "neko": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          nekoIncludePaths: getPaths("ammer.neko.includePaths"),
          nekoLibraryPaths: getPaths("ammer.neko.libraryPaths"),
        } : ammer.core.plat.Neko.NekoConfig);
      case "js": ({
          // TODO: (once implemented,) choose JS build system
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          nodeGypBinary: Config.getString("ammer.js.nodeGypBinary", "node-gyp"),
        } : ammer.core.plat.Nodejs.NodejsConfig);
      case "python": ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
          pythonVersionMinor: Config.getInt("ammer.python.version", 8),
          pythonIncludePaths: getPaths("ammer.python.includePaths"),
          pythonLibraryPaths: getPaths("ammer.python.libraryPaths"),
        } : ammer.core.plat.Python.PythonConfig);

      case _: ({
          buildPath: baseConfig.buildPath,
          outputPath: baseConfig.outputPath,
        } : ammer.core.plat.None.NoneConfig);
    });

    platformL = ammer.core.Platform.createCurrentPlatform(platformConfig);
    Context.onAfterTyping(_ -> {
      var program = platformL.finalise();
      builder.build(program);
    });
    return platformL;
  }

  public static function registerBakedLibraryV1(info:ammer.internal.v1.LibInfo):Void {
    // TODO: also detect duplicate library names (add to libraries.byLibraryName ?)
    Reporting.withCurrentPos(() -> {
      final fail = Reporting.error;
// ammer-fragment-begin: register-v1
      // detect local path
      var path = PositionTools.getInfos(info.herePos).file;
      if (!Path.isAbsolute(path)) {
        path = Path.join([Sys.getCwd(), path]);
      }
      path = Path.normalize(Path.directory(path));
      var binaryPath = Path.normalize(path + "/" + info.setupToBin);

      if (true) { //if (Context.defined('${info.name}_copy_binary')) {
        var outputPath = Context.definedValue("ammer.outputPath");
        outputPath != null || throw fail("missing required define: ammer.outputPath");
        FileSystem.createDirectory(outputPath);
        for (file in info.files) {
          var dst = file.dst;
          var dstFull = Path.normalize(Path.join([outputPath, dst]));

          var dstExists = FileSystem.exists(dstFull);
          if (dstExists) {
            !FileSystem.isDirectory(dstFull) || throw fail('$dst exists but is a directory');
            if (true) continue;
            /*
            // TODO: skip if configured (when running ammer proper?)
            var digest = haxe.crypto.Sha256.make(File.getBytes(dstFull)).toHex();
            if (digest == file.digest) {
              continue;
            } else {
              Sys.println('[ammer] $dst found with different contents (possibly an older version)');
            }*/
          }

          // at this point, either the required file does not exist
          // or its digest does not match what we expect (currently disabled)
          // -> look for a source

          var sourcesSkipped = [];
          var sourcesAvailableLocally = [];
          var sourcesAvailableOnline = [];

          for (source in file.sources) {
            // skip sources which are not compatible with the current OS
            var compatible = true;
            if (source.os != null) {
              var osInfo = ammer.internal.v1.OsInfo.info;
              if (source.os != osInfo.os) compatible = false;
              if (compatible && osInfo.architecture != null) {
                if (source.architectures != null
                  && !source.architectures.contains(osInfo.architecture)) compatible = false;
              }
              if (compatible && osInfo.version != null) {
                if (source.minVersion != null
                  && osInfo.versionCompare(osInfo.version, source.minVersion) < 0) compatible = false;
                if (source.maxVersion != null
                  && osInfo.versionCompare(osInfo.version, source.maxVersion) > 0) compatible = false;
              }
            }
            if (!compatible) {
              sourcesSkipped.push(source);
              continue;
            }

            var srcFull = Path.normalize(Path.join([binaryPath, source.name]));
            if (FileSystem.exists(srcFull)) {
              sourcesAvailableLocally.push(source);
              continue;
            }

            if (source.downloadFrom != null) {
              sourcesAvailableOnline.push(source);
              continue;
            }

            sourcesSkipped.push(source);
          }

          // exactly one locally available, compatible source: copy it
          if (!dstExists && sourcesAvailableLocally.length == 1) {
            var source = sourcesAvailableLocally[0];
            var srcFull = Path.normalize(Path.join([binaryPath, source.name]));
            Sys.println('[ammer] copying $srcFull -> $dstFull');
            File.copy(srcFull, dstFull);
            continue;
          }

          // at this point, we will prompt the user to choose an action, either
          // because there are multiple locally available, compatible sources,
          // or because a source will need to be downloaded

          Sys.println('[ammer] required file $dst not found for library ${info.name}');
          Sys.println("  options (press a key):");

          var options = new Map();
          function option(char:Int, text:String, f:()->Void):Void {
            Sys.println('  [${String.fromCharCode(char)}] $text');
            options[char] = f;
          }
          var yeses = "y0123456789".split("");
          function optionYes(text:String, f:()->Void):Void {
            if (yeses.length == 0) {
              Sys.println('  [ ] (too many options...) $text');
            } else {
              var cc = yeses.shift().charCodeAt(0);
              option(cc, text, f);
            }
          }

          function describe(source:ammer.internal.v1.LibInfo.LibInfoFileSource, online:Bool):String {
            var infos = [];
            if (online && source.downloadFrom != null) infos.push('URL: ${source.downloadFrom}');
            if (source.os != null) infos.push('OS: ${source.os}');
            if (source.minVersion != null) infos.push('OS version >= ${source.minVersion}');
            if (source.maxVersion != null) infos.push('OS version <= ${source.maxVersion}');
            if (source.architectures != null) infos.push('arch: ${source.architectures.join("/")}');
            if (infos.length == 0) return source.description;
            return '${source.description} (${infos.join(", ")})';
          }

          var choiceDone = false;
          var doDownload = null;
          var doCopy = null;
          if (dstExists) {
            for (source in sourcesAvailableLocally) {
              optionYes('override file using: ${describe(source, false)}', () -> {
                doCopy = source;
              });
            }
            for (source in sourcesAvailableOnline) {
              optionYes('download file now and override using: ${describe(source, true)}', () -> {
                doDownload = source;
                doCopy = source;
              });
            }
            option("s".code, "keep existing file", () -> {});
          } else {
            for (source in sourcesAvailableLocally) {
              optionYes('use: ${describe(source, false)}', () -> {
                doCopy = source;
              });
            }
            for (source in sourcesAvailableOnline) {
              optionYes('download file now: ${describe(source, true)}', () -> {
                doDownload = source;
                doCopy = source;
              });
            }
            if (sourcesAvailableLocally.length == 0 && sourcesAvailableOnline.length == 0) {
              Sys.println("  This file is not available online: you may need to compile it locally.");
              // TODO: add link to manual page (once it exists)
            }
            option("s".code, "ignore (program may not function correctly)", () -> {});
          }
          if (sourcesSkipped.length > 0) {
            option("i".code, 'show details of ${sourcesSkipped.length} skipped sources', () -> {
              for (source in sourcesSkipped) {
                Sys.println('      ${describe(source, true)}');
              }
              choiceDone = false;
            });
          }
          option("q".code, "abort compilation", () -> throw fail("aborting"));

          while (!choiceDone) {
            var choice = Sys.getChar(false);
            if (!options.exists(choice)) continue;
            choiceDone = true;
            options[choice]();
          }

          if (doDownload != null) {
            Sys.println("  downloading file ...");
            var url = doDownload.downloadFrom;
            var srcFull = Path.normalize(Path.join([binaryPath, doDownload.name]));
            var followed = 0;
            var downloaded = false;
            while (!downloaded) {
              var http = new haxe.Http(url);
              var done = false;
              var success = false;
              try {
                var status = "999";
                http.onBytes = (data) -> {
                  if (status.charAt(0) == "2") {
                    Sys.println("  file downloaded");
                    /*
                    var digest = haxe.crypto.Sha256.make(data).toHex();
                    if (digest != file.digest) {
                      Sys.println("  warning: file digest has changed (possibly a newer version)");
                    }
                    */
                    File.saveBytes(srcFull, data);
                    downloaded = true;
                    done = true;
                    success = true;
                  } else if (status.charAt(0) == "3") {
                    http.responseHeaders.exists("Location") || throw fail("redirect without Location header");
                    Sys.println("  following redirect ...");
                    url = http.responseHeaders["Location"];
                    done = true;
                    success = true;
                  }
                };
                http.onError = (msg) -> {
                  Sys.println('  download error: $msg');
                  done = true;
                  success = false;
                };
                http.onStatus = (s:Int) -> {
                  status = '$s';
                  Sys.println('  status: $status');
                  if (status.charAt(0) != "2" && status.charAt(0) != "3") {
                    done = true;
                    success = false;
                  }
                }
                http.request(false);
              } catch (ex:Dynamic) {
                Sys.println('  download error: $ex');
                done = true;
                success = false;
              }
              // TODO: timeout?
              while (!done) Sys.sleep(.25);
              if (!success) fail("download error");
              followed++;
              if (followed >= 5) fail("too many redirects");
            }
          }
          if (doCopy != null) {
            var srcFull = Path.normalize(Path.join([binaryPath, doCopy.name]));
            Sys.println('[ammer] copying $srcFull -> $dstFull');
            File.copy(srcFull, dstFull);
          }
        }
      }

      function extend<T>(target:Map<String, T>, source:Map<String, T>):Void {
        for (k => v in source) {
          if (target.exists(k)) throw fail("library replaces an existing type");
          target[k] = v;
        }
      }
      extend(mergedInfo.arrays.byTypeId, info.arrays.byTypeId);
      extend(mergedInfo.arrays.byElementTypeId, info.arrays.byElementTypeId);
      extend(mergedInfo.boxes.byTypeId, info.boxes.byTypeId);
      extend(mergedInfo.boxes.byElementTypeId, info.boxes.byElementTypeId);
      extend(mergedInfo.callbacks.byTypeId, info.callbacks.byTypeId);
      extend(mergedInfo.callbacks.byElementTypeId, info.callbacks.byElementTypeId);
      extend(mergedInfo.enums, info.enums);
      extend(mergedInfo.haxeRefs.byTypeId, info.haxeRefs.byTypeId);
      extend(mergedInfo.haxeRefs.byElementTypeId, info.haxeRefs.byElementTypeId);
      extend(mergedInfo.opaques, info.opaques);
      extend(mergedInfo.structs, info.structs);
      extend(mergedInfo.sublibraries, info.sublibraries);
// ammer-fragment-end: register-v1
    });
  }

  public static function initLibrary(lib:ClassType, name:String, options:LibContext.LibContextOptions):LibContext {
    if (libraries.byLibraryName.exists(name))
      throw Reporting.error('duplicate definition of library "$name"');

    var libId = Utils.typeId(lib);
    var ctx = new LibContext(name, options);
    ctx.isLibTypes = (libId == "ammer.internal.LibTypes.LibTypes");
    libraries.byLibraryName[name] = ctx;
    libraries.byTypeId[libId] = ctx;
    libraries.active.push(ctx);

    contextReady(lib, ctx);

    return ctx;
  }

  public static function contextReady(lib:ClassType, ctx:LibContext):Void {
    var libId = Utils.typeId(lib);
    var curr = queuedSubtypes.first;
    while (curr != null) {
      var currId = Utils.typeId2(curr.lib);
      if (Utils.typeId2(curr.lib) == libId) {
        dequeueSubtype(curr);
        curr.result = Reporting.withPosition(curr.pos, () -> curr.process(ctx));
        curr.done = true;
      }
      curr = curr.next;
    }
  }

  // TODO: support multiple libraries for a subtype
  public static function initSubtype<T>(
    subId:String,
    lib:Type,
    process:(ctx:LibContext)->T,
    ?processLibTypes:(ctx:LibContext)->T
  ):T {
    // enqueue deferred subtype processing
    var queued:QueuedSubtype = {
      subId: subId,
      lib: lib,
      pos: Reporting.currentPos(),
      process: process,
      result: null,
      done: false,
      prev: null,
      next: null,
    };
    enqueueSubtype(queued);

    // trigger typing of the library
    var ctx = Types.resolveContext(lib);
    ctx != null || {
      trace("could not resolve context", subId, lib);
      Context.fatalError("here", Context.currentPos());
      //throw 0;
    };

    if (queued.done) {
      return queued.result;
    }

    // if it was not processed, then either:
    // - the library is currently being processed, or
    // - the library has already finished processing

    if (!ctx.done) {
      // currently being processed
      dequeueSubtype(queued);
      return process(ctx);
    } else {
      if (ctx.isLibTypes && processLibTypes != null) {
        return processLibTypes(ctx);
      }

      // already processed, report missing subtype link
      // TODO: format types better
      Reporting.error(
        '$subId is declared as a subtype of library ${Utils.typeId2(lib)}, '
        + 'but the library was already fully processed. Please add a subtype '
        + 'link @:ammer.sub((_ : $subId)) to the library definition.');
      return null;
    }
  }
}

#end
