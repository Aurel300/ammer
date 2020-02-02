package ammer.patch;

import haxe.macro.Expr;

class PatchEval {
  public static function patch(ctx:AmmerContext):Void {
    ctx.externIsExtern = false;
    var plugin = 'ammer_${ctx.libraryConfig.name}.cmxs';
    ctx.externFields.push({
      access: [APublic, AStatic],
      name: "plugin",
      kind: FVar(macro : Dynamic, macro eval.vm.Context.loadPlugin($v{plugin})),
      meta: [],
      pos: ctx.implType.pos
    });
  }
}

class PatchEvalMethod extends ammer.patch.PatchMethod {
  public function new(ctx:AmmerMethodPatchContext) {
    super(ctx);
    ctx.callExpr = Utils.e(ECall(macro $p{["ammer", "externs", ctx.top.externName, "plugin", ctx.ffi.name]}, ctx.callArgs));
    ctx.wrapExpr = ctx.callExpr;
  }

  override public function visitArgument(i:Int, ffi:FFIType):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
        ctx.callArgs.splice(i, 1);
        return;
      case _:
    }
    super.visitArgument(i, ffi);
  }
}
