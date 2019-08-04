package ammer.stub;

import haxe.macro.Expr;
import ammer.*;

using ammer.FFITools;

class StubEval {
  static var ctx:AmmerContext;
  static var fn:Function;
  static var lbc:LineBuf; // C code
  static var lbo:LineBuf; // OCaml code

  static function generateHeader():Void {
    // C stubs
    lbc.ai("#define CAML_NAME_SPACE\n");
    lbc.ai("#include <string.h>\n");
    lbc.ai("#include <caml/alloc.h>\n");
    lbc.ai("#include <caml/callback.h>\n");
    lbc.ai("#include <caml/fail.h>\n");
    lbc.ai("#include <caml/memory.h>\n");
    lbc.ai("#include <caml/mlvalues.h>\n");
    for (header in ctx.headers)
      lbc.ai('#include <${header}>\n');

    // OCaml stubs
    lbo.ai("open EvalContext\n");
    lbo.ai("open EvalDecode\n");
    lbo.ai("open EvalEncode\n");
    lbo.ai("open EvalStdLib\n");
    lbo.ai("open EvalValue\n");
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function boxFFIOCaml(t:FFIType, expr:String):String {
    return (switch (t) {
      case Bool: 'Val_bool($expr)';
      case Int: 'Val_int($expr)';
      case String: 'caml_copy_string($expr)';
      case Bytes:
      var bv = 'tmp${lbc.fresh()}';
      lbc.ai('CAMLlocal1($bv);\n');
      lbc.ai('$bv = caml_alloc_string(_retSize);\n');
      lbc.ai('memcpy(&Byte($bv, 0), _ret, _retSize);\n');
      '$bv';
      case SameSizeAs(t, arg):
      lbc.ai('size_t _retSize = caml_string_length(arg_${fn.args.map(a -> a.name).indexOf(arg)});\n');
      boxFFIOCaml(t, expr);
      case _: throw "!";
    });
  }

  static function unboxFFIOCaml(t:FFIType, expr:String):String {
    return (switch (t) {
      case Bool: 'Bool_val($expr)';
      case Int: 'Int_val($expr)';
      case String: '&Byte($expr, 0)';
      case Bytes: '&Byte($expr, 0)';
      case SizeOf(_):
      'Int_val($expr)';
      case SizeOfReturn:
      lbc.ai('size_t _retSize = 0;\n');
      '&_retSize';
      case _: throw "!";
    });
  }

  static function boxFFIEval(t:FFIType):String {
    return (switch (t) {
      case Bool: "vbool";
      case Int: "vint";
      case String: "encode_string";
      case Bytes: "encode_bytes";
      case SizeOf(_): "vint";
      case SameSizeAs(t, _): boxFFIEval(t);
      case _: trace(t); throw "!";
    });
  }

  static function unboxFFIEval(t:FFIType):Null<String> {
    return (switch (t) {
      case Bool: "decode_bool";
      case Int: "decode_int";
      case String: "decode_string";
      case Bytes: "decode_bytes";
      case SizeOf(_): "decode_int";
      case SizeOfReturn: null;
      case SameSizeAs(t, _): unboxFFIEval(t);
      case _: trace(t); throw "!";
    });
  }

  static function mapTypeOCaml(t:FFIType):String {
    return (switch (t) {
      case Bool: "bool";
      case Int: "int";
      case String: "string";
      case Bytes: "bytes";
      case SizeOf(_): "int";
      case SizeOfReturn: "int";
      case SameSizeAs(t, _): mapTypeOCaml(t);
      case _: throw "!";
    });
  }

  static function generateMethod(name:String, args:Array<FFIType>, ret:FFIType):Void {
    // C stubs
    lbc.ai('CAMLprim value ${mapMethodName(name)}(');
    lbc.a([ for (i in 0...args.length) 'value arg_${i}' ].join(", "));
    lbc.a(") {\n");
    lbc.indent(() -> {
      var i = 0;
      while (i < args.length) {
        var batch = args.length - i <= 5 ? args.length - i : 5;
        lbc.ai('CAML${i == 0 ? "" : "x"}param$batch(');
        lbc.a([ for (j in 0...batch) 'arg_${i + j}' ].join(", "));
        lbc.a(');\n');
        i += 5;
      }
      lbc.ai('${StubBaseC.mapTypeC(ret)} _ret = ${name}(${[ for (i in 0...args.length) unboxFFIOCaml(args[i], 'arg_${i}') ].filter(u -> u != null).join(", ")});\n');
      lbc.ai('CAMLreturn(${boxFFIOCaml(ret, "_ret")});\n');
    });
    lbc.ai("}\n");
    // TODO: handle > 5 args

    // OCaml stubs
    var unboxed = args.map(unboxFFIEval);
    var realCount = 0;
    lbo.ai('external ${mapMethodName(name)} : ');
    for (i in 0...unboxed.length) {
      if (unboxed[i] != null) {
        lbo.a('${mapTypeOCaml(args[i])} -> ');
        realCount++;
      }
    }
    lbo.a('${mapTypeOCaml(ret)} = "${mapMethodName(name)}"\n');
    lbo.ai('let ${name} = vfun${realCount} (fun ');
    lbo.a([ for (i in 0...unboxed.length) if (unboxed[i] != null) 'v${i}' ].join(" "));
    lbo.a(" ->\n");
    lbo.indent(() -> {
      for (i in 0...unboxed.length) {
        if (unboxed[i] != null)
          lbo.ai('let v${i} = ${unboxed[i]} v${i} in\n');
      }
      lbo.ai('${boxFFIEval(ret)} (${mapMethodName(name)} ');
      lbo.a([ for (i in 0...args.length) if (unboxed[i] != null) 'v${i}' ].join(" "));
      lbo.a(')\n');
    });
    lbo.ai(')\n');
  }

  static function generateFooter():Void {
    lbo.ai(";;\n");
    lbo.ai("EvalStdLib.StdContext.register [\n");
    lbo.indent(() -> {
      for (field in ctx.ffi.fields) {
        switch (field) {
          case Method(name, args, ret):
            lbo.ai('"${name}", ${name};\n');
          case _:
        }
      }
    });
    lbo.ai("];\n");
  }

  public static function generate(ctx:AmmerContext):Void {
    StubEval.ctx = ctx;
    lbc = new LineBuf();
    lbo = new LineBuf();
    generateHeader();
    var mi = 0;
    for (field in ctx.ffi.fields) {
      switch (field) {
        case Method(name, args, ret):
          fn = (switch (ctx.implFields[mi++].kind) {
            case FFun(f): f;
            case _: throw "!";
          });
          generateMethod(name, args, ret);
        case _:
      }
    }
    generateFooter();
    Ammer.update('${ctx.config.eval.build}/ammer_${ctx.libname}.eval.c', lbc.dump());
    Ammer.update('${ctx.config.eval.build}/ammer_${ctx.libname}.ml', lbo.dump());
  }
}
