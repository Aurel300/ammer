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

  static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case Closure(_, _, _): '::Dynamic $name';
      case ClosureData(_): 'int $name';
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateClosureWrappers(ctx:AmmerContext):Void {
    for (i in 0...ctx.closureTypes.length) {
      lb.ai('#ifdef AMMER_CODE_${ctx.index}\n');
      var method = ctx.closureTypes[i];
      lb.ai('static ${mapTypeC(method.ret, "")} wc_${i}_${ctx.index}(');
      var userData = -1;
      lb.a([ for (i in 0...method.args.length) switch (method.args[i]) {
        case ClosureDataUse: userData = i; 'void *arg_$i';
        case _: mapTypeC(method.args[i], 'arg_$i');
      } ].filter(a -> a != null).join(", "));
      lb.a(") {\n");
      lb.indent(() -> {
        lb.ai('::Dynamic cl = ::Dynamic((hx::Object *)arg_$userData);\n');
        lb.ai("::hx::NativeAttach attach_gc;\n");
        if (method.ret == Void)
          lb.ai("");
        else
          lb.ai("return ");
        lb.a('(');
        lb.a(mapTypeC(method.ret, ""));
        lb.a(')(cl(');
        lb.a([ for (i in 0...method.args.length) switch (method.args[i]) {
          case String: '::cpp::Pointer<char>(arg_$i)';
          case ClosureDataUse: continue;
          case _: 'arg_$i';
        } ].join(", "));
        lb.a('));\n');
      });
      lb.ai("}\n");
      lb.ai("#endif\n");
    }
  }

  static function generateMethod(method:FFIMethod, ctx:AmmerContext):Void {
    lb.ai('${mapTypeC(method.ret, "")} ${mapMethodName(method.uniqueName)}(');
    if (method.args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i') ].join(", "));
    lb.a(")\n");
    lb.ai('#ifdef AMMER_CODE_${ctx.index}\n');
    lb.ai("{\n");
    lb.indent(() -> {
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      var call = '${method.native}(' + [ for (i in 0...method.args.length) {
        switch (method.args[i]) {
          case Closure(idx, _, _, _): '&wc_${idx}_${ctx.index}';
          case ClosureData(f): 'arg_$f.mPtr';
          case _: 'arg_$i';
        }
      } ].join(", ") + ')';
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
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      generateClosureWrappers(ctx);
    lb.ai('extern "C" {\n');
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.uniqueName))
          continue; // TODO: make sure the field has the same signature
        generated[method.uniqueName] = true;
        generateMethod(method, ctx);
      }
    lb.ai("}\n");
    }
    Utils.update('${config.output}/ammer/ammer_${library.name}.cpp.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
