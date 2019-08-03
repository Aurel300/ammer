package ammer.stub;

import haxe.macro.Expr;
import sys.io.File;
import ammer.*;

using ammer.FFITools;

class StubHl extends StubBaseC {
  var lb:LineBuf = new LineBuf();

  public function new(ctx:AmmerContext) {
    super(ctx);
  }

  function generateHeader():Void {
    lb.a('#define HL_NAME(n) ammer_${ctx.libname}_ ## n\n');
    lb.a('#include <hl.h>\n');
    for (header in ctx.headers)
      lb.a('#include <${header}>\n');
  }

  function mapTypeHlFFI(t:FFIType):String {
    return (switch (t) {
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
      case SizeOfReturn: "_REF(_I32)";
      case SizeOf(_): "_I32";
      case SameSizeAs(t, _): mapTypeHlFFI(t);
      case _: throw "!";
    });
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  function generateMethod(name:String, args:Array<FFIType>, ret:FFIType):Void {
    lb.ai('HL_PRIM ${mapTypeC(ret)} HL_NAME(${mapMethodName(name)})(');
    lb.a([ for (i in 0...args.length) '${mapTypeC(args[i])} arg_${i}' ].join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      lb.ai('return ${name}(');
      lb.a([ for (i in 0...args.length) 'arg_${i}' ].join(", "));
      lb.a(');\n');
    });
    lb.ai("}\n");
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(ret)}, ${mapMethodName(name)}, ');
    lb.a([ for (arg in args) mapTypeHlFFI(arg) ].join(" "));
    lb.a(");\n");
  }

  override public function generate():Void {
    generateHeader();
    for (field in ctx.ffi.fields) {
      switch (field) {
        case Method(name, args, ret):
          generateMethod(name, args, ret);
        case _:
      }
    }
    Ammer.update('${ctx.config.hlBuild}/ammer_${ctx.libname}.c', lb.dump());
  }
}
