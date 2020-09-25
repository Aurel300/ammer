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
      /*
      // dense arrays
      case Array(t = (Int)):
        var ct = t.toComplexType();
        macro($e : ammer.conv.CArray<$ct>).toNative1();
      // mapped arrays
      case WithSize(size, Array(t)):
        macro {
          var orig = $e;
          var native:cpp.Pointer<cpp.ConstCharStar> = cpp.Pointer.fromStar((cpp.Native.malloc(orig.length):cpp.Star<cpp.ConstCharStar>));
          for (i in 0...orig.length) {
            var ref:cpp.Reference<cpp.ConstCharStar> = native.at(i);
            ref = ${commonPatchArgument(macro orig[i], t)};
          }
          $size = orig.length;
          native.ptr;
        };
      */
      /*
        var ct = t.toComplexType();
        var mct = ammer.patch.PatchCpp.PatchCppMethod.mapType(t);
        macro(($e.map(el -> $e{commonPatchArgument(macro el, t)})) : ammer.conv.CArray<$mct>).toNative1();
      */
      case String:
        macro($e : ammer.conv.CString).toNative();
      case LibType(_, _) | Nested(LibType(_, _)):
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
      // dense arrays
      case WithSize(size, Array(t = (Int))): // TODO: add other dense types
        var ct = t.toComplexType();
        macro (ammer.conv.CArray.fromNative(cast $e, $size) : ammer.conv.CArray<$ct>);
      // mapped arrays
      /*
      case WithSize(size, Array(t)):
        var ct = t.toComplexType();
        macro {
          var native:cpp.Pointer<cpp.ConstCharStar> = cpp.Pointer.fromStar($e);
          var ret = new haxe.ds.Vector<$ct>($size);
          for (i in 0...ret.length) {
            ret[i] = $e{commonUnpatchArgument(macro native.at(i), t)};
          }
          ret;
        };
      */
      case String:
        macro ammer.conv.CString.fromNative($e);
      case LibType(oid, _) | Nested(LibType(oid, _)):
        var implTypePath = Ammer.typeMap[oid].implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibIntEnum(oid):
        var implTypePath = Ammer.typeMap[oid].implTypePath;
        var fromNative = implTypePath.pack.concat([implTypePath.name]);
        if (implTypePath.sub != null) fromNative.push(implTypePath.sub);
        fromNative.push("ammerFromNative");
        macro @:privateAccess $p{fromNative}($e);
      case _:
        e;
    });
  }

  public static function commonPatchReturn(e:Expr, t:FFIType):Expr {
    return (switch (t) {
      case WithSize(size, Bytes):
        macro ammer.conv.Bytes.fromNative(cast $e, $size);
      // dense arrays
      case WithSize(size, Array(t = (Int))): // TODO: add other dense types
        var ct = t.toComplexType();
        macro (ammer.conv.CArray.fromNative(cast $e, $size) : ammer.conv.CArray<$ct>);
      // mapped arrays
      /*
      case WithSize(size, Array(t)):
        var ct = t.toComplexType();
        macro {
          var native:cpp.Pointer<cpp.ConstCharStar> = cpp.Pointer.fromStar($e);
          var ret = new haxe.ds.Vector<$ct>($size);
          for (i in 0...ret.length) {
            ret[i] = $e{commonPatchReturn(macro native.at(i), t)};
          }
          ret;
        };*/
        /*
        var ct = t.toComplexType();
        var mct = ammer.patch.PatchCpp.PatchCppMethod.mapType(t);
        macro ((ammer.conv.CArray.fromNative(cast $e, $size) : ammer.conv.CArray<$mct>)
          : haxe.ds.Vector<$mct>)
          .map(el -> $e{commonUnpatchArgument(macro el, t)});
        */
      case String:
        macro ammer.conv.CString.fromNative($e);
      case LibType(oid, _) | Nested(LibType(oid, _)):
        var implTypePath = Ammer.typeMap[oid].implTypePath;
        macro @:privateAccess new $implTypePath($e);
      case LibIntEnum(oid):
        var implTypePath = Ammer.typeMap[oid].implTypePath;
        var fromNative = implTypePath.pack.concat([implTypePath.name]);
        if (implTypePath.sub != null) fromNative.push(implTypePath.sub);
        fromNative.push("ammerFromNative");
        macro @:privateAccess $p{fromNative}($e);
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
      // dense arrays
      case Array(t = (Int)):
        var ct = t.toComplexType();
        macro($e : ammer.conv.CArray<$ct>).toNative1();
      // mapped arrays
      /*
      case WithSize(size, Array(t)):
        macro {
          var orig = $e;
          var native:cpp.Pointer<cpp.ConstCharStar> = cpp.Pointer.fromStar((cpp.Native.malloc(orig.length):cpp.Star<cpp.ConstCharStar>));
          for (i in 0...orig.length) {
            var ref:cpp.Reference<cpp.ConstCharStar> = native.at(i);
            ref = ${commonUnpatchReturn(macro orig[i], t)};
          }
          $size = orig.length;
          native.ptr;
        };*/
        /*
        var ct = t.toComplexType();
        macro(($e.map(el -> $e{commonPatchArgument(macro el, t)})) : ammer.conv.CArray<$ct>).toNative1();
        */
      case LibType(_, _) | Nested(LibType(_, _)):
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
    var callArgs = [ for (i in 0...norm.length) Utils.arg(i) ];
    var wrapExpr = macro return _closure($a{callArgs});
    // unpatch return
    wrapExpr = commonUnpatchReturn(wrapExpr, ret);
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
        ret: ret.toComplexType()
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
