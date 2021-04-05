package ammer.patch;

import haxe.macro.Expr;

class PatchLua {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    ctx.externIsExtern = false;
    var lib =  ammer.build.BuildTools.extensions('ammer_${ctx.libraryConfig.name}.%DLL%');
    var load = 'assert(package.loadlib("$lib", "g_init_${ctx.index}"))()';
    ctx.externFields.push({
      access: [AStatic],
      kind: FVar((macro:lua.Table<String, Dynamic>), macro untyped __lua__($v{load})),
      name: "ammerNative",
      pos: pos
    });
    for (t in FFITools.CONSTANT_TYPES) {
      if (!ctx.ffiConstants.exists(t.ffi))
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
      case Unsupported(_):
        ctx.callArgs[i] = macro 0;
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
      case ArrayFixed(idx, _, _): Ammer.typeMap['ammer.externs.AmmerArray_$idx.AmmerArray_$idx'].nativeType;
      case LibType(t, _) | Nested(LibType(t, _)) | Alloc(LibType(t, _)) | LibIntEnum(t, _): t.nativeType;
      case Derived(_, t) | WithSize(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
