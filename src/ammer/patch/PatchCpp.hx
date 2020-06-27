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
    ctx.externFields.push({
      access: [AStatic],
      kind: FFun({
        args: [],
        expr: macro $b{[
          for (t in ([
            {ffi: Int, name: "int"},
            {ffi: String, name: "string"},
            {ffi: Bool, name: "bool"},
            {ffi: Float, name: "float"}
          ]:Array<{ffi:FFIType, name:String}>)) {
            if (!ctx.varCounter.exists(t.ffi))
              continue;
            macro $b{[ for (variable in ctx.ffiVariables) {
              if (variable.type != t.ffi)
                continue;
              var target = variable.target;
              if (t.ffi == String)
                macro $p{target.pack.concat([target.module, target.cls, target.field])} = untyped __cpp__($v{'String(${variable.native})'});
              else
                macro $p{target.pack.concat([target.module, target.cls, target.field])} = untyped __cpp__($v{'(${t.name})${variable.native}'});
            } ]};
          }
        ]},
        ret: (macro : Void)
      }),
      name: "__init__",
      pos: pos
    });
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
      case Bytes:
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
      case Bytes | String: (macro:cpp.ConstPointer<cpp.Char>);
      case SizeOfReturn: (macro:cpp.Pointer<cpp.SizeT>);
      case SizeOf(_): (macro:cpp.SizeT);
      case LibType(id, _): Ammer.typeMap[id].nativeType;
      case Nested(LibType(id, _)): Ammer.typeMap[id].nativeType;
      case Derived(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
