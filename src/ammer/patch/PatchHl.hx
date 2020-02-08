package ammer.patch;

import haxe.macro.Expr;

class PatchHl {
  public static function patch(ctx:AmmerContext):Void {
    var pos = ctx.implType.pos;
    ctx.externFields.push({
      access: [AStatic],
      kind: FFun({
        args: [],
        expr: macro $b{[
          for (t in ([
            {ffi: Int, haxe: (macro : Int), name: "int"},
            {ffi: String, haxe: (macro : hl.Bytes), name: "string"},
            {ffi: Bool, haxe: (macro : Bool), name: "bool"},
            {ffi: Float, haxe: (macro : Float), name: "float"}
          ]:Array<{ffi:FFIType, haxe:ComplexType, name:String}>)) {
            if (!ctx.varCounter.exists(t.ffi))
              continue;
            var hxType = t.haxe;
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
            macro {
              var values = $i{'ammer_g_${t.name}'}();
              $b{[ for (variable in ctx.ffiVariables) {
                if (variable.type != t.ffi)
                  continue;
                // TODO: sub-module types
                if (t.ffi == String)
                  macro $p{ctx.implType.pack.concat([ctx.implType.name, variable.name])} = @:privateAccess String.fromUTF8(values[$v{variable.index}]);
                else
                  macro $p{ctx.implType.pack.concat([ctx.implType.name, variable.name])} = values[$v{variable.index}];
              } ]};
            };
          }
        ]},
        ret: (macro : Void)
      }),
      name: "__init__",
      pos: pos
    });
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
      //case Function(_, _, _):
      //  ctx.callArgs[i] = macro untyped hl.Api.noClosure(${ctx.callArgs[i]});
      case _:
    }
    super.visitArgument(i, ffi);
  }

  override public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic],
      name: ctx.ffi.name,
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
            {expr: EConst(CString(ammer.stub.StubHl.mapMethodName(ctx.ffi.name))), pos: ctx.ffi.field.pos}
          ],
          pos: ctx.ffi.field.pos
        }
      ],
      pos: ctx.ffi.field.pos
    });
  }

  override function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bytes | String: (macro:hl.Bytes);
      case SizeOfReturn: (macro:hl.Ref<Int>);
      case LibType(id, _): Ammer.typeMap[id].nativeType;
      case _: super.mapType(t);
    });
  }
}
