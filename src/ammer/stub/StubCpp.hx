package ammer.stub;

import ammer.Config.AmmerLibraryConfig;

using ammer.FFITools;
using StringTools;

class StubCpp {
  static var library:AmmerLibraryConfig;
  static var lb:LineBuf;

  static function generateHeader():Void {
    for (header in library.headers)
      lb.a('#include <${header}>\n');
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateMethod(method:FFIMethod, ctx:AmmerContext):Void {
    lb.ai('${StubBaseC.mapTypeC(method.ret, "")} ${mapMethodName(method.uniqueName)}(');
    if (method.args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...method.args.length) StubBaseC.mapTypeC(method.args[i], 'arg_$i') ].join(", "));
    lb.a(")\n");
    lb.ai('#ifdef AMMER_CODE_${ctx.index}\n');
    lb.ai("{\n");
    lb.indent(() -> {
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      var call = '${method.native}(' + [ for (i in 0...method.args.length) 'arg_$i' ].join(", ") + ')';
      if (method.ret == Void)
        lb.ai("");
      else
        lb.ai("return ");
      if (method.cReturn != null)
        lb.a('${method.cReturn.replace("%CALL%", call)};\n');
      else
        lb.a('$call;\n');
    });
    lb.ai("}\n");
    lb.ai("#else\n");
    lb.ai(";\n");
    lb.ai("#endif\n");
  }

  public static function generate(config:Config, library:AmmerLibraryConfig):Void {
    StubCpp.library = library;
    lb = new LineBuf();
    generateHeader();
    lb.ai('extern "C" {\n');
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.uniqueName))
          continue; // TODO: make sure the field has the same signature
        generated[method.uniqueName] = true;
        generateMethod(method, ctx);
      }
    }
    lb.ai("}\n");
    Utils.update('${config.output}/ammer/ammer_${library.name}.cpp.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
