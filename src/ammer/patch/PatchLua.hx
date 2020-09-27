package ammer.patch;

import haxe.macro.Expr;

class PatchLua {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    ctx.externIsExtern = false;
    ctx.externFields.push({
      access: [AStatic],
      kind: FVar((macro:lua.Table<String, Dynamic>), null),
      name: "ammerNative",
      pos: pos
    });
    var load = 'package.loadlib("${ammer.build.BuildTools.extensions('ammer_${ctx.libraryConfig.name}.%DLL%')}", "g_init_${ctx.index}")()';
    for (t in FFITools.VARIABLE_TYPES) {
      if (!ctx.ffiVariables.exists(t.ffi))
        continue;
      var hxType = t.haxe;
      ctx.externFields.push({
        access: [AStatic],
        name: 'ammer_g_${t.name}',
        kind: FFun({
          args: [],
          expr: macro return $p{["ammerNative", 'g_${t.name}_${ctx.index}']}(),
          ret: (macro : lua.Table<Int, $hxType>)
        }),
        pos: pos
      });
    }
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
      name: ctx.ffi.uniqueName,
      kind: FFun({
        args: externArgs,
        expr: macro return untyped ammerNative[$v{ammer.stub.StubLua.mapMethodName(ctx.ffi.uniqueName)}]($a{callArgs}),
        ret: mapType(ctx.ffi.ret)
      }),
      pos: ctx.ffi.field.pos
    });
  }

  public static function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bytes: (macro:String);
      case LibType(t, _): t.nativeType;
      case Nested(LibType(t, _)): t.nativeType;
      case LibIntEnum(t): t.nativeType;
      case Derived(_, t) | WithSize(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
