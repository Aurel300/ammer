package ammer.patch;

import haxe.macro.Expr;
import ammer.*;

class PatchHl implements Patch {
  final ctx:AmmerContext;

  public function new(ctx:AmmerContext) {
    this.ctx = ctx;
  }

  public function visitMethod(mctx:AmmerMethodPatchContext):ammer.patch.Patch.PatchMethod {
    return new PatchHlMethod(mctx);
  }
}

class PatchHlMethod implements ammer.patch.Patch.PatchMethod {
  final ctx:AmmerMethodPatchContext;
  final argNames:Array<String>;

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
    argNames = ctx.fn.args.map(a -> a.name);
  }

  inline function e(e:ExprDef):Expr {
    return {expr: e, pos: ctx.field.pos};
  }

  inline function id(s:String):Expr {
    return e(EConst(CIdent(s)));
  }

  inline function an(n:String):Expr {
    if (argNames.indexOf(n) == -1)
      throw "no such arg";
    return id('_arg${argNames.indexOf(n)}');
  }

  public function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void {
    switch (ffi) {
      case SizeOfReturn:
        ctx.callArgs[i] = id("_retSize");
        ctx.wrapExpr = macro {
          var _retSize = 0;
          ${ctx.wrapExpr};
        };
        ctx.externArgs.push({
          name: original.name,
          type: (macro : hl.Ref<Int>)
        });
        return;
      case SizeOf(of):
        ctx.callArgs[i] = macro $e{an(of)}.length;
        ctx.externArgs.push({
          name: original.name,
          type: mapTypeHlExtern(ffi)
        });
        return;
      case String:
        ctx.callArgs[i] = macro @:privateAccess $e{id('_arg${i}')}.toUtf8();
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
    switch (ffi) {
      case Bytes:
        ctx.wrapExpr = macro {
          var _retPtr:hl.Bytes = ${ctx.wrapExpr};
          _retPtr.toBytes(_retSize);
        };
      case String:
        ctx.wrapExpr = macro {
          var _retPtr:hl.Bytes = ${ctx.wrapExpr};
          @:privateAccess String.fromUTF8(_retPtr);
        };
      case SameSizeAs(t, arg):
        var ret = visitReturn(t, original);
        ctx.wrapExpr = macro {
          var _retSize = $e{an(arg)}.length;
          ${ctx.wrapExpr};
        };
        return ret;
      case _:
    }
    return original;
  }

  public function mapTypeHlExtern(t:FFIType):ComplexType {
    return (switch (t) {
      case Bool: (macro : Bool);
      case Int: (macro : Int);
      case Bytes | String: (macro : hl.Bytes);
      case SizeOfReturn: (macro : hl.Ref<Int>);
      case SizeOf(_): (macro : Int);
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
      meta: [{
        name: ":hlNative",
        params: [
          {expr: EConst(CString('ammer_${ctx.top.libname}')), pos: ctx.field.pos},
          {expr: EConst(CString(ammer.stub.StubHl.mapMethodName(ctx.name))), pos: ctx.field.pos}
        ],
        pos: ctx.field.pos
      }],
      pos: ctx.field.pos
    });
  }
}
