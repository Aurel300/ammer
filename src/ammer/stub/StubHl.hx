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
      case Int | I8(_): "_I32";
      case Float: "_F64";
      case Single: "_F32";
      case Bytes: "_BYTES";
      case String: "_BYTES";
      case Derived(_, t): mapTypeHlFFI(t);
      case Closure(_, args, ret, _): '_FUN(${mapTypeHlFFI(ret)}, ${args.map(mapTypeHlFFI).filter(a -> a != null).join(" ")})';
      case ClosureDataUse: null;
      case ClosureData(_): "_I32"; // dummy
      case LibType(id, _): '_ABSTRACT(${Ammer.typeMap[id].nativeName})';
      case OutPointer(LibType(id, _)): '_OBJ(_ABSTRACT(${Ammer.typeMap[id].nativeName}))';
      case NoSize(t): mapTypeHlFFI(t);
      case SizeOfReturn: "_REF(_I32)";
      case SizeOf(_): "_I32";
      case SameSizeAs(t, _): mapTypeHlFFI(t);
      case _: throw "!";
    });
  }

  static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case Closure(_, _, _, _): 'vclosure *$name';
      case ClosureDataUse: 'void *$name';
      case ClosureData(_): 'int $name';
      case OutPointer(LibType(id, _)): 'vdynamic *$name';
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  static function generateClosureWrappers(ctx:AmmerContext):Void {
    for (i in 0...ctx.closureTypes.length) {
      var method = ctx.closureTypes[i];
      lb.ai('static ${mapTypeC(method.ret, "")} wc_${i}_${ctx.index}(');
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i') ].filter(a -> a != null).join(", "));
      lb.a(") {\n");
      lb.indent(() -> {
        lb.ai('vclosure *cl = (vclosure *)(${method.dataAccess.join("->")});\n');
        inline function print(withValue:Bool):Void {
          if (method.ret == Void)
            lb.ai("");
          else
            lb.ai("return ");
          lb.a('((');
          lb.a(mapTypeC(method.ret, ""));
          lb.a(' (*)(');
          lb.a((withValue ? ["vdynamic *"] : []).concat([ for (i in 0...method.args.length) switch (method.args[i]) {
            case ClosureDataUse: continue;
            case _: mapTypeC(method.args[i], "");
          } ]).filter(a -> a != null).join(", "));
          lb.a('))(cl->fun))(');
          lb.a((withValue ? ["cl->value"] : []).concat([ for (i in 0...method.args.length) switch (method.args[i]) {
            case ClosureDataUse: continue;
            case _: 'arg_$i';
          } ]).join(", "));
          lb.a(');\n');
        }
        lb.ai("if (cl->hasValue)\n");
        lb.indent(() -> print(true));
        lb.ai("else\n");
        lb.indent(() -> print(false));
      });
      lb.ai("}\n");
    }
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateMethod(method:FFIMethod, ctx:AmmerContext):Void {
    lb.ai('HL_PRIM ${mapTypeC(method.ret, "")} HL_NAME(${mapMethodName(method.uniqueName)})(');
    if (method.args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i') ].filter(a -> a != null).join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      var call = '${method.native}(' + [ for (i in 0...method.args.length) {
        switch (method.args[i]) {
          case Closure(idx, _, _, _): 'wc_${idx}_${ctx.index}';
          case ClosureData(f): '(void *)arg_$f';
          case OutPointer(LibType(id, _)): '(${Ammer.typeMap[id].nativeName} **)(&(((void **)arg_$i)[1]))';
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
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(method.ret)}, ${mapMethodName(method.uniqueName)}, ');
    if (method.args.length == 0)
      lb.a("_NO_ARG");
    else
      lb.a([ for (arg in method.args) mapTypeHlFFI(arg) ].filter(a -> a != null).join(" "));
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
      generateClosureWrappers(ctx);
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.uniqueName))
          continue; // TODO: make sure the field has the same signature
        generated[method.uniqueName] = true;
        generateMethod(method, ctx);
      }
      generateVariables(ctx);
    }
    Utils.update('${config.hl.build}/ammer_${library.name}.hl.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
