package ammer.patch;

import haxe.macro.Expr;

class PatchCross implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
  }

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchCrossMethod(mctx);
  }
}

class PatchCrossMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case SizeOfReturn | SizeOf(_):
        return;
      case _:
    }
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
