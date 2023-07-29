// ammer-bake: ammer.internal.v1 RelativePathsHelper true
package ammer.internal.v1;

#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.io.Path;

using StringTools;

class RelativePathsHelper {
  public static function build(includePaths:Array<String>, libraryPaths:Array<String>):Array<Field> {
    if (includePaths.length == 0 && libraryPaths.length == 0) return null;

    var cls = Context.getLocalClass().get();

    var outputPath = Compiler.getOutput();
    var rootPath = PositionTools.getInfos(cls.pos).file;
    if (!Path.isAbsolute(rootPath)) rootPath = Path.join([Sys.getCwd(), rootPath]);
    rootPath = Path.normalize(Path.directory(rootPath) + "/" + cls.pack.map(_ -> "../").join(""));
    var xml = '<files id="haxe">'
        + includePaths.map(path -> '<compilerflag value="-I$rootPath/$path"/>').join("")
      + '</files><target id="haxe">'
        + libraryPaths.map(path -> '<libpath name="$rootPath/$path"/>').join("")
      + '</target>';

    cls.meta.add(":buildXml", [macro $v{xml}], cls.pos);
    return null;
  }
}

#end
