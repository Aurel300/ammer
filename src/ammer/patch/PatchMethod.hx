package ammer.patch;

import haxe.macro.Expr;
import haxe.macro.ExprTools;

using StringTools;
using ammer.FFITools;

// TODO: commonPatchArgument almost the same as commonUnpatchReturn
// same for UnpatchArgument and PatchReturn
class PatchMethod {
  public static function commonPatchArgument(e:Expr, t:FFIType):Expr {
    return (switch (t) {
      case NoSize(t):
        commonPatchArgument(e, t);
      case Bytes:
        macro($e : ammer.conv.Bytes).toNative1();
      case String:
        macro($e : ammer.conv.CString).toNative();
      case ArrayFixed(_, _, _):
        macro @:privateAccess $e.ammerNative;
      case LibType(_, _) | Nested(LibType(_, _)) | Alloc(LibType(_, _)):
        macro @:privateAccess $e.ammerNative;
      case LibIntEnum(_):
        macro @:privateAccess $e.ammerNative;
      case Closure(_, args, ret, _):
        commonPatchClosure(e, args, ret);
      case WithSize(_, t):
        commonPatchArgument(e, t);
      case _:
        e;
    });
  }

  public static function commonUnpatchArgument(e:Expr, t:FFIType):Expr {
    return (switch (t) {
      case WithSize(size, Bytes):
        macro ammer.conv.Bytes.fromNative(cast $e, $size);
      case String:
        macro ammer.conv.CString.fromNative($e);
      case ArrayFixed(t, _, _):
        var implTypePath = Ammer.ctx.arrayTypes[t].implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibType(t, _) | Nested(LibType(t, _)) | Alloc(LibType(t, _)):
        var implTypePath = t.implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibIntEnum(t):
        macro @:privateAccess $p{Utils.access(t.implType, "ammerFromNative")}($e);
      case _:
        e;
    });
  }

  public static function commonPatchReturn(e:Expr, t:FFIType):Expr {
    return (switch (t) {
      case WithSize(size, Bytes):
        macro ammer.conv.Bytes.fromNative(cast $e, $size);
      case String:
        macro ammer.conv.CString.fromNative($e);
      case ArrayFixed(t, _, _):
        var implTypePath = Ammer.ctx.arrayTypes[t].implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibType(t, _) | Nested(LibType(t, _)) | Alloc(LibType(t, _)):
        var implTypePath = t.implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibIntEnum(t):
        macro @:privateAccess $p{Utils.access(t.implType, "ammerFromNative")}($e);
      case SameSizeAs(t, arg):
        commonPatchReturn(e, WithSize(macro $e{Utils.arg(arg)}.length, t));
      case _:
        e;
    });
  }

  public static function commonUnpatchReturn(e:Expr, t:FFIType):Expr {
    return (switch (t) {
      case NoSize(t):
        commonUnpatchReturn(e, t);
      case Bytes:
        macro($e : ammer.conv.Bytes).toNative1();
      case String:
        macro($e : ammer.conv.CString).toNative();
      case ArrayFixed(_, _, _):
        macro @:privateAccess $e.ammerNative;
      case LibType(_, _) | Nested(LibType(_, _)) | Alloc(LibType(_, _)):
        macro @:privateAccess $e.ammerNative;
      case LibIntEnum(_):
        macro @:privateAccess $e.ammerNative;
      case Closure(_, args, ret, _):
        throw "too deep";
      case WithSize(_, t):
        commonUnpatchReturn(e, t);
      case _:
        e;
    });
  }

  public static function commonPatchClosure(original:Expr, args:Array<FFIType>, ret:FFIType):Expr {
    var norm = args.map(FFITools.normalise).filter(a -> !a.match(Derived(_, _) | SizeOfReturn | ClosureDataUse | ClosureData(_)));
    var normRet = FFITools.normalise(ret);
    var callArgs = [ for (i in 0...norm.length) Utils.arg(i) ];
    var wrapExpr = macro _closure($a{callArgs});
    // unpatch return
    wrapExpr = commonUnpatchReturn(wrapExpr, ret);
    wrapExpr = macro return $wrapExpr;
    // unpatch args
    for (i in 0...norm.length) {
      callArgs[i] = commonUnpatchArgument(callArgs[i], norm[i]);
    }
    return {
      expr: EFunction(FAnonymous, {
        args: [ for (i in 0...norm.length) {
          name: '_carg$i',
          type: (switch (Ammer.config.platform) {
            case Cpp: ammer.patch.PatchCpp.PatchCppMethod.mapType;
            case Hl: ammer.patch.PatchHl.PatchHlMethod.mapType;
            case Lua: ammer.patch.PatchLua.PatchLuaMethod.mapType;
            case _: mapType;
          })(norm[i])
        } ],
        expr: ExprTools.map(wrapExpr, function walk(e:Expr):Expr {
          return (switch (e.expr) {
            case EConst(CIdent(n)) if (n.startsWith("_arg")):
              {expr: EConst(CIdent('_carg${n.substr(4)}')), pos: e.pos};
            case EConst(CIdent("_closure")): original;
            case _: ExprTools.map(e, walk);
          });
        }),
        ret: (switch (Ammer.config.platform) {
          case Cpp: ammer.patch.PatchCpp.PatchCppMethod.mapType;
          case Hl: ammer.patch.PatchHl.PatchHlMethod.mapType;
          case Lua: ammer.patch.PatchLua.PatchLuaMethod.mapType;
          case _: mapType;
        })(normRet)
      }),
      pos: original.pos
    };
  }

  final ctx:AmmerMethodPatchContext;
  final externArgs:Array<FunctionArg> = [];

  public function new(ctx:AmmerMethodPatchContext) {
    this.ctx = ctx;
  }

  public function visitArgument(i:Int, ffi:FFIType):Void {
    externArgs.push({
      name: '_arg$i',
      type: (switch (Ammer.config.platform) {
        case Cpp: ammer.patch.PatchCpp.PatchCppMethod.mapType;
        case Hl: ammer.patch.PatchHl.PatchHlMethod.mapType;
        case Lua: ammer.patch.PatchLua.PatchLuaMethod.mapType;
        case _: mapType;
      })(ffi)
    });
  }

  public function finish():Void {}

  public static function mapType(t:FFIType):ComplexType {
    return (switch (t) {
      case Derived(_, t) | NoSize(t) | SameSizeAs(t, _): mapType(t);
      case Closure(idx, args, ret, mode):
        TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(mapType), mapType(ret));
      case _: t.toComplexType();
    });
  }
}
