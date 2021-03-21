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

  static function mapTypeC(t:FFIType, name:String, closure:Bool = false):String {
    return (switch (t) {
      case Closure(_, _, _): '::Dynamic $name';
      case ClosureDataUse: 'void * $name';
      case ClosureData(_): 'int $name';
      case LibIntEnum(_, _): 'int $name';
      case Nested(LibType(t, _)) if (closure): '${t.nativeName} $name';
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  static function unmapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case LibIntEnum(t, _): '${t.nativeName} $name';
      case _: mapTypeC(t, name);
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
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i', true) ].filter(a -> a != null).join(", "));
      lb.a(") {\n");
      lb.indent(() -> {
        lb.ai('::Dynamic cl = ::Dynamic((hx::Object *)(${method.dataAccess.join("->")}));\n');
        lb.ai("::hx::NativeAttach attach_gc;\n");
        if (method.ret == Void)
          lb.ai("");
        else
          lb.ai("return ");
        lb.a('(');
        lb.a(mapTypeC(method.ret, ""));
        lb.a(')');
        if (method.ret.match(LibIntEnum(_, _))) {
          lb.a("(int)");
        }
        lb.a('(cl(');
        lb.a([ for (i in 0...method.args.length) switch (method.args[i]) {
          case String: '::cpp::Pointer<char>(arg_$i)';
          case LibType(t, _): '::cpp::Pointer<${t.nativeName}>(arg_$i)';
          case Nested(LibType(t, _)): '::cpp::Pointer<${t.nativeName}>(&arg_$i)';
          case ClosureDataUse: continue;
          case _: 'arg_$i';
        } ].join(", "));
        lb.a('));\n');
      });
      lb.ai("}\n");
      lb.ai("#endif\n");
    }
  }

  static function generateArrayWrappers(ctx:AmmerContext):Void {
    for (i in 0...ctx.arrayTypes.length) {
      lb.ai('typedef ${mapTypeC(ctx.arrayTypes[i].ffi, "")} wt_array_${i}_${ctx.index};\n');
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
      switch (method.ret) {
        case Alloc(LibType(t, _)):
          lb.ai('${t.nativeName} *ret_alloc = (${t.nativeName} *)malloc(sizeof(${t.nativeName}));\n');
        case _:
      }
      var call = '${method.native}(' + [ for (i in 0...method.args.length) {
        switch (method.args[i]) {
          case Closure(idx, _, _, _):
            var cl = ctx.closureTypes[idx];
            '(${unmapTypeC(cl.ret, "")} (*)(${cl.args.map(a -> unmapTypeC(a, "")).join(", ")}))(&wc_${idx}_${ctx.index})';
          case ClosureData(f): 'arg_$f.mPtr';
          case LibIntEnum(t, _): '(${t.nativeName})arg_$i';
          case Nested(LibType(_, _)): '(*arg_$i)';
          case _: 'arg_$i';
        }
      } ].join(", ") + ')';
      if (method.ret == Void)
        lb.ai("");
      else if (method.ret.match(Alloc(LibType(_, _))))
        lb.ai("*ret_alloc = ");
      else {
        lb.ai("return (");
        lb.a(mapTypeC(method.ret, ""));
        lb.ai(")");
      }
      if (method.cReturn != null)
        lb.a('${method.cReturn.replace("%CALL%", call)};\n');
      else
        lb.a('$call;\n');
      if (method.ret.match(Alloc(LibType(_, _))))
        lb.ai("return ret_alloc;\n");
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
      generateArrayWrappers(ctx);
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
