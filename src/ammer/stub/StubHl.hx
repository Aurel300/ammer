package ammer.stub;

import ammer.*;

using ammer.FFITools;

class StubHl {
  static var ctx:AmmerContext;
  static var lb:LineBuf;

  static function generateHeader():Void {
    lb.a('#define HL_NAME(n) ammer_${ctx.libraryConfig.name}_ ## n\n');
    lb.a('#include <hl.h>\n');
    for (header in ctx.libraryConfig.headers)
      lb.a('#include <${header}>\n');
  }

  static function mapTypeHlFFI(t:FFIType):String {
    return (switch (t) {
      case Void: "_VOID";
      case Bool: "_BOOL";
      case Int: "_I32";
      /*
      case I8(_): "char";
      case I16(_): "short";
      case I32(_): "int";
      case I64(_): "long";
      case UI8(_): "unsigned char";
      case UI16(_): "unsigned short";
      case UI32(_): "unsigned int";
      case UI64(_): "unsigned long";
      */
      case Float: "_F64";
      case Bytes: "_BYTES";
      case String: "_BYTES";
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
    lb.a([ for (i in 0...args.length) '${StubBaseC.mapTypeC(args[i])} arg_${i}' ].join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      lb.ai('return ${native}(');
      if (args.length == 0)
        lb.a("_NO_ARG");
      else
        lb.a([ for (i in 0...args.length) 'arg_${i}' ].join(", "));
      lb.a(');\n');
    });
    lb.ai("}\n");
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(ret)}, ${mapMethodName(name)}, ');
    lb.a([ for (arg in args) mapTypeHlFFI(arg) ].join(" "));
    lb.a(");\n");
  }

  public static function generate(ctx:AmmerContext):Void {
    StubHl.ctx = ctx;
    lb = new LineBuf();
    generateHeader();
    for (field in ctx.ffi.fields) {
      switch (field) {
        case Method(name, native, args, ret):
          generateMethod(name, native, args, ret);
        case _:
      }
    }
    Ammer.update('${ctx.config.hl.build}/ammer_${ctx.libraryConfig.name}.hl.${ctx.libraryConfig.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
