package ammer.stub;

#if macro
import haxe.macro.Expr;
import sys.io.File;
import ammer.Ammer.AmmerContext;
import ammer.FFI;
import ammer.FFI.FFIType;

using ammer.FFITools;

class StubHL extends StubBaseC {
  function generateHeader():Void {
    a('#define HL_NAME(n) ammer_${ctx.ffi.name}_ ## n\n');
    a('#include <hl.h>\n');
    for (header in ctx.ffi.headers)
      a('#include <${header}>\n');
  }

  function mapTypeHLFFI(t:FFIType):String {
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
      case ReturnSizePtr(t): "_REF(_I32)";
      case SizePtr(t, _): mapTypeHLFFI(t);
      case _: throw "!";
    });
  }

  function mapTypeHLExtern(t:FFIType):ComplexType {
    return (switch (t) {
      case Bool: (macro : Bool);
      case Int: (macro : Int);
      case Bytes | String: (macro : hl.Bytes);
      case ReturnSizePtr(t): (macro : hl.Ref<Int>);
      case SizePtr(t, _): (macro : Int);
      case _: throw "!";
    });
  }

  function mapMethodName(name:String):String {
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
    ai('DEFINE_PRIM(${mapTypeHLFFI(ret)}, ${mapMethodName(name)}, ');
    a([ for (arg in args) mapTypeHLFFI(arg) ].join(" "));
    a(");\n");
  }

  override public function generate(ctx:AmmerContext):Void {
    this.ctx = ctx;
    var buf = new StringBuf();
    ai = (data) -> buf.add('$currentIndent$data');
    a = buf.add;
    generateHeader();
    for (field in ctx.ffi.fields) {
      switch (field.kind) {
        case Method(name, args, ret):
          generateMethod(name, args, ret);
        case _:
      }
    }
    File.saveContent('${ctx.config.outputDir}/stub.c', buf.toString());
    this.ctx = null;
    buf = null;
  }

  override public function build(ctx:AmmerContext):Array<String> {
    return [
      '$${CC} $${CFLAGS} -shared -o ammer_${ctx.ffi.name}.hdll native/${ctx.ffi.name}.o $${LIBFLAGS} -L. -lhl -l${ctx.ffi.name}'
    ];
  }

  override public function patch(ctx:AmmerContext):Void {
    for (i in 0...ctx.ffi.fields.length) {
      var ffiField = ctx.ffi.fields[i];
      var implField = ctx.implFields[i];
      var pos = implField.pos;
      inline function e(e:ExprDef):Expr {
        return {expr: e, pos: pos};
      }
      inline function id(s:String):Expr {
        return e(EConst(CIdent(s)));
      }
      if (implField.meta == null)
        implField.meta = [];
      switch [ffiField.kind, implField.kind] {
        case [Method(mn, ffiArgs, ffiRet), FFun(f)]:
          var argNames = f.args.map(a -> a.name);
          inline function an(n:String):Expr {
            if (argNames.indexOf(n) == -1)
              throw "no such arg";
            return id('_arg${argNames.indexOf(n)}');
          }
          var callArgs = [ for (i in 0...ffiArgs.length) id('_arg${i}') ];
          var callExpr = e(ECall(macro $p{["ammer", "externs", ctx.externName, implField.name]}, callArgs));
          var wrapExpr = callExpr;
          switch (ffiRet) {
            case Bytes:
              wrapExpr = macro {
                var _retPtr:hl.Bytes = $wrapExpr;
                _retPtr.toBytes(_retSize);
              };
            case String:
              wrapExpr = macro {
                var _retPtr:hl.Bytes = $wrapExpr;
                @:privateAccess String.fromUTF8(_retPtr);
              };
            case _:
          }
          for (annotation in ffiField.annotations) {
            switch (annotation) {
              case ReturnSizeSameAs(of):
                wrapExpr = macro {
                  var _retSize = 1; //macro $e{an(of)}.length;
                  $wrapExpr;
                };
              case _: throw "!";
            }
          }
          var wrapArgs = [ for (i in 0...ffiArgs.length) {
              var ffiArg = ffiArgs[i];
              switch (ffiArg) {
                case ReturnSizePtr(_):
                  var orig = f.args[i].type;
                  f.args[i].type = (macro : hl.Ref<$orig>);
                  callArgs[i] = id("_retSize");
                  wrapExpr = macro {
                    var _retSize = 0;
                    $wrapExpr;
                  };
                  continue;
                case SizePtr(_, of):
                  callArgs[i] = macro $e{an(of)}.length;
                  continue;
                case String:
                  callArgs[i] = macro @:privateAccess $e{id('_arg${i}')}.toUtf8();
                case _:
              }
              {
                name: '_arg${i}',
                type: f.args[i].type
              };
            } ];
          var externField:Field = {
            access: [APublic, AStatic],
            name: implField.name,
            kind: FFun({
              args: [ for (i in 0...f.args.length) {
                name: f.args[i].name,
                type: mapTypeHLExtern(ffiArgs[i])
              } ],
              expr: null,
              ret: mapTypeHLExtern(ffiRet)
            }),
            meta: [{
              name: ":hlNative",
              params: [
                {expr: EConst(CString('ammer_${ctx.libname}')), pos: pos},
                {expr: EConst(CString(mapMethodName(implField.name))), pos: pos}
              ],
              pos: pos
            }],
            pos: pos
          };
          ctx.externFields.push(externField);
          f.expr = macro return $wrapExpr;
          f.args = wrapArgs;
          implField.kind = FFun(f);
        case _:
          throw "?";
      }
    }
  }

  public function new() {}
}
#end
