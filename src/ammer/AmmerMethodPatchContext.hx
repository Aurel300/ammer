package ammer;

import haxe.macro.Expr;

typedef AmmerMethodPatchContext = {
  top:AmmerContext,
  ffi:FFIMethod,
  callArgs:Array<Expr>,
  callExpr:Expr,
  wrapExpr:Expr
};
