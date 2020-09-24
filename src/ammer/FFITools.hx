package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

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
      case Single: true;
      case LibIntEnum(_): true;
      case _: false;
    });
  }

  public static function needsSize(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _): false;
      case /*String | */ Bytes: true;
      case Array(_): true;
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
      case I8(_): (macro:Int);
      case Float: (macro:Float);
      case Single: (macro:Single);
      case Bytes: (macro:haxe.io.Bytes);
      case Array(t): TPath({pack: ["haxe", "ds"], name: "Vector", params: [TPType(toComplexType(t))]});
      case String: (macro:String);
      case Derived(_, t): toComplexType(t);
      case WithSize(_, t): toComplexType(t);
      case Closure(_, args, ret, _): TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(toComplexType), toComplexType(ret));
      case ClosureDataUse: (macro:Int);
      case ClosureData(_): (macro:Int); // pass dummy 0
      case LibType(id, _): TPath(Ammer.typeMap[id].implTypePath);
      case LibIntEnum(id): TPath(Ammer.typeMap[id].implTypePath);
      case OutPointer(LibType(id, _)): TPath(Ammer.typeMap[id].implTypePath);
      case Nested(LibType(id, _)): TPath(Ammer.typeMap[id].implTypePath);
      case NoSize(t): toComplexType(t);
      case SameSizeAs(t, _): toComplexType(t);
      case SizeOf(_): (macro:Int);
      case SizeOfReturn: (macro:Int);
      case SizeOfField(_): (macro:Int);
      case _: throw "!";
    });
  }

  public static function toClosureDataUse(t:FFIType, prefix:Array<String>):Array<Array<String>> {
    return (switch (t) {
      case ClosureDataUse: [prefix.copy()];
      case LibType(id, _):
        Ammer.typeMap[id].ffiVariables.map(f -> toClosureDataUse(f.type, prefix.concat([f.name]))).flatten();
      case _: [];
    });
  }

  /**
    Maps a Haxe type (including the special `ammer.ffi.*` types) to its FFI
    type equivalent.
  **/
  // argNames:Array<String>, pos:Position, arg:Null<Int>, ?annotated:Bool = false
  public static function toFFITypeResolved(resolved:Type, ctx:FFIContext):FFIType {
    var herePos = (macro null).pos;
    var ret = null;
    function c(type:ComplexType, ffi:FFIType):Bool {
      if (Context.unify(Context.resolveType(type, herePos), resolved)) {
        ret = ffi;
        return true;
      }
      return false;
    }
    c((macro:Void), Void)
    || c((macro:Bool), Bool) // order matters for Float and Int!
    || c((macro:Float), Float)
    || c((macro:Single), Single)
    || c((macro:Int), Int) // also matches UInt
    || c((macro:String), String)
    || c((macro:haxe.io.Bytes), Bytes)
    || c((macro:ammer.ffi.SizeOfReturn), SizeOfReturn)
    || c((macro:ammer.ffi.This), This)
    || c((macro:ammer.ffi.Int8), I8(null))
    || {
      ret = (switch [resolved, ctx] {
        // context dependent (function signatures)
        case [
          TInst(_.get() => {name: "SameSizeAs", pack: ["ammer", "ffi"]}, [inner, TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]),
          {type: FunctionArgument(_, _, {argNames: argNames}) | FunctionReturn({argNames: argNames})}
        ]:
          SameSizeAs(toFFITypeResolved(inner, ctx), argNames.indexOf(argName));
        case [
          TInst(_.get() => {name: "SizeOf", pack: ["ammer", "ffi"]}, [TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]),
          {type: FunctionArgument(_, _, {argNames: argNames}) | FunctionReturn({argNames: argNames})}
        ]:
          SizeOf(argNames.indexOf(argName));
        case [
          TInst(_.get() => {name: "ClosureData", pack: ["ammer", "ffi"]}, [TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]),
          {type: FunctionArgument(_, _, {argNames: argNames}) | FunctionReturn({argNames: argNames})}
        ]:
          ClosureData(argNames.indexOf(argName));
        // context dependent (struct members)
        case [
          TInst(_.get() => {name: "SizeOf", pack: ["ammer", "ffi"]}, [TInst(_.get() => {kind: KExpr({expr: EConst(CString(fieldName))})}, [])]),
          {type: LibType}
        ]:
          SizeOfField(fieldName);
        // context independent
        case [TInst(_.get() => {name: "Array", pack: ["ammer", "ffi"]}, [inner]), _]:
          Array(toFFITypeResolved(inner, ctx));
        case [TInst(_.get() => {name: "NoSize", pack: ["ammer", "ffi"]}, [inner]), _]:
          NoSize(toFFITypeResolved(inner, ctx));
        case [
          TInst(_.get() => {name: "Closure", pack: ["ammer", "ffi"]}, [
            Context.follow(_) => TFun(args, ret),
            TInst(_.get() => {kind: KExpr({expr: EConst(CString(mode = ("none" | "once" | "forever")))})}, [])
          ]),
          _
        ]:
          var ffi = toFFITypeFunction(args.map(a -> {name: a.name, type: Context.toComplexType(a.t)}), Context.toComplexType(ret), ctx.pos, ctx.typeThis);
          // check if the closure type exists already
          var idx = -1;
          for (i in 0...Ammer.ctx.closureTypes.length) {
            var closureType = Ammer.ctx.closureTypes[i];
            if (ffi.args.length != closureType.args.length)
              continue;
            var argsMatch = true;
            for (i in 0...ffi.args.length) {
              if (!equal(ffi.args[i], closureType.args[i])) {
                argsMatch = false;
                break;
              }
            }
            if (!argsMatch)
              continue;
            if (!equal(ffi.ret, closureType.ret))
              continue;
            idx = i;
            break;
          }
          if (idx == -1) {
            var data = ffi.args.mapi((i, a) -> toClosureDataUse(a, ['arg_$i'])).flatten();
            if (data.length != 1) {
              trace(args, ret, data);
              Context.fatalError('closure type must have exactly one occurrence of ClosureDataUse', ctx.pos);
            }
            idx = Ammer.ctx.closureTypes.length;
            Ammer.ctx.closureTypes.push({
              args: ffi.args,
              ret: ffi.ret,
              dataAccess: data[0]
            });
          }
          Closure(idx, ffi.args, ffi.ret, switch (mode) {
            case "none": None;
            case "once": Once;
            case "forever": Forever;
            case _: throw "!";
          });
        case [TInst(_.get() => {name: "ClosureDataUse", pack: ["ammer", "ffi"]}, []), _]:
          ClosureDataUse;
        case [TInst(_.get() => {name: "OutPointer", pack: ["ammer", "ffi"]}, [inner]), _]:
          var inner = toFFITypeResolved(inner, ctx);
          if (!inner.match(LibType(_, _)))
            Context.fatalError("OutPointer must wrap a pointer type", ctx.pos);
          OutPointer(inner);
        case [TInst(_.get() => {name: "Nested", pack: ["ammer", "ffi"]}, [inner]), _]:
          var inner = toFFITypeResolved(inner, ctx);
          if (!inner.match(LibType(_, _)))
            Context.fatalError("Nested must wrap a pointer type", ctx.pos);
          Nested(inner);
        case [TInst(_.get() => type, []), _] if (type.superClass != null):
          switch (type.superClass.t.get()) {
            case {name: "PointerProcessed", module: "ammer.Pointer"}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, Pointer);
              LibType(id, false);
            case {name: "IntEnumProcessed", module: "ammer.IntEnum"}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, IntEnum);
              LibIntEnum(id);
            case {name: "Sublibrary", pack: ["ammer"]}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, Sublibrary);
              LibSub(id);
            case _:
              null;
          }
        case [TType(_, []), _]:
          // TODO: get rid of this case;
          // handle resolution failure errors in a method wrapping this
          // so that toFFIType can be properly used in Ammer.registerType()
          // even if it returns an "invalid" type
          // also get rid of LibSub
          LibSub(null);
        case _:
          null;
      });
      true;
    };

    // TODO: validate annotations if final return

    if (ret == null) {
      Context.fatalError(switch (ctx.type) {
        case None: "invalid FFI type";
        case FunctionReturn(_): "invalid FFI type for return";
        case FunctionArgument(arg, _, _): 'invalid FFI type for argument $arg';
        case Function(_): "invalid FFI type in function";
        case LibType: "invalid FFI type in library data type";
      }, ctx.pos);
    }

    return ret;
  }

  /**
    Resolves a Haxe syntactic type at the given position, then maps it to its
    FFI type equivalent.
  **/
  public static function toFFIType(t:ComplexType, ctx:FFIContext):FFIType {
    return toFFITypeResolved(Context.resolveType(t, ctx.pos), ctx); // argNames, pos, arg);
  }

  public static function toFFITypeFunction(args:Array<{name:String, type:ComplexType}>, ret:ComplexType, pos:Position,
      ?typeThis:String):{args:Array<FFIType>, ret:FFIType} {
    var argNames:Array<String> = args.map(a -> a.name);
    var needsSizes = [];
    var hasSizes = [];
    var sizeArgs = new Map<Int, Expr>();
    var ffiCtxSub:FFIContextFunction = {
      args: args,
      ret: ret,
      argNames: argNames,
      needsSizes: needsSizes,
      hasSizes: hasSizes,
    };
    var ffiCtx:FFIContext = {
      pos: pos,
      parent: null,
      typeThis: typeThis,
      type: Function(ffiCtxSub)
    };

    // map arguments
    var ffiArgs = [
      for (i in 0...args.length) {
        var arg = args[i];
        if (arg.type == null)
          Context.fatalError('type required for argument ${arg.name}', pos);
        var type = FFITools.toFFIType(arg.type, {
          pos: pos,
          parent: ffiCtx,
          typeThis: typeThis,
          type: FunctionArgument(arg.name, i, ffiCtxSub)
        });
        if (!type.isArgumentType())
          Context.fatalError('FFI type not allowed for argument ${arg.name}', pos);
        if (type.needsSize()) {
          // a size specification would be ambiguous
          var prev = argNames.indexOf(arg.name);
          if (prev != -1 && prev < i)
            Context.fatalError('argument ${arg.name} should have a unique identifier', pos);
          needsSizes.push(i);
        }
        switch (type) {
          case NoSize(_):
            if (hasSizes.indexOf(i) != -1)
              Context.fatalError('size of ${arg.name} is already specified in a prior argument', pos);
            hasSizes.push(i);
          case SizeOf(j):
            if (hasSizes.indexOf(j) != -1)
              Context.fatalError('size of ${args[j].name} is already specified in a prior argument', pos);
            hasSizes.push(j);
            sizeArgs[j] = Utils.arg(i);
          case SizeOfReturn:
            if (hasSizes.indexOf(-1) != -1)
              Context.fatalError('size of return is already specified in a prior argument', pos);
            hasSizes.push(-1);
            sizeArgs[-1] = macro _retSize;
          case _:
        }
        if (type == This) {
          if (typeThis == null)
            Context.fatalError('ammer.ffi.This can only be used in library type methods', pos);
          FFIType.LibType(typeThis, true);
        } else
          type;
      }
    ];

    // map return type
    if (ret == null)
      Context.fatalError('return type required', pos);
    var ffiRet = FFITools.toFFIType(ret, {
      pos: pos,
      parent: ffiCtx,
      typeThis: typeThis,
      type: FunctionReturn(ffiCtxSub)
    });
    if (!ffiRet.isReturnType())
      Context.fatalError('FFI type not allowed for return', pos);
    if (ffiRet.needsSize())
      needsSizes.push(-1);
    if (ffiRet == This) {
      if (typeThis == null)
        Context.fatalError('ammer.ffi.This can only be used in library type methods', pos);
      // TODO: does This as return type make sense?
      ffiRet = LibType(typeThis, true);
    }

    // ensure all size requirements are satisfied
    for (need in needsSizes) {
      if (hasSizes.indexOf(need) == -1)
        if (need == -1)
          Context.fatalError('size specification required for return', pos);
        else
          Context.fatalError('size specification required for argument ${args[need].name}', pos);
      hasSizes.remove(need);
    }
    // if (hasSizes.length > 0)
    //  Context.fatalError('superfluous sizes specified', pos);

    // map size requirements to WithSize
    for (i in 0...args.length) {
      if (ffiArgs[i].needsSize()) {
        ffiArgs[i] = WithSize(sizeArgs[i], ffiArgs[i]);
      }
    }
    if (ffiRet.needsSize()) {
      ffiRet = WithSize(sizeArgs[-1], ffiRet);
    }

    return {args: ffiArgs, ret: ffiRet};
  }

  public static function toFFITypeFunctionF(field:Field, f:Function, ?typeThis:String):{args:Array<FFIType>, ret:FFIType} {
    return toFFITypeFunction(f.args, f.ret, field.pos, typeThis);
  }

  public static function toFFITypeVariable(field:Field, ct:ComplexType):FFIType {
    return FFITools.toFFIType(ct, {
      pos: field.pos,
      parent: null,
      type: None
    });
  }

  public static function normalise(t:FFIType):FFIType {
    return (switch (t) {
      case This: throw "!";
      case SizeOf(arg): Derived(macro $e{Utils.arg(arg)}.length, Int);
      case _: t;
    });
  }

  public static function equal(a:FFIType, b:FFIType):Bool {
    return (switch [a, b] {
      case [Void, Void]: true;
      case [Bool, Bool]: true;
      case [Int, Int]: true;
      case [I8(a), I8(b)]: a == b;
      case [I16(a), I16(b)]: a == b;
      case [I32(a), I32(b)]: a == b;
      case [I64(a), I64(b)]: a == b;
      case [UI8(a), UI8(b)]: a == b;
      case [UI16(a), UI16(b)]: a == b;
      case [UI32(a), UI32(b)]: a == b;
      case [UI64(a), UI64(b)]: a == b;
      case [Float, Float]: true;
      case [Single, Single]: true;
      case [Bytes, Bytes]: true;
      case [String, String]: true;
      case [This, This]: true;
      case [LibType(a, at), LibType(b, bt)]: a == b && at == bt;
      case [LibIntEnum(a), LibIntEnum(b)]: a == b;
      case [Derived(_, a), Derived(_, b)]: equal(a, b);
      case [Closure(a, _, _, am), Closure(b, _, _, bm)]: am == bm && a == b;
      case [ClosureDataUse, ClosureDataUse]: true;
      case [ClosureData(a), ClosureData(b)]: a == b;
      case [NoSize(a), NoSize(b)]: equal(a, b);
      case [SameSizeAs(a, ai), SameSizeAs(b, bi)]: ai == bi && equal(a, b);
      case [SizeOf(a), SizeOf(b)]: a == b;
      case [SizeOfReturn, SizeOfReturn]: true;
      case [SizeOfField(a), SizeOfField(b)]: a == b;
      case _: false;
    });
  }
}

typedef FFIContext = {
  pos:Position,
  parent:FFIContext,
  ?typeThis:String,
  type:FFIContextType,
};

enum FFIContextType {
  None;
  FunctionReturn(ctx:FFIContextFunction);
  FunctionArgument(arg:String, argIdx:Int, ctx:FFIContextFunction);
  Function(ctx:FFIContextFunction);
  LibType;
}

typedef FFIContextFunction = {
  args:Array<{name:String, type:ComplexType}>,
  ret:ComplexType,
  argNames:Array<String>,
  // -1 in the needsSizes and hasSizes arrays signifies the return
  needsSizes:Array<Int>,
  hasSizes:Array<Int>,
};
