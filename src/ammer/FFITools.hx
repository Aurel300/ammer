package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class FFITools {
  public static function isArgumentType(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _) | Void: false;
      case _: true;
    });
  }

  public static function isReturnType(t:FFIType):Bool {
    return (switch (t) {
      case SizeOf(_) | SizeOfReturn: false;
      case _: true;
    });
  }

  public static function isVariableType(t:FFIType):Bool {
    return (switch (t) {
      case Int: true;
      case String: true;
      case Bool: true;
      case Float: true;
      case _: false;
    });
  }

  public static function needsSize(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _): false;
      case /*String | */Bytes: true;
      case _: false;
    });
  }

  /**
    Maps an FFI type to its syntactic Haxe equivalent.
  **/
  public static function toComplexType(t:FFIType):ComplexType {
    return (switch (t) {
      case Void: (macro:Void);
      case Bool: (macro:Bool);
      case Int: (macro:Int);
      case Float: (macro:Float);
      case Bytes: (macro:haxe.io.Bytes);
      case String: (macro:String);
      case Derived(_, t): toComplexType(t);
      case Function(args, ret, _): TFunction(args.map(toComplexType), toComplexType(ret));
      case LibType(id, _): (macro:Dynamic); // Ammer.typeMap[id].nativeType;
      case NoSize(t): toComplexType(t);
      case SameSizeAs(t, _): toComplexType(t);
      case SizeOf(_): (macro:Int);
      case SizeOfReturn: (macro:Int);
      case _: throw "!";
    });
  }

  /**
    Maps a Haxe type (including the special `ammer.ffi.*` types) to its FFI
    type equivalent. Only allows FFI type wrappers if `annotated` is `false`
    (this prevents malformed FFI types like `SameSizeAs(SameSizeAs(...), ...)`).
  **/
  public static function toFFITypeResolved(resolved:Type, field:Field, arg:Null<Int>, ?annotated:Bool = false):FFIType {
    var pos = (macro null).pos;
    var ret = null;
    function c(type:ComplexType, ffi:FFIType):Bool {
      if (Context.unify(Context.resolveType(type, pos), resolved)) {
        ret = ffi;
        return true;
      }
      return false;
    }
    var fieldFun = (switch (field.kind) {
      case FFun(f): f;
      case _: null;
    });
    c((macro:Void), Void)
    || c((macro:Bool), Bool) // order matters for Float and Int!
    || c((macro:Float), Float)
    || c((macro:Int), Int) // also matches UInt
    || c((macro:String), String)
    || c((macro:haxe.io.Bytes), Bytes)
    || c((macro:ammer.ffi.SizeOfReturn), SizeOfReturn)
    || c((macro:ammer.ffi.This), This)
    || {
      ret = (switch (resolved) {
        case TInst(_.get() => {name: "NoSize", pack: ["ammer", "ffi"]}, [inner]) if (!annotated):
          NoSize(toFFITypeResolved(inner, field, arg, true));
        case TInst(_.get() => {name: "SameSizeAs", pack: ["ammer", "ffi"]},
          [inner, TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]) if (!annotated):
          SameSizeAs(toFFITypeResolved(inner, field, arg, true), fieldFun.args.map(a -> a.name).indexOf(argName));
        case TInst(_.get() => {name: "SizeOf", pack: ["ammer", "ffi"]},
          [TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]) if (!annotated):
          SizeOf(fieldFun.args.map(a -> a.name).indexOf(argName));
        case TInst(_.get() => {name: "RootOnce", module: "ammer.ffi.Gc"}, [TFun(args, ret)]):
          Function(args.map(a -> toFFITypeResolved(a.t, field, arg, true)), toFFITypeResolved(ret, field, arg, true), Once);
        case TInst(_.get() => type, []) if (!annotated && type.superClass != null):
          switch (type.superClass.t.get()) {
            case {name: "Pointer", pack: ["ammer"]}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type);
              LibType(id, false);
            case _:
              null;
          }
        case _:
          null;
      });
      true;
    };

    if (ret == null) {
      if (arg == null)
        Context.fatalError('invalid FFI type for the return type of ${field.name}', field.pos);
      else
        Context.fatalError('invalid FFI type for argument ${fieldFun.args[arg].name} of ${field.name}', field.pos);
    }

    return ret;
  }

  /**
    Resolves a Haxe syntactic type at the given position, then maps it to its
    FFI type equivalent.
  **/
  public static function toFFIType(t:ComplexType, field:Field, arg:Null<Int>):FFIType {
    return toFFITypeResolved(Context.resolveType(t, field.pos), field, arg);
  }

  public static function normalise(t:FFIType):FFIType {
    return (switch (t) {
      case This: throw "!";
      // case LibType(_, true): Derived(_ -> macro this.ammerNative, t);
      case SizeOf(arg): Derived(_ -> macro $e{Utils.arg(arg)}.length, Int);
      case _: t;
    });
  }
}
