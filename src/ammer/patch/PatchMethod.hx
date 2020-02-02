package ammer.patch;

import haxe.macro.Expr;

class PatchMethod {
  final ctx:AmmerMethodPatchContext;
  final externArgs:Array<FunctionArg> = [];

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType):Void {
    externArgs.push({
      name: '_arg$i',
      type: mapType(ffi)
    });
  }

  public function finish():Void {}

  function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Derived(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case _: t.toComplexType();
    });
  }
}
