package ammer.patch;

import haxe.macro.Expr;

class PatchHl {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    for (t in FFITools.CONSTANT_TYPES) {
      if (!ctx.ffiConstants.exists(t.ffi))
        continue;
      var hxType = t.haxe;
      if (t.ffi == String)
        hxType = (macro : hl.Bytes);
      ctx.externFields.push({
        access: [AStatic],
        name: 'ammer_g_${t.name}',
        kind: FFun({
          args: [],
          expr: null,
          ret: (macro : hl.NativeArray<$hxType>)
        }),
        meta: [
          {
            name: ":hlNative",
            params: [
              {expr: EConst(CString('ammer_${ctx.libraryConfig.name}')), pos: pos},
              {expr: EConst(CString('g_${t.name}_${ctx.index}')), pos: pos}
            ],
            pos: pos
          }
        ],
        pos: pos
      });
    }
  }
}

class PatchHlMethod extends ammer.patch.PatchMethod {
  override public function visitArgument(i:Int, ffi:FFIType):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
      case ClosureData(_):
        ctx.callArgs[i] = macro 0;
      case _:
    }
    super.visitArgument(i, ffi);
  }

  override public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic],
      name: ctx.ffi.uniqueName,
      kind: FFun({
        args: externArgs,
        expr: null,
        ret: mapType(ctx.ffi.ret)
      }),
      meta: [
        {
          name: ":hlNative",
          params: [
            {expr: EConst(CString('ammer_${ctx.top.libraryConfig.name}')), pos: ctx.ffi.field.pos},
            {expr: EConst(CString(ammer.stub.StubHl.mapMethodName(ctx.ffi.uniqueName))), pos: ctx.ffi.field.pos}
          ],
          pos: ctx.ffi.field.pos
        }
      ],
      pos: ctx.ffi.field.pos
    });
  }

  public static function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bytes | String: (macro:hl.Bytes);
      case SizeOfReturn: (macro:hl.Ref<Int>);
      case ArrayFixed(idx, _, _): Ammer.typeMap['ammer.externs.AmmerArray_$idx.AmmerArray_$idx'].nativeType;
      case LibType(t, _) | Nested(LibType(t, _)) | Alloc(LibType(t, _)) | LibIntEnum(t, _): t.nativeType;
      case Derived(_, t) | WithSize(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
