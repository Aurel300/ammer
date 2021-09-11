package ammer.patch;

import haxe.macro.Expr;

class PatchEval {
  public static function patch(ctx:AmmerContext):Void {}
}

class PatchEvalMethod extends ammer.patch.PatchMethod {
  public function new(ctx:AmmerMethodPatchContext) {
    super(ctx);
  }
}
