package ammer.stub;

#if macro
import haxe.macro.Expr;
import sys.io.File;
import ammer.FFI;
import ammer.FFIType;

using ammer.FFITools;

class StubCpp extends StubBaseC {
  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
  }

  function generateHeader():Void {
    a('#include <hx/CFFI.h>\n');
    for (header in ctx.ffi.headers)
      a('#include <${header}>\n');
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  function generateMethod(name:String, args:Array<FFIType>, ret:FFIType):Void {
    ai('${mapTypeC(ret)} ${mapMethodName(name)}(');
    a([ for (i in 0...args.length) '${mapTypeC(args[i])} arg_${i}' ].join(", "));
    a(") {\n");
    indent(() -> {
      ai('return ${name}(');
      a([ for (i in 0...args.length) 'arg_${i}' ].join(", "));
      a(');\n');
    });
    ai("}\n");
    ai('DEFINE_PRIME${args.length}(${mapMethodName(name)});\n');
  }

  override public function generate():Void {
    var buf = new StringBuf();
    ai = (data) -> buf.add('$currentIndent$data');
    a = buf.add;
    generateHeader();
    for (field in ctx.ffi.fields) {
      switch (field) {
        case Method(name, args, ret):
          generateMethod(name, args, ret);
        case _:
      }
    }
    ctx.externIsExtern = false;
    ctx.externMeta.push({
      name: ":cppFileCode",
      params: [{expr: EConst(CString(buf.toString())), pos: ctx.implType.pos}],
      pos: ctx.implType.pos
    });
    buf = null;
  }

  override public function build():Array<String> {
    return [];
  }
}
#end
