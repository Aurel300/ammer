package ammer.patch;

import haxe.macro.Expr;

class PatchHl implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
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

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchHlMethod(mctx);
  }
}

class PatchHlMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.callArgs[i] = Utils.id("_retSize");
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
        ctx.externArgs.push({
          name: original.name,
          type: (macro:hl.Ref<Int>)
        });
        return;
      case SizeOf(of):
        ctx.callArgs[i] = macro $e{Utils.an(of)}.length;
        ctx.externArgs.push({
          name: original.name,
          type: mapTypeHlExtern(ffi)
        });
        return;
      case _:
    }
    ctx.externArgs.push({
      name: original.name,
      type: mapTypeHlExtern(ffi)
    });
    ctx.wrapArgs.push({
      name: '_arg${i}',
      type: original.type
    });
  }

  public function visitReturn(ffi:FFIType, original:ComplexType):ComplexType {
    return mapTypeHlExtern(ffi);
  }

  public function mapTypeHlExtern(t:FFIType):ComplexType {
    return (switch (t) {
      case Void: (macro:Void);
      case Bool: (macro:Bool);
      case Int: (macro:Int);
      case Float: (macro:Float);
      case Bytes | String: (macro:hl.Bytes);
      case Opaque(id): Ammer.opaqueMap[id].nativeType;
      case Deref(t): mapTypeHlExtern(t);
      case NoSize(t): mapTypeHlExtern(t);
      case SizeOfReturn: (macro:hl.Ref<Int>);
      case SizeOf(_): (macro:Int);
      case SameSizeAs(t, _): mapTypeHlExtern(t);
      case _: throw "!";
    });
  }

  public function finish():Void {
    ctx.top.externFields.push({
      access: [APublic, AStatic],
      name: ctx.name,
      kind: FFun({
        args: ctx.externArgs,
        expr: null,
        ret: mapTypeHlExtern(ctx.ffiRet)
      }),
      meta: [
        {
          name: ":hlNative",
          params: [
            {expr: EConst(CString('ammer_${ctx.top.libraryConfig.name}')), pos: ctx.field.pos},
            {expr: EConst(CString(ammer.stub.StubHl.mapMethodName(ctx.name))), pos: ctx.field.pos}
          ],
          pos: ctx.field.pos
        }
      ],
      pos: ctx.field.pos
    });
  }
}
