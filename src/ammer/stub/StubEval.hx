package ammer.stub;

import haxe.macro.Expr;
import ammer.Config.AmmerLibraryConfig;

using ammer.FFITools;

class StubEval {
  static var library:AmmerLibraryConfig;
  static var fn:Function;
  static var lbc:LineBuf; // C code
  static var lbo:LineBuf; // OCaml code

  static function generateHeader():Void {
    // C stubs
    lbc.ai("#ifdef __cplusplus\n");
    lbc.ai("extern \"C\" {\n");
    lbc.ai("#endif\n");
    lbc.ai("#define CAML_NAME_SPACE\n");
    lbc.ai("#include <stdbool.h>\n");
    lbc.ai("#include <string.h>\n");
    lbc.ai("#include <caml/alloc.h>\n");
    lbc.ai("#include <caml/callback.h>\n");
    lbc.ai("#include <caml/fail.h>\n");
    lbc.ai("#include <caml/memory.h>\n");
    lbc.ai("#include <caml/mlvalues.h>\n");
    lbc.ai("#ifdef __cplusplus\n");
    lbc.ai("}\n");
    lbc.ai("#endif\n");
    for (header in library.headers)
      lbc.ai('#include <${header}>\n');

    // OCaml stubs
    lbo.ai("open EvalContext\n");
    lbo.ai("open EvalDecode\n");
    lbo.ai("open EvalEncode\n");
    lbo.ai("open EvalExceptions\n");
    lbo.ai("open EvalStdLib\n");
    lbo.ai("open EvalValue\n");
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function boxFFIOCaml(t:FFIType, expr:String):String {
    return (switch (t) {
      case Void: "Val_unit";
      case Bool: 'Val_bool($expr)';
      case Int: 'Val_int($expr)';
      case Float: 'caml_copy_double($expr)';
      case String: 'caml_copy_string($expr)';
      case Bytes:
      var bv = 'tmp${lbc.fresh()}';
      lbc.ai('CAMLlocal1($bv);\n');
      lbc.ai('$bv = caml_alloc_string(_retSize);\n');
      lbc.ai('memcpy(&Byte($bv, 0), _ret, _retSize);\n');
      '$bv';
      case SameSizeAs(t, arg):
      lbc.ai('size_t _retSize = caml_string_length(arg_$arg);\n');
      boxFFIOCaml(t, expr);
      case _: throw "!";
    });
  }

  static function unboxFFIOCaml(t:FFIType, expr:String):String {
    return (switch (t) {
      case Void: "Val_unit";
      case Bool: 'Bool_val($expr)';
      case Int: 'Int_val($expr)';
      case Float: 'Double_val($expr)';
      case String: '&Byte($expr, 0)';
      case Bytes: '(unsigned char *)&Byte($expr, 0)';
      case NoSize(t): unboxFFIOCaml(t, expr);
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
      case Void: "";
      case Bool: "vbool ";
      case Int: "vint ";
      case Float: "vfloat ";
      case String: "encode_string ";
      case Bytes: "encode_bytes ";
      case SizeOf(_): "vint ";
      case SameSizeAs(t, _): boxFFIEval(t);
      case _: throw "!";
    });
  }

  static function unboxFFIEval(t:FFIType):Null<String> {
    return (switch (t) {
      case Bool: "decode_bool";
      case Int: "decode_int";
      case Float: "decode_float";
      case String: "decode_string";
      case Bytes: "decode_bytes";
      case NoSize(t): unboxFFIEval(t);
      case SizeOf(_): "decode_int";
      case SizeOfReturn: null;
      case SameSizeAs(t, _): unboxFFIEval(t);
      case _: throw "!";
    });
  }

  static function mapTypeOCaml(t:FFIType):String {
    return (switch (t) {
      case Void: "unit";
      case Bool: "bool";
      case Int: "int";
      case Float: "float";
      case String: "string";
      case Bytes: "bytes";
      case NoSize(t): mapTypeOCaml(t);
      case SizeOf(_): "int";
      case SizeOfReturn: "int";
      case SameSizeAs(t, _): mapTypeOCaml(t);
      case _: throw "!";
    });
  }

  static function generateMethod(method:FFIMethod):Void {
    // C stubs
    fn = (switch (method.field.kind) {
      case FFun(f): f;
      case _: throw "!";
    });
    lbc.ai("#ifdef __cplusplus\n");
    lbc.ai("extern \"C\"\n");
    lbc.ai("#endif\n");
    lbc.ai('CAMLprim value ${mapMethodName(method.name)}(');
    lbc.a([ for (i in 0...method.args.length) 'value arg_${i}' ].join(", "));
    lbc.a(") {\n");
    lbc.indent(() -> {
      if (method.args.length == 0)
        lbc.ai("CAMLparam0();\n");
      var i = 0;
      while (i < method.args.length) {
        var batch = method.args.length - i <= 5 ? method.args.length - i : 5;
        lbc.ai('CAML${i == 0 ? "" : "x"}param$batch(');
        lbc.a([ for (j in 0...batch) 'arg_${i + j}' ].join(", "));
        lbc.a(');\n');
        i += 5;
      }
      var retVar = (method.ret != Void ? '${StubBaseC.mapTypeC(method.ret)} _ret = ' : "");
      lbc.ai('$retVar${method.native}(${[ for (i in 0...method.args.length) unboxFFIOCaml(method.args[i], 'arg_${i}') ].filter(u -> u != null).join(", ")});\n');
      lbc.ai('CAMLreturn(${boxFFIOCaml(method.ret, "_ret")});\n');
    });
    lbc.ai("}\n");
    if (method.args.length > 5) {
      lbc.ai('CAMLprim value bc_${mapMethodName(method.name)}(value *argv, int argn) {\n');
      lbc.indent(() -> {
        lbc.ai('return ${mapMethodName(method.name)}(');
        lbc.a([ for (i in 0...method.args.length) 'argv[$i]' ].join(", "));
        lbc.a(');\n');
      });
      lbc.ai("}\n");
    }

    // OCaml stubs
    var unboxed = method.args.map(unboxFFIEval);
    var realCount = 0;
    lbo.ai('external ${mapMethodName(method.name)} : ');
    if (unboxed.length == 0)
      lbo.a("unit -> ");
    for (i in 0...unboxed.length) {
      if (unboxed[i] != null) {
        lbo.a('${mapTypeOCaml(method.args[i])} -> ');
        realCount++;
      }
    }
    lbo.a('${mapTypeOCaml(method.ret)} = ');
    if (method.args.length > 5)
      lbo.a('"bc_${mapMethodName(method.name)}" ');
    lbo.a('"${mapMethodName(method.name)}"\n');
    lbo.ai('let ${method.name} = ');
    if (realCount > 5) {
      lbo.a('vstatic_function (fun vl -> match vl with [');
      lbo.a([ for (i in 0...unboxed.length) if (unboxed[i] != null) 'v${i}' ].join("; "));
      lbo.a("] ->\n");
    } else {
      lbo.a('vfun${realCount} (fun ');
      if (unboxed.length == 0)
        lbo.a("()");
      lbo.a([ for (i in 0...unboxed.length) if (unboxed[i] != null) 'v${i}' ].join(" "));
      lbo.a(" ->\n");
    }
    lbo.indent(() -> {
      for (i in 0...unboxed.length) {
        if (unboxed[i] != null)
          lbo.ai('let v${i} = ${unboxed[i]} v${i} in\n');
      }
      lbo.ai('${boxFFIEval(method.ret)}(${mapMethodName(method.name)} ');
      if (method.args.length == 0)
        lbo.a("()");
      lbo.a([ for (i in 0...method.args.length) if (unboxed[i] != null) 'v${i}' ].join(" "));
      if (method.ret == Void) {
        lbo.a(");\n");
        lbo.ai("vnull\n");
      } else
        lbo.a(")\n");
    });
    if (realCount > 5) {
      lbo.ai('| _ -> invalid_call_arg_number ${realCount} (List.length vl)\n');
    }
    lbo.ai(')\n');
  }

  static function generateFooter(generated:Map<String, Bool>):Void {
    lbo.ai(";;\n");
    lbo.ai("EvalStdLib.StdContext.register [\n");
    lbo.indent(() -> {
      for (name in generated.keys()) {
        lbo.ai('"${name}", ${name};\n');
      }
    });
    lbo.ai("];\n");
  }

  public static function generate(config:Config, library:AmmerLibraryConfig):Void {
    StubEval.library = library;
    lbc = new LineBuf();
    lbo = new LineBuf();
    generateHeader();
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.name))
          continue; // TODO: make sure the field has the same signature
        generated[method.name] = true;
        generateMethod(method);
      }
    }
    generateFooter(generated);
    Utils.update('${config.eval.build}/ammer_${library.name}.eval.c', lbc.dump());
    Utils.update('${config.eval.build}/ammer_${library.name}.ml', lbo.dump());
  }
}
