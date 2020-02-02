package ammer.patch;

import haxe.macro.Expr;

class PatchCross {
  public static function patch(ctx:AmmerContext):Void {}
}

class PatchCrossMethod extends ammer.patch.PatchMethod {}
