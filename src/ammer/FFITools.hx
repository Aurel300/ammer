package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

class FFITools {
  static var herePos = (macro null).pos;

  public static var CONSTANT_TYPES:Array<{ffi:FFIType, haxe:ComplexType, name:String}> = [
    {ffi: Integer(Signed32), haxe: (macro : Int), name: "int"},
    // TODO: other integer sizes?
    {ffi: String, haxe: (macro : String), name: "string"},
    {ffi: Bool, haxe: (macro : Bool), name: "bool"},
    {ffi: Float(Float32), haxe: (macro : Float), name: "float"},
    // TODO: other float sizes? default to double?
  ];
  public static var CONSTANT_TYPES_MAP = [ for (t in CONSTANT_TYPES) t.ffi => t ];

  public static function isArgumentType(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _) | Void | Alloc(_): false;
      case _: true;
    });
  }

  public static function isReturnType(t:FFIType):Bool {
    return (switch (t) {
      case SizeOf(_) | SizeOfReturn | Nested(_): false;
      case _: true;
    });
  }

  public static function isVariableType(t:FFIType):Bool {
    return (switch (t) {
      case Integer(_): true;
      case String: true;
      case Bool: true;
      case Float(_): true;
      case LibIntEnum(_, _): true;
      case _: false;
    });
  }

  public static function needsSize(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _): false;
      case /*String | */ Bytes: true;
      case ArrayDynamic(_, _): true;
      case _: false;
    });
  }

  /**
    Maps an FFI type to its syntactic Haxe equivalent.
  **/
  public static function toComplexType(t:FFIType):ComplexType {
    // TODO: this match on platform is not great
    return (switch [t, Ammer.config.platform] {
      case [Void, _]: (macro:Void);
      case [Bool, _]: (macro:Bool);
      case [Integer(Signed8 | Unsigned8), Hl]: (macro:hl.UI8);
      case [Integer(Signed16 | Unsigned16), Hl]: (macro:hl.UI16);
      case [Integer(Signed8), Cpp]: (macro:cpp.Int8);
      case [Integer(Signed16), Cpp]: (macro:cpp.Int16);
      case [Integer(Signed32), Cpp]: (macro:cpp.Int32);
      //case [Integer(Signed64), Cpp]: (macro:cpp.Int64);
      case [Integer(Unsigned8), Cpp]: (macro:cpp.UInt8);
      case [Integer(Unsigned16), Cpp]: (macro:cpp.UInt16);
      case [Integer(Unsigned32), Cpp]: (macro:cpp.UInt32);
      //case [Integer(Unsigned64), Cpp]: (macro:cpp.UInt64);
      case [Integer(Signed64 | Unsigned64), _]: (macro:haxe.Int64);
      case [Integer(_), _]: (macro:Int);
      case [Float(Float64), _]: (macro:Float);
      case [Float(Float32), _]: (macro:Single);
      case [Bytes, _]: (macro:haxe.io.Bytes);
      case [ArrayDynamic(idx, _) | ArrayFixed(idx, _, _), _]: TPath(Ammer.ctx.arrayTypes[idx].wrapperTypePath);
      case [String, _]: (macro:String);
      case [Derived(_, t), _]: toComplexType(t);
      case [WithSize(_, t), _]: toComplexType(t);
      case [Closure(_, args, ret, _), _]: TFunction(args.filter(a -> !a.match(ClosureDataUse)).map(toComplexType), toComplexType(ret));
      case [ClosureDataUse, _]: (macro:Int);
      case [ClosureData(_), _]: (macro:Int); // pass dummy 0
      case [LibType(t, _), _]: TPath(t.implTypePath);
      case [LibIntEnum(t, _), _]: TPath(t.implTypePath);
      case [OutPointer(LibType(t, _)), _]: TPath(t.implTypePath);
      case [Nested(LibType(t, _)), _]: TPath(t.implTypePath);
      case [Alloc(LibType(t, _)), _]: TPath(t.implTypePath);
      case [NoSize(t), _]: toComplexType(t);
      case [SameSizeAs(t, _), _]: toComplexType(t);
      case [SizeOf(_), _]: (macro:Int);
      case [SizeOfReturn, _]: (macro:Int);
      case [SizeOfField(_), _]: (macro:Int);
      case [NativeHl(ct, _, _), _]: ct;
      case [Unsupported(_), _]: (macro:Int); // pass dummy 0
      case _: throw "!";
    });
  }

  public static function toClosureDataUse(t:FFIType, prefix:Array<String>):Array<Array<String>> {
    return (switch (t) {
      case ClosureDataUse: [prefix.copy()];
      case LibType(t, _):
        t.ffiVariables.map(f -> toClosureDataUse(f.type, prefix.concat([f.name]))).flatten();
      case _: [];
    });
  }

  static function defineArrayType(inner:FFIType):Int {
    var idx = -1;
    for (i in 0...Ammer.ctx.arrayTypes.length) {
      if (equal(Ammer.ctx.arrayTypes[i].ffi, inner)) {
        idx = i;
        break;
      }
    }
    if (idx == -1) {
      idx = Ammer.ctx.arrayTypes.length;
      var at:ComplexType = TPath({name: 'AmmerArray_$idx', pack: ["ammer", "externs"]});
      var t = toComplexType(inner);
      var impl = macro class AmmerArray {
        @:ammer.c.return("(%RET_TYPE%)calloc(sizeof(%RET_ELEM_TYPE%), arg_0)")
        public static function alloc(size:Int):$at;
        @:ammer.c.return("arg_0[arg_1]")
        public function get(_:ammer.ffi.This, idx:Int):$t;
        @:ammer.c.return("arg_0[arg_1] = arg_2")
        public function set(_:ammer.ffi.This, idx:Int, val:$t):Void;
      };
      switch (Ammer.config.platform) {
        case Hl:
          impl.fields = impl.fields.concat((macro class {
            @:ammer.c.return("(%RET_TYPE%)(((void **)arg_0)[2])")
            // "(%RET_TYPE%)hl_aptr(arg_0, %RET_ELEM_TYPE%)")
            public static function ofNativeInt(arr:ammer.ffi.NativeHl<std.Array<Int>, "_OBJ(_I32 _BYTES _I32)", "vobj *">):$at;
          }).fields);
        case _:
      }
      impl.pack = ["ammer", "externs"];
      impl.name = 'AmmerArray_$idx';
      impl.kind = TDClass({
        name: "Pointer",
        pack: ["ammer"],
        params: [
          TPExpr(macro $v{'wt_array_${idx}_${Ammer.ctx.index}'}),
          TPType(Ammer.ctx.implComplexType),
        ],
      }, []);
      Ammer.defineType(impl);
      var implTypePath = {name: impl.name, pack: impl.pack};
      Ammer.ctx.arrayTypes.push({
        index: idx,
        ffi: inner,
        implTypePath: implTypePath,
        wrapperTypePath: {
          name: "ArrayWrapper",
          pack: ["ammer", "conv"],
          params: [
            TPType(t),
            TPType(TPath(implTypePath)),
          ],
        },
      });
      Context.resolveType(TPath({name: impl.name, pack: impl.pack}), herePos);
    }
    return idx;
  }

  /**
    Maps a Haxe type (including the special `ammer.ffi.*` types) to its FFI
    type equivalent.
  **/
  // argNames:Array<String>, pos:Position, arg:Null<Int>, ?annotated:Bool = false
  public static function toFFITypeResolved(resolved:Type, ctx:FFIContext):FFIType {
    var ret = null;
    function c(type:ComplexType, ffi:FFIType):Bool {
      if (type == null) {
        return false;
      }
      if (Context.unify(Context.resolveType(type, herePos), resolved)) {
        ret = ffi;
        return true;
      }
      return false;
    }
    c((macro:Void), Void)
    || c((macro:Bool), Bool) // order matters for Float and Int!
    || c((macro:Float), Float(Float64))
    // TODO: disallowing Single completely for Lua is not an ideal solution
    || c(Ammer.config.platform.match(Hl | Cpp) ? (macro:Single) : null, Float(Float32))
    || c((macro:Int), Integer(Signed32)) // also matches UInt
    || c((macro:ammer.ffi.Int8), Integer(Signed8))
    || c((macro:ammer.ffi.Int16), Integer(Signed16))
    || c((macro:ammer.ffi.Int32), Integer(Signed32))
    || c((macro:ammer.ffi.Int64), Integer(Signed64))
    || c((macro:ammer.ffi.UInt8), Integer(Unsigned8))
    || c((macro:ammer.ffi.UInt16), Integer(Unsigned16))
    || c((macro:ammer.ffi.UInt32), Integer(Unsigned32))
    || c((macro:ammer.ffi.UInt64), Integer(Unsigned64))
    || c((macro:ammer.ffi.Float32), Float(Float32))
    || c((macro:ammer.ffi.Float64), Float(Float64))
    || c((macro:String), String)
    || c((macro:haxe.io.Bytes), Bytes)
    || c((macro:ammer.ffi.SizeOfReturn), SizeOfReturn)
    || c((macro:ammer.ffi.This), This)
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
        case [TInst(_.get() => {name: "NativeHl", pack: ["ammer", "ffi"]}, [
          inner,
          TInst(_.get() => {kind: KExpr({expr: EConst(CString(ffiName))})}, []),
          TInst(_.get() => {kind: KExpr({expr: EConst(CString(cName))})}, []),
        ]), _]:
          NativeHl(Context.toComplexType(inner), ffiName, cName);
        case [TInst(_.get() => {name: "ArrayDynamic", pack: ["ammer", "ffi"]}, [inner]), _]:
          var inner = toFFITypeResolved(inner, ctx);
          var idx = defineArrayType(inner);
          ArrayDynamic(idx, inner);
        case [TInst(_.get() => {name: "ArrayFixed", pack: ["ammer", "ffi"]}, [inner, TInst(_.get() => {kind: KExpr({expr: EConst(CInt(Std.parseInt(_) => size))})}, [])]), _]:
          var inner = toFFITypeResolved(inner, ctx);
          var idx = defineArrayType(inner);
          ArrayFixed(idx, inner, size);
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
              index: idx,
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
          if (!inner.match(LibType(_, _) | This))
            Context.fatalError("Nested must wrap a pointer type", ctx.pos);
          Nested(inner);
        case [TInst(_.get() => {name: "Alloc", pack: ["ammer", "ffi"]}, [inner]), _]:
          var inner = toFFITypeResolved(inner, ctx);
          if (!inner.match(LibType(_, _)))
            Context.fatalError("Alloc must wrap a pointer type", ctx.pos);
          Alloc(inner);
        case [TInst(_.get() => {name: "Unsupported", pack: ["ammer", "ffi"]}, [
          TInst(_.get() => {kind: KExpr({expr: EConst(CString(cName))})}, []),
        ]), _]:
          Unsupported(cName);
        case [TInst(_.get() => type, []), _] if (type.superClass != null):
          switch (type.superClass.t.get()) {
            case {name: "PointerProcessed", module: "ammer.Pointer"}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, Pointer(true));
              LibType(Ammer.typeMap[id], false);
            case {name: "PointerNoStarProcessed", module: "ammer.PointerNoStar"}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, Pointer(false));
              LibType(Ammer.typeMap[id], false);
            case {name: "IntEnumProcessed", module: "ammer.IntEnum"}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, IntEnum);
              LibIntEnum(Ammer.typeMap[id], false);
            case {name: "Sublibrary", pack: ["ammer"]}:
              var id = Utils.typeId(type);
              if (!Ammer.typeMap.exists(id))
                Ammer.delayedBuildType(id, type, Sublibrary);
              LibSub(Ammer.typeMap[id]);
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

  public static function toFFITypeFunction(
    args:Array<{name:String, type:ComplexType}>,
    ret:ComplexType,
    pos:Position,
    ?typeThis:String
  ):{args:Array<FFIType>, ret:FFIType} {
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

    var ffiThis:FFIType = null;
    if (typeThis != null) {
      ffiThis = (switch (Ammer.typeMap[typeThis].kind) {
        case IntEnum: FFIType.LibIntEnum(Ammer.typeMap[typeThis], true);
        case _: FFIType.LibType(Ammer.typeMap[typeThis], true);
      });
    }

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
        // resolve ammer.ffi.This
        if (type.match(Nested(This))) {
          if (typeThis == null)
            Context.fatalError('ammer.ffi.This can only be used in library type methods', pos);
          FFIType.Nested(ffiThis);
        } else if (type == This) {
          if (typeThis == null)
            Context.fatalError('ammer.ffi.This can only be used in library type methods', pos);
          ffiThis;
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
      ffiRet = ffiThis;
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
      // TODO: eventually support size_t/64-bit
      case SizeOf(arg): Derived(macro ($e{Utils.arg(arg)}.length:Int), Integer(Signed32));
      case _: t;
    });
  }

  public static function equal(a:FFIType, b:FFIType):Bool {
    return (switch [a, b] {
      case [Void, Void]: true;
      case [Bool, Bool]: true;
      case [Integer(a), Integer(b)]: a == b;
      case [Float(a), Float(b)]: a == b;
      case [Bytes, Bytes]: true;
      case [String, String]: true;
      case [This, This]: true;
      case [LibType(a, at), LibType(b, bt)]: a == b && at == bt;
      case [LibIntEnum(a, at), LibIntEnum(b, bt)]: a == b && at == bt;
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
