package ammer.stub;

import ammer.Config.AmmerLibraryConfig;

using ammer.FFITools;
using StringTools;

class StubHl {
  static var library:AmmerLibraryConfig;
  static var lb:LineBuf;

  static function generateHeader():Void {
    lb.a('#define HL_NAME(n) ammer_${library.name}_ ## n\n');
    lb.a('#include <hl.h>\n');
    for (header in library.headers)
      lb.a('#include <${header}>\n');
  }

  static function mapTypeHlFFI(t:FFIType):String {
    return (switch (t) {
      case Void: "_VOID";
      case Bool: "_BOOL";
      case Int: "_I32";
      case Float: "_F64";
      case Bytes: "_BYTES";
      case String: "_BYTES";
      case Derived(_, t): mapTypeHlFFI(t);
      case Function(args, ret, _): '_FUN(${mapTypeHlFFI(ret)}, ${args.map(mapTypeHlFFI).join(" ")})';
      case LibType(id, _): '_ABSTRACT(${Ammer.typeMap[id].nativeName})';
      case NoSize(t): mapTypeHlFFI(t);
      case SizeOfReturn: "_REF(_I32)";
      case SizeOf(_): "_I32";
      case SameSizeAs(t, _): mapTypeHlFFI(t);
      case _: throw "!";
    });
  }

  static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case Function(_, _, _): "vclosure *" + (name != "" ? ' $name' : "");
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateMethod(method:FFIMethod):Void {
    lb.ai('HL_PRIM ${mapTypeC(method.ret, "")} HL_NAME(${mapMethodName(method.name)})(');
    if (method.args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i') ].join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      var call = '${method.native}(' + [ for (i in 0...method.args.length) {
        switch (method.args[i]) {
          case Function(_, _, _): 'arg_$i->fun';
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
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(method.ret)}, ${mapMethodName(method.name)}, ');
    if (method.args.length == 0)
      lb.a("_NO_ARG");
    else
      lb.a([ for (arg in method.args) mapTypeHlFFI(arg) ].join(" "));
    lb.a(");\n");
  }

  static function generateVariables(ctx:AmmerContext):Void {
    for (t in ([
      {ffi: Int, hlt: "i32", c: "int", name: "int"},
      {ffi: String, hlt: "bytes", c: "char *", name: "string"},
      {ffi: Bool, hlt: "bool", c: "bool", name: "bool"},
      {ffi: Float, hlt: "f64", c: "double", name: "float"}
    ]:Array<{ffi:FFIType, hlt:String, c:String, name:String}>)) {
      if (!ctx.varCounter.exists(t.ffi))
        continue;
      lb.ai('HL_PRIM varray *HL_NAME(g_${t.name}_${ctx.index})(void) {\n');
      lb.indent(() -> {
        lb.ai('varray *ret = hl_alloc_array(&hlt_${t.hlt}, ${ctx.varCounter[t.ffi]});\n');
        for (variable in ctx.ffiVariables) {
          if (variable.type == t.ffi)
            lb.ai('hl_aptr(ret, ${t.c})[${variable.index}] = ${variable.native};\n');
        }
        lb.ai('return ret;\n');
      });
      lb.ai("}\n");
      lb.ai('DEFINE_PRIM(_ARR, g_${t.name}_${ctx.index}, _NO_ARG);\n');
    }
  }

  public static function generate(config:Config, library:AmmerLibraryConfig):Void {
    StubHl.library = library;
    lb = new LineBuf();
    generateHeader();
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.name))
          continue; // TODO: make sure the field has the same signature
        generated[method.name] = true;
        generateMethod(method);
      }
      generateVariables(ctx);
    }
    Utils.update('${config.hl.build}/ammer_${library.name}.hl.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
