package ammer.stub;

#if macro
import haxe.macro.Expr;
import sys.io.File;
import ammer.FFI;
import ammer.FFIType;

using ammer.FFITools;

class StubHl extends StubBaseC {
  public function new(ctx:AmmerContext) {
    super(ctx);
  }

  function generateHeader():Void {
    a('#define HL_NAME(n) ammer_${ctx.ffi.name}_ ## n\n');
    a('#include <hl.h>\n');
    for (header in ctx.ffi.headers)
      a('#include <${header}>\n');
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
    ai('HL_PRIM ${mapTypeC(ret)} HL_NAME(${mapMethodName(name)})(');
    a([ for (i in 0...args.length) '${mapTypeC(args[i])} arg_${i}' ].join(", "));
    a(") {\n");
    indent(() -> {
      ai('return ${name}(');
      a([ for (i in 0...args.length) 'arg_${i}' ].join(", "));
      a(');\n');
    });
    ai("}\n");
    ai('DEFINE_PRIM(${mapTypeHlFFI(ret)}, ${mapMethodName(name)}, ');
    a([ for (arg in args) mapTypeHlFFI(arg) ].join(" "));
    a(");\n");
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
    File.saveContent('${ctx.config.outputDir}/stub.c', buf.toString());
  }

  override public function build():Array<String> {
    return [
      '$${CC} $${CFLAGS} -shared -o ammer_${ctx.ffi.name}.hdll native/${ctx.ffi.name}.o $${LIBFLAGS} -L. -lhl -l${ctx.ffi.name}'
    ];
  }
}
#end
