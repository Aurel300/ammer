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
    var load = 'package.loadlib("${ammer.build.BuildTools.extensions('ammer_${ctx.libraryConfig.name}.%DLL%')}", "g_init_${ctx.index}")()';
    ctx.externFields.push({
      access: [AStatic],
      kind: FFun({
        args: [],
        expr: macro {
          ammerNative = untyped __lua__($v{load});
          $b{[
            for (t in ([
              {ffi: Int, name: "int"},
              {ffi: String, name: "string"},
              {ffi: Bool, name: "bool"},
              {ffi: Float, name: "float"}
            ]:Array<{ffi:FFIType, name:String}>)) {
              if (!ctx.varCounter.exists(t.ffi))
                continue;
              macro {
                var values:lua.Table<Int, Any> = $p{["ammerNative", 'g_${t.name}_${ctx.index}']}();
                $b{[ for (variable in ctx.ffiVariables) {
                  if (variable.type != t.ffi)
                    continue;
                  // TODO: sub-module types
                  macro $p{ctx.implType.pack.concat([ctx.implType.name, variable.name])} = values[$v{variable.index}];
                } ]};
              };
            }
          ]};
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
      name: ctx.ffi.name,
      kind: FFun({
        args: externArgs,
        expr: macro return untyped ammerNative[$v{ammer.stub.StubLua.mapMethodName(ctx.ffi.name)}]($a{callArgs}),
        ret: mapType(ctx.ffi.ret)
      }),
      pos: ctx.ffi.field.pos
    });
  }

  override function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bytes: (macro:String);
      case LibType(id, _): Ammer.typeMap[id].nativeType;
      case _: super.mapType(t);
    });
  }
}
