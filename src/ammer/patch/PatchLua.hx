package ammer.patch;

import haxe.macro.Expr;

class PatchLua {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    ctx.externIsExtern = false;
    ctx.externFields.push({
      access: [AStatic],
      kind: FVar((macro:lua.Table<String, Dynamic>), macro null),
      name: "ammerNative",
      pos: pos
    });
    var load = 'package.loadlib("ammer_${ctx.libraryConfig.name}.dylib", "g_init_${ctx.index}")()';
    ctx.externFields.push({
      access: [AStatic],
      kind: FFun({
        args: [],
        expr: macro {
          ammerNative = untyped __lua__($v{load});
        },
        ret: (macro : Void)
      }),
      name: "__init__",
      pos: pos
    });
    // TODO: variables
  }
}

class PatchLuaMethod extends ammer.patch.PatchMethod {
  override public function visitArgument(i:Int, ffi:FFIType):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
      case _:
    }
    super.visitArgument(i, ffi);
  }

  override public function finish():Void {
    var callArgs:Array<Expr> = [ for (i in 0...externArgs.length) Utils.arg(i) ];
    ctx.top.externFields.push({
      access: [APublic, AStatic, AInline],
      name: ctx.ffi.name,
      kind: FFun({
        args: externArgs,
        expr: macro return untyped ammerNative[$v{ammer.stub.StubLua.mapMethodName(ctx.ffi.name)}]($a{callArgs}),
        ret: mapType(ctx.ffi.ret)
      }),
      pos: ctx.ffi.field.pos
    });
  }
}
