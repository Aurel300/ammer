#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class NativeGen {
  public static function deleteFields():Array<Field> {
    return [];
  }
  public static function generate():Void {
    var pos = Context.currentPos();
    function params(isConst:Array<Bool>):Array<haxe.macro.TypeParamDecl> {
      return [ for (i in 0...isConst.length) {
        name: 'T$i',
        meta: isConst[i] ? [{
          pos: pos,
          name: ":const",
        }] : [],
      } ];
    }
    Context.onTypeNotFound(rname -> {
      if (rname == "Single") return {
        name: rname,
        pack: [],
        kind: TDAlias((macro : Float)),
        fields: [],
        pos: pos,
      };
      var pack = rname.split(".");
      var name = pack.pop();
      if (pack.length > 0 && pack[0] == "ammer") {
        if (rname == "ammer.Syntax") {
          return {
            name: name,
            pack: pack,
            kind: TDClass(null, [], true, false, false),
            fields: [],
            pos: pos,
          };
        }
        if (pack[1] == "def") {
          return {
            name: name,
            pack: pack,
            params: (switch (rname) {
              case "ammer.def.Library": params([true]);
              case "ammer.def.Struct": params([true, false]);
              case "ammer.def.Sublibrary": params([false]);
              case _: [];
            }),
            kind: TDClass(null, [], false, false, false),
            meta: [{
              name: ":autoBuild",
              params: [macro NativeGen.deleteFields()],
              pos: pos,
            }],
            fields: [],
            pos: pos,
          };
        }
        return {
          name: name,
          pack: pack,
          params: [],
          kind: TDClass(null, [], false, false, false),
          fields: [],
          pos: pos,
        };
      }
      return null;
    });
    for (test in FileSystem.readDirectory("../src/test")) {
      if (test.startsWith(".") || !test.endsWith(".hx")) continue;
      Context.resolveType(TPath({
        name: test.substr(0, test.length - 3),
        pack: ["test"],
      }), pos);
    }
    Context.onAfterTyping(types -> {
      var outputs:Map<String, Map<String, String>> = [];
      for (common in FileSystem.readDirectory("common-header")) {
        outputs[common] = ["(HEADER)" => File.getContent('common-header/$common')];
      }
      for (t in types) switch (t) {
        case TClassDecl(_.get() => cls = { pack: ["test"], name: _.startsWith("Test") => true }):
          for (code in cls.meta.extract(":ammertest.code")) switch (code.params) {
            case [{expr: EConst(CString(output))}, {expr: EMeta(_, {expr: EConst(CString(code))})}]:
              code.startsWith("<x>") || throw 0;
              code = code.substr("<x>".length);
              code.endsWith("</x>") || throw 0;
              code = code.substr(0, code.length - "</x>".length);
              if (!outputs.exists(output)) outputs[output] = new Map();
              var typeId = cls.pack.concat([cls.name]).join(".");
              outputs[output][typeId] = '// $typeId\n$code';
            case _: throw 0;
          }
        case _:
      }
      for (common in FileSystem.readDirectory("common-footer")) {
        outputs[common]["(FOOTER)"] = File.getContent('common-footer/$common');
      }
      var sortedOutputs = [ for (k in outputs.keys()) k ];
      sortedOutputs.sort(Reflect.compare);
      for (output in sortedOutputs) {
        var codes = outputs[output];
        var merged = new StringBuf();
        var sortedKeys = [ for (k in codes.keys()) k ];
        sortedKeys.sort((a, b) ->
          a == "(HEADER)" ? -1 :
          a == "(FOOTER)" ? 1 :
          b == "(HEADER)" ? 1 :
          b == "(FOOTER)" ? -1 : Reflect.compare(a, b));
        for (k in sortedKeys) {
          merged.add(codes[k]);
        }
        Sys.println('$output ... ${sortedKeys.length}');
        File.saveContent('../native-src/$output', merged.toString());
      }
    });
  }
}

#end
