package ammer.patch;

import haxe.macro.Expr;
import ammer.*;

class PatchHl implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
  }

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchHlMethod(mctx);
  }
}

class PatchHlMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.callArgs[i] = Utils.id("_retSize");
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
        ctx.externArgs.push({
          name: original.name,
          type: (macro:hl.Ref<Int>)
        });
        return;
      case SizeOf(of):
        ctx.callArgs[i] = macro $e{Utils.an(of)}.length;
        ctx.externArgs.push({
          name: original.name,
          type: mapTypeHlExtern(ffi)
        });
        return;
      case _:
    }
    ctx.externArgs.push({
      name: original.name,
      type: mapTypeHlExtern(ffi)
    });
    ctx.wrapArgs.push({
      name: '_arg${i}',
      type: original.type
    });
  }

  public function visitReturn(ffi:FFIType, original:ComplexType):ComplexType {
    return mapTypeHlExtern(ffi);
  }

  public function mapTypeHlExtern(t:FFIType):ComplexType {
    return (switch (t) {
      case Void: (macro:Void);
      case Bool: (macro:Bool);
      case Int: (macro:Int);
      case Float: (macro:Float);
      case Bytes | String: (macro:hl.Bytes);
      case NoSize(t): mapTypeHlExtern(t);
      case SizeOfReturn: (macro:hl.Ref<Int>);
      case SizeOf(_): (macro:Int);
      case SameSizeAs(t, _): mapTypeHlExtern(t);
      case _: throw "!";
    });
  }

  public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic],
      name: ctx.name,
      kind: FFun({
        args: ctx.externArgs,
        expr: null,
        ret: mapTypeHlExtern(ctx.ffiRet)
      }),
      meta: [
        {
          name: ":hlNative",
          params: [
            {expr: EConst(CString('ammer_${ctx.top.libraryConfig.name}')), pos: ctx.field.pos},
            {expr: EConst(CString(ammer.stub.StubHl.mapMethodName(ctx.name))), pos: ctx.field.pos}
          ],
          pos: ctx.field.pos
        }
      ],
      pos: ctx.field.pos
    });
  }
}
