package ammer.patch;

import haxe.macro.Expr;
import ammer.*;

class PatchCpp implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
    ctx.externIsExtern = false;
    for (header in ctx.libraryConfig.headers)
      ctx.externMeta.push({
        name: ":headerCode",
        params: [{expr: EConst(CString('#include <${header}>')), pos: ctx.implType.pos}],
        pos: ctx.implType.pos
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
      params: [{expr: EConst(CString(lb.dump())), pos: ctx.implType.pos}],
      pos: ctx.implType.pos
    });
  }

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchCppMethod(mctx);
  }
}

class PatchCppMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case NoSize(t):
        return visitArgument(i, t, original);
      case SizeOfReturn:
        ctx.callArgs[i] = macro cpp.Pointer.addressOf(($e{Utils.id("_retSize")} : cpp.Reference<cpp.SizeT>));
        ctx.wrapExpr = macro {
          var _retSize:cpp.SizeT = 0;
          ${ctx.wrapExpr};
        };
        ctx.externArgs.push({
          name: original.name,
          type: (macro:cpp.Pointer<cpp.SizeT>)
        });
        return;
      case SizeOf(of):
        ctx.callArgs[i] = macro $e{Utils.an(of)}.length;
        ctx.externArgs.push({
          name: original.name,
          type: mapTypeCppExtern(ffi, false)
        });
        return;
      case Bytes:
        ctx.externArgs.push({
          name: original.name,
          type: (macro:cpp.Pointer<cpp.UInt8>)
        });
        ctx.wrapArgs.push({
          name: '_arg${i}',
          type: original.type
        });
        return;
      case _:
    }
    ctx.externArgs.push({
      name: original.name,
      type: mapTypeCppExtern(ffi, false)
    });
    ctx.wrapArgs.push({
      name: '_arg${i}',
      type: original.type
    });
  }

  public function visitReturn(ffi:FFIType, original:ComplexType):ComplexType {
    switch (ffi) {
      case SameSizeAs(t, arg):
        var ret = visitReturn(t, original);
        ctx.wrapExpr = macro {
          var _retSize = $e{Utils.an(arg)}.length;
          ${ctx.wrapExpr};
        };
        return ret;
      case _:
    }
    return original;
  }

  public function mapTypeCppExtern(t:FFIType, ret:Bool):ComplexType {
    return (switch (t) {
      case Void: (macro:Void);
      case Bool: (macro:Bool);
      case Int: (macro:Int);
      case Float: (macro:Float);
      case Bytes | String if (!ret): (macro:cpp.ConstPointer<cpp.Char>);
      case Bytes | String: (macro:cpp.Pointer<cpp.Char>);
      case NoSize(t): mapTypeCppExtern(t, ret);
      case SizeOfReturn: (macro:cpp.Pointer<cpp.SizeT>);
      case SizeOf(_): (macro:cpp.SizeT);
      case SameSizeAs(t, _): mapTypeCppExtern(t, ret);
      case _: throw "!";
    });
  }

  public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic, AExtern],
      name: ctx.name,
      kind: FFun({
        args: ctx.externArgs,
        expr: null,
        ret: mapTypeCppExtern(ctx.ffiRet, true)
      }),
      meta: [
        {
          name: ":native",
          params: [{expr: EConst(CString("::" + ctx.name)), pos: ctx.field.pos},],
          pos: ctx.field.pos
        }
      ],
      pos: ctx.field.pos
    });
  }
}
