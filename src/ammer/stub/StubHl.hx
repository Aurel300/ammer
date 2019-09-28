package ammer.stub;

import ammer.AmmerConfig.AmmerLibraryConfig;

using ammer.FFITools;

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
      case Opaque(id): '_ABSTRACT(${Ammer.opaqueMap[id].nativeName})';
      case NoSize(t): mapTypeHlFFI(t);
      case SizeOfReturn: "_REF(_I32)";
      case SizeOf(_): "_I32";
      case SameSizeAs(t, _): mapTypeHlFFI(t);
      case _: throw "!";
    });
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateMethod(name:String, native:String, args:Array<FFIType>, ret:FFIType):Void {
    lb.ai('HL_PRIM ${StubBaseC.mapTypeC(ret)} HL_NAME(${mapMethodName(name)})(');
    if (args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...args.length) '${StubBaseC.mapTypeC(args[i])} arg_${i}' ].join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      lb.ai('return ${native}(');
      lb.a([ for (i in 0...args.length) 'arg_${i}' ].join(", "));
      lb.a(');\n');
    });
    lb.ai("}\n");
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(ret)}, ${mapMethodName(name)}, ');
    if (args.length == 0)
      lb.a("_NO_ARG");
    else
      lb.a([ for (arg in args) mapTypeHlFFI(arg) ].join(" "));
    lb.a(");\n");
  }

  public static function generate(config:AmmerConfig, library:AmmerLibraryConfig):Void {
    StubHl.library = library;
    lb = new LineBuf();
    generateHeader();
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      for (field in ctx.ffi.fields) {
        switch (field) {
          case Method(name, native, args, ret, _):
            if (generated.exists(name))
              continue; // TODO: make sure the field has the same signature
            generated[name] = true;
            generateMethod(name, native, args, ret);
          case _:
        }
      }
    }
    Ammer.update('${config.hl.build}/ammer_${library.name}.hl.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
