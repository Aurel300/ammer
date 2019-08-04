package ammer.patch;

import haxe.macro.Expr;
import ammer.*;

class PatchEval implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
    ctx.externIsExtern = false;
    var plugin = 'ammer_${ctx.libname}.cmxs';
    ctx.externFields.push({
      access: [APublic, AStatic],
      name: "plugin",
      kind: FVar(macro : Dynamic, macro eval.vm.Context.loadPlugin($v{plugin})),
      meta: [],
      pos: ctx.implType.pos
    });
  }

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchEvalMethod(mctx);
  }
}

class PatchEvalMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
    ctx.callExpr = e(ECall(macro $p{["ammer", "externs", ctx.top.externName, "plugin", ctx.name]}, ctx.callArgs));
    ctx.wrapExpr = ctx.callExpr;
  }

  inline function e(e:ExprDef):Expr {
    return {expr: e, pos: ctx.field.pos};
  }

  inline function id(s:String):Expr {
    return e(EConst(CIdent(s)));
  }

  inline function an(n:String):Expr {
    if (ctx.argNames.indexOf(n) == -1)
      throw "no such arg";
    return id('_arg${ctx.argNames.indexOf(n)}');
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case SizeOf(of):
        ctx.callArgs[i] = macro $e{an(of)}.length;
        ctx.externArgs.push({
          name: original.name,
          type: original.type
        });
        return;
      case SizeOfReturn:
        ctx.callArgs.splice(i, 1);
        ctx.argNames.splice(i, 1);
        return;
      case _:
    }
    ctx.externArgs.push({
      name: original.name,
      type: original.type
    });
    ctx.wrapArgs.push({
      name: '_arg${i}',
      type: original.type
    });
  }

  public function visitReturn(ffi:FFIType, original:ComplexType):ComplexType {
    return original;
  }

  public function finish():Void {}
}
