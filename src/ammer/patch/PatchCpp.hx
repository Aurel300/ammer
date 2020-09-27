package ammer.patch;

import haxe.macro.Expr;

class PatchCpp {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    ctx.externIsExtern = false;
    var headerCode = '#include "../ammer/ammer_${ctx.libraryConfig.name}.cpp.${ctx.libraryConfig.abi == Cpp ? "cpp" : "c"}"';
    ctx.externMeta.push({
      name: ":headerCode",
      params: [{expr: EConst(CString(headerCode)), pos: ctx.implType.pos}],
      pos: pos
    });
    var cppFileCode = '#define AMMER_CODE_${ctx.index}
#include "../ammer/ammer_${ctx.libraryConfig.name}.cpp.${ctx.libraryConfig.abi == Cpp ? "cpp" : "c"}"
#undef AMMER_CODE_${ctx.index}';
    ctx.externMeta.push({
      name: ":cppFileCode",
      params: [{expr: EConst(CString(cppFileCode)), pos: ctx.implType.pos}],
      pos: pos
    });
    var lb = new LineBuf();
    lb.ai('<files id="haxe">\n');
    lb.indent(() -> {
      lb.ai('<compilerflag value="-I${ctx.libraryConfig.includePath}"/>\n');
    });
    lb.ai('</files>\n');
    lb.ai('<target id="haxe">\n');
    lb.indent(() -> {
      lb.ai('<libpath name="${ctx.libraryConfig.libraryPath}"/>\n');
      lb.ai('<lib name="-l${ctx.libraryConfig.name}" unless="windows" />\n');
      lb.ai('<lib name="${ctx.libraryConfig.name}" if="windows" />\n');
    });
    lb.ai('</target>\n');
    ctx.externMeta.push({
      name: ":buildXml",
      params: [{expr: EConst(CString(lb.dump())), pos: pos}],
      pos: pos
    });
    for (t in FFITools.VARIABLE_TYPES) {
      if (!ctx.ffiVariables.exists(t.ffi))
        continue;
      var hxType = t.haxe;
      if (t.ffi == String)
        hxType = (macro : cpp.ConstPointer<cpp.Char>);
      ctx.externFields.push({
        access: [AStatic],
        name: 'ammer_g_${t.name}',
        kind: FFun({
          args: [],
          expr: {
            var vars = [ for (variable in ctx.ffiVariables[t.ffi]) {
              macro untyped __cpp__($v{'${variable.native}'});
            } ];
            macro return $a{vars};
          },
          ret: (macro : Array<$hxType>)
        }),
        pos: pos
      });
    }
  }

  public static function patchType(ctx:AmmerTypeContext):Void {
    var headerCode = '#include "../ammer/ammer_${ctx.libraryCtx.libraryConfig.name}.cpp.${ctx.libraryCtx.libraryConfig.abi == Cpp ? "cpp" : "c"}"';
    ctx.implType.meta.add(
      ":headerCode",
      [{expr: EConst(CString(headerCode)), pos: ctx.implType.pos}],
      ctx.implType.pos
    );
  }
}

class PatchCppMethod extends ammer.patch.PatchMethod {
  override public function visitArgument(i:Int, ffi:FFIType):Void {
    switch (ffi) {
      case NoSize(t):
        return visitArgument(i, t);
      case SizeOfReturn:
        ctx.callArgs[i] = macro cpp.Pointer.addressOf(($e{Utils.id("_retSize")} : cpp.Reference<cpp.SizeT>));
        ctx.wrapExpr = macro {
          var _retSize:cpp.SizeT = 0;
          ${ctx.wrapExpr};
        };
      case Bytes | WithSize(_, Bytes):
        externArgs.push({
          name: '_arg$i',
          type: (macro:cpp.Pointer<cpp.UInt8>)
        });
        return;
      case ClosureData(_):
        ctx.callArgs[i] = macro 0;
      case OutPointer(LibType(_, _)):
        ctx.callArgs[i] = macro untyped __cpp__("&{0}->ammerNative.ptr", $e{ctx.callArgs[i]});
      case _:
    }
    super.visitArgument(i, ffi);
  }

  override public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic, AExtern],
      name: ctx.ffi.uniqueName,
      kind: FFun({
        args: externArgs,
        expr: null,
        ret: mapType(ctx.ffi.ret)
      }),
      meta: [
        {
          name: ":native",
          params: [{expr: EConst(CString('::${ammer.stub.StubCpp.mapMethodName(ctx.ffi.uniqueName)}')), pos: ctx.ffi.field.pos}],
          pos: ctx.ffi.field.pos
        }
      ],
      pos: ctx.ffi.field.pos
    });
  }

  public static function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bytes: (macro:cpp.ConstPointer<cpp.Char>);
      case String: (macro:cpp.ConstPointer<cpp.Char>);
      //case String: (macro:cpp.ConstCharStar);
      //case Array(t = Int): TPath({pack: ["cpp"], name: "Pointer", params: [TPType(mapType(t))]});
      case WithSize(_, Array(t)) | Array(t): TPath({pack: ["cpp"], name: "Star", params: [TPType(mapType(t))]});
      case SizeOfReturn: (macro:cpp.Pointer<cpp.SizeT>);
      case SizeOf(_): (macro:cpp.SizeT);
      case LibType(t, _): t.nativeType;
      case Nested(LibType(t, _)): t.nativeType;
      case LibIntEnum(t): t.nativeType;
      case Derived(_, t) | WithSize(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
