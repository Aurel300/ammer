package ammer.internal;

#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.io.Path;
import ammer.core.utils.TypeUtils;

using Lambda;

/**
  Various entrypoints into `ammer` processing from user-defined types extending
  the marker types from `ammer.def.*`, as well as some standard library types.

  The methods in this class can be categorised as follows:
  - `genericBuild...` methods for `ammer.ffi.*` types.
    (`...Array`, `...Box`, `...HaxeRef`)
    These are invoked via `@:genericBuild` on marker types in the `ammer.ffi.*`
    package. The method creates a monomorphisation of the requested type (e.g.
    an array of 32-bit integers).
  - `genericBuild...` methods for `ammer.def.*` types.
    (`...Library`, `...Opaque`, `...Struct`, `...Sublibrary`)
    These exist to attach a marker type to be used as a superclass for the
    user-declared type. No processing is performed here except for validating
    the type parameters.
  - `autoBuild...` methods for "processed" types.
    (`...Library`, `...Opaque`, `...Struct`, `...Sublibrary`)
    These are invoked via `@:autoBuild` on the type resulting from the previous
    category. The actual processing of user-declared types is performed here.
  - `build...` methods for `ammer.def.*` types.
    (`...Enum`)
    These are invoked with a direct `@:build` metadata on a user-declared type.
**/
class Entrypoint {
  public static function genericBuildArray():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.ffi.Array<El>
      case TInst(_, [el]):
        var el = TypeTools.followWithAbstracts(el);
        var elId = Utils.typeId2(el);
        if (Ammer.mergedInfo.arrays.byElementTypeId.exists(elId)) {
          return Ammer.mergedInfo.arrays.byElementTypeId[elId].arrayCt;
        }
        Reporting.log('enter genericBuildArray $elId', "stage-ffi");

        Ammer.initSubtype('ammer.ffi.Array<$elId>', el, ctx -> {
          // was it initialised in the meanwhile?
          if (Ammer.mergedInfo.arrays.byElementTypeId.exists(elId)) {
            return Ammer.mergedInfo.arrays.byElementTypeId[elId].arrayCt;
          }
          Reporting.log('process genericBuildArray $elId', "stage-ffi");

          var elRes = Types.resolveType(el, ctx);

          (elRes.wrap == null && elRes.unwrap == null) || throw Reporting.error("unsupported array element type");
          var elCt = elRes.haxeType;
          var marshal = ctx.marshal.arrayPtr(elRes.marshal);

          var arrayTp:TypePath = {
            name: 'Array_${elRes.marshal.mangled}',
            pack: ["ammer", "gen"],
          };
          var arrayCt = TPath(arrayTp);

          // force the box type to exist
          var refElCt = elRes.marshal.arrayType != null ? elRes.marshal.arrayType : elCt;
          var refEl = Context.resolveType(refElCt, Reporting.currentPos());
          var refElId = Utils.typeId2(refEl);
          //Context.resolveType((macro : ammer.ffi.Box<$refElCt>), Reporting.currentPos());
          //var elBoxTp = Utils.expectTypePath(Ammer.mergedInfo.boxes.byElementTypeId[refElId].boxCt);
          //var elBoxCt = TPath(elBoxTp);

          var defArray = macro class {
            private var _ammer_native:Any;
            private function new(native:Any) {
              this._ammer_native = native;
            }
            public function get(index:Int):$elCt {
              return $e{marshal.get(macro _ammer_native, macro index)};
            }
            public function set(index:Int, val:$elCt):Void {
              $e{marshal.set(macro _ammer_native, macro index, macro val)};
            }
            //public function ref(index:Int):$elBoxCt {
            //  return @:privateAccess new $elBoxTp($e{marshal.ref(macro _ammer_native, macro index)});
            //}
            public function free():Void {
              $e{marshal.free(macro _ammer_native)};
            }
            private static function nullPtr():$arrayCt {
              return new $arrayTp($e{marshal.nullPtr});
            }
          };
          defArray.name = arrayTp.name;
          defArray.pack = arrayTp.pack;
          Utils.defineType(defArray);

          // TODO: use abstract
          var unref = marshal.fromHaxeRef != null
            ? macro _ammer_core_native.unref()
            : macro {
              for (i in 0...vector.length) {
                vector[i] = $e{marshal.get(macro _ammer_core_native, macro i)};
              }
            };
          var defArrayRef = macro class {
            private var _ammer_core_native:Dynamic;
            private var vector:haxe.ds.Vector<$elCt>;
            private function new(
              _ammer_core_native:Dynamic,
              vector:haxe.ds.Vector<$elCt>
            ) {
              this._ammer_core_native = _ammer_core_native;
              this.vector = vector;
            }
            public var array(get, never):$arrayCt;
            private inline function get_array():$arrayCt {
              return @:privateAccess new $arrayTp(_ammer_core_native.ptr);
            }
            public function unref():Void {
              if (_ammer_core_native != null) {
                $unref;
                _ammer_core_native = null;
              }
            }
          };
          defArrayRef.name = 'ArrayRef_${elRes.marshal.mangled}';
          defArrayRef.pack = ["ammer", "gen"];
          var arrayRefCt = TPath({
            name: defArrayRef.name,
            pack: defArrayRef.pack,
          });
          Utils.defineType(defArrayRef);

          var array = {
            arrayCt: arrayCt,
            arrayRefCt: arrayRefCt,
            alloc: marshal.alloc(macro _size),
            fromHaxeCopy: marshal.fromHaxeCopy(macro _vec),
            fromHaxeRef: marshal.fromHaxeRef != null ? marshal.fromHaxeRef(macro _vec) : null,

            elementType: el,
            arrayMarshal: marshal,
          };

          Ammer.mergedInfo.arrays.byTypeId['ammer.gen.${defArray.name}.${defArray.name}'] = array;
          Ammer.mergedInfo.arrays.byElementTypeId[elId] = array;
          ctx.info.arrays.byTypeId['ammer.gen.${defArray.name}.${defArray.name}'] = array;
          ctx.info.arrays.byElementTypeId[elId] = array;

          Reporting.log('exit genericBuildArray $elId', "stage-ffi");
          arrayCt;
        });
      case _: throw 0;
    });
  }

  public static function genericBuildBox():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.ffi.Box<El>
      case TInst(_, [el]):
        var elId = Utils.typeId2(el);
        if (Ammer.mergedInfo.boxes.byElementTypeId.exists(elId)) {
          return Ammer.mergedInfo.boxes.byElementTypeId[elId].boxCt;
        }
        Reporting.log('enter genericBuildBox $elId', "stage-ffi");

        Ammer.initSubtype('ammer.ffi.Box<$elId>', el, ctx -> {
          // was it initialised in the meanwhile?
          if (Ammer.mergedInfo.boxes.byElementTypeId.exists(elId)) {
            return Ammer.mergedInfo.boxes.byElementTypeId[elId].boxCt;
          }
          Reporting.log('process genericBuildBox $elId', "stage-ffi");

          var elRes = Types.resolveType(el, ctx);

          var elCt = elRes.haxeType;
          var marshal = ctx.marshal.boxPtr(elRes.marshal);

          var boxTp:TypePath = {
            name: 'Box_${elRes.marshal.mangled}',
            pack: ["ammer", "gen"],
          };
          var boxCt = TPath(boxTp);
          var defBox = macro class {
            private var _ammer_native:Any;
            private function new(native:Any) {
              this._ammer_native = native;
            }
            public function get():$elCt {
              return $e{Utils.exprMap(marshal.get(macro _ammer_native), elRes.wrap)};
            }
            public function set(val:$elCt):Void {
              $e{marshal.set(macro _ammer_native, Utils.exprMap(macro val, elRes.unwrap))};
            }
            public function free():Void {
              $e{marshal.free(macro _ammer_native)};
            }
            private static function nullPtr():$boxCt {
              return new $boxTp($e{marshal.nullPtr});
            }
          };
          defBox.name = boxTp.name;
          defBox.pack = boxTp.pack;
          Utils.defineType(defBox);

          var box = {
            elementType: el,
            boxCt: boxCt,
            alloc: marshal.alloc,
            boxMarshal: marshal,
          };
          Ammer.mergedInfo.boxes.byTypeId['ammer.gen.${defBox.name}.${defBox.name}'] = box;
          Ammer.mergedInfo.boxes.byElementTypeId[elId] = box;
          ctx.info.boxes.byTypeId['ammer.gen.${defBox.name}.${defBox.name}'] = box;
          ctx.info.boxes.byElementTypeId[elId] = box;

          Reporting.log('exit genericBuildBox $elId', "stage-ffi");
          boxCt;
        });
      case _: throw 0;
    });
  }

  public static function buildBytes():Array<Field> {
    var pos = Context.currentPos();
    return Reporting.withPosition(pos, () -> {
      var implType = Context.getLocalClass().get();

      Reporting.log("enter buildBytes", "stage-ffi");

      var lib = Context.resolveType((macro : ammer.internal.LibTypes), pos);
      var fields:Array<Field> = Ammer.initSubtype(Utils.typeId(implType), lib, ctx -> {
        Reporting.log("process buildBytes", "stage-ffi");
        var marshal = ctx.marshal.bytes();
        var toHaxeRef = marshal.toHaxeRef != null
          ? macro return $e{marshal.toHaxeRef(macro _ammer_native, macro size)}
          : macro throw "platform does not support non-copy references to Bytes";
        var fromHaxeRef = marshal.fromHaxeRef != null
          ? macro return @:privateAccess new ammer.ffi.BytesRef($e{marshal.fromHaxeRef(macro bytes)}, bytes)
          : macro return @:privateAccess new ammer.ffi.BytesRef($e{marshal.fromHaxeCopy(macro bytes)}, bytes);
        var fromHaxeRefForce = marshal.fromHaxeRef != null
          ? macro return @:privateAccess new ammer.ffi.BytesRef($e{marshal.fromHaxeRef(macro bytes)}, bytes)
          : macro throw "platform does not support non-copy references from Bytes";
        var fields = (macro class {
          private var _ammer_native:Any;
          private function new(native:Any) {
            this._ammer_native = native;
          }

          public function get8(index:Int):Int return $e{marshal.get8(macro _ammer_native, macro index)};
          public function get16(index:Int):Int return $e{marshal.get16(macro _ammer_native, macro index)};
          public function get32(index:Int):Int return $e{marshal.get32(macro _ammer_native, macro index)};
          public function get64(index:Int):haxe.Int64 return $e{marshal.get64(macro _ammer_native, macro index)};

          public function set8(index:Int, val:Int):Void $e{marshal.set8(macro _ammer_native, macro index, macro val)};
          public function set16(index:Int, val:Int):Void $e{marshal.set16(macro _ammer_native, macro index, macro val)};
          public function set32(index:Int, val:Int):Void $e{marshal.set32(macro _ammer_native, macro index, macro val)};
          public function set64(index:Int, val:haxe.Int64):Void $e{marshal.set64(macro _ammer_native, macro index, macro val)};

          public function get16be(index:Int):Int return $e{marshal.get16be(macro _ammer_native, macro index)};
          public function get32be(index:Int):Int return $e{marshal.get32be(macro _ammer_native, macro index)};
          public function get64be(index:Int):haxe.Int64 return $e{marshal.get64be(macro _ammer_native, macro index)};
          public function set16be(index:Int, val:Int):Void $e{marshal.set16be(macro _ammer_native, macro index, macro val)};
          public function set32be(index:Int, val:Int):Void $e{marshal.set32be(macro _ammer_native, macro index, macro val)};
          public function set64be(index:Int, val:haxe.Int64):Void $e{marshal.set64be(macro _ammer_native, macro index, macro val)};

          public function get16le(index:Int):Int return $e{marshal.get16le(macro _ammer_native, macro index)};
          public function get32le(index:Int):Int return $e{marshal.get32le(macro _ammer_native, macro index)};
          public function get64le(index:Int):haxe.Int64 return $e{marshal.get64le(macro _ammer_native, macro index)};
          public function set16le(index:Int, val:Int):Void $e{marshal.set16le(macro _ammer_native, macro index, macro val)};
          public function set32le(index:Int, val:Int):Void $e{marshal.set32le(macro _ammer_native, macro index, macro val)};
          public function set64le(index:Int, val:haxe.Int64):Void $e{marshal.set64le(macro _ammer_native, macro index, macro val)};

          public static function alloc(size:Int):ammer.ffi.Bytes return new ammer.ffi.Bytes($e{marshal.alloc(macro size)});
          public static function zalloc(size:Int):ammer.ffi.Bytes return new ammer.ffi.Bytes($e{marshal.zalloc(macro size)});
          public static function nullPtr():ammer.ffi.Bytes return new ammer.ffi.Bytes($e{marshal.nullPtr});
          public function free():Void {
            $e{marshal.free(macro _ammer_native)};
            _ammer_native = null;
          }
          public function copy(size:Int):Bytes return new ammer.ffi.Bytes($e{marshal.copy(macro _ammer_native, macro size)});
          public static function blit(source:Bytes, sourcepos:Int, dest:Bytes, destpos:Int, size:Int):Void {
            $e{marshal.blit(macro source._ammer_native, macro sourcepos, macro dest._ammer_native, macro destpos, macro size)};
          }
          public function offset(pos:Int):Bytes return new ammer.ffi.Bytes($e{marshal.offset(macro _ammer_native, macro pos)});

          public function toHaxeCopy(size:Int):haxe.io.Bytes return $e{marshal.toHaxeCopy(macro _ammer_native, macro size)};
          public static function fromHaxeCopy(bytes:haxe.io.Bytes):Bytes return new ammer.ffi.Bytes($e{marshal.fromHaxeCopy(macro bytes)});
          public function toHaxeRef(size:Int):haxe.io.Bytes $toHaxeRef;
          public static function fromHaxeRef(bytes:haxe.io.Bytes):ammer.ffi.BytesRef $fromHaxeRef;
          public static function fromHaxeRefForce(bytes:haxe.io.Bytes):ammer.ffi.BytesRef $fromHaxeRefForce;
        }).fields;

        // TODO: use abstract
        var ptr = marshal.fromHaxeRef != null
          ? macro _ammer_core_native.ptr
          : macro _ammer_core_native;
        var unref = marshal.fromHaxeRef != null
          ? macro _ammer_core_native.unref()
          : macro {
            for (i in 0...hbytes.length) {
              hbytes.set(i, $e{marshal.get8(ptr, macro i)});
            }
            $e{marshal.free(ptr)};
          };
        var defBytesRef = macro class {
          private var _ammer_core_native:Dynamic;
          private var hbytes:haxe.io.Bytes;
          private function new(
            _ammer_core_native:Dynamic,
            hbytes:haxe.io.Bytes
          ) {
            this._ammer_core_native = _ammer_core_native;
            this.hbytes = hbytes;
          }
          public var bytes(get, never):ammer.ffi.Bytes;
          private inline function get_bytes():ammer.ffi.Bytes {
            return @:privateAccess new ammer.ffi.Bytes($ptr);
          }
          public function unref():Void {
            if (_ammer_core_native != null) {
              $unref;
              _ammer_core_native = null;
            }
          }
        };
        defBytesRef.name = "BytesRef";
        defBytesRef.pack = ["ammer", "ffi"];
        var bytesRefCt = TPath({
          name: defBytesRef.name,
          pack: defBytesRef.pack,
        });
        Utils.defineType(defBytesRef);

        fields;
      });

      Reporting.log("exit buildBytes", "stage-ffi");
      Utils.modifyType(implType, fields);
    });
  }

  public static function genericBuildCallback():ComplexType {
    var pos = Context.currentPos();
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.ffi.Callback<CallbackType, FunctionType, CallTarget, CallArgs, Lib>
      case TInst(_, [cbType, fnType, callTarget, callArgs, lib]):
        switch (fnType) {
          case TFun(_, _):
          case _: throw Reporting.error("ammer.ffi.Callback second type parameter should be a function type");
        }

        var isGlobal = false;
        var callTarget:Expr = (switch (callTarget) {
          case TInst(_.get() => {kind: KExpr({expr: EConst(CString("global"))})}, []):
            isGlobal = true;
            null;
          case TInst(_.get() => {kind: KExpr({expr: EArrayDecl([expr])})}, []):
            expr;
          case _:
            throw Reporting.error("ammer.ffi.Callback third type parameter should be an array with a single expression or \"global\"");
        });
        var callArgs = Utils.exprArrayOfType(callArgs);
        callArgs != null
          || throw Reporting.error("ammer.ffi.Callback fourth type parameter should be an array of expressions");

        var printer = new haxe.macro.Printer();
        var elId = StringTools.hex(haxe.crypto.Crc32.make(haxe.io.Bytes.ofString(ammer.core.utils.Mangle.parts([
          Utils.typeId2(cbType),
          Utils.typeId2(fnType),
          printer.printExpr(callTarget),
          printer.printExpr(macro $a{callArgs}),
        ]))), 8);
        if (Ammer.mergedInfo.callbacks.byElementTypeId.exists(elId)) {
          return Ammer.mergedInfo.callbacks.byElementTypeId[elId].callbackCt;
        }
        Reporting.log('enter genericBuildCallback $elId', "stage");

        var callbackTp:TypePath = {
          name: 'Callback_$elId',
          pack: ["ammer", "gen"],
        };
        var callbackCt = TPath(callbackTp);
        var funCt = TypeTools.toComplexType(fnType);
        var callback:ammer.internal.v1.LibInfo.LibInfoCallback = {
          isGlobal: isGlobal,
          callbackCt: callbackCt,
          funCt: funCt,
          callbackName: null,
        };
        var typeId = Utils.typeIdTp(callbackTp);

        Ammer.initSubtype('ammer.ffi.Callback<$elId>', lib, ctx -> {
          // was it initialised in the meanwhile?
          if (Ammer.mergedInfo.callbacks.byElementTypeId.exists(elId)) {
            return Ammer.mergedInfo.callbacks.byElementTypeId[elId].callbackCt;
          }
          Reporting.log('process genericBuildCallback $elId', "stage");
          callback.ctx = ctx;
          Ammer.mergedInfo.callbacks.byTypeId[typeId] = callback;
          Ammer.mergedInfo.callbacks.byElementTypeId[elId] = callback;
          ctx.info.callbacks.byTypeId[typeId] = callback;
          ctx.info.callbacks.byElementTypeId[elId] = callback;

          var cbArgsRes;
          var cbRetRes;
          switch (cbType) {
            case TFun(args, ret):
              cbArgsRes = args.map(arg -> Types.resolveType(arg.t, ctx));
              cbRetRes = Types.resolveType(ret, ctx);
            case _: throw Reporting.error("ammer.ffi.Callback first type parameter should be a function type");
          }

          var invoke = [];
          for (idx => arg in cbArgsRes) {
            if (arg.wrap != null) {
              var ident = 'arg$idx';
              invoke.push(macro var $ident = $e{Utils.exprMap(macro $i{ident}, arg.wrap)});
            }
          }
          invoke.push(isGlobal
            ? (macro return @:privateAccess $p{Utils.accessTp(callbackTp)}.stored.value($a{callArgs}))
            : (macro return $e{callTarget}.value($a{callArgs})));
          callback.callbackName = ctx.library.addStaticCallback(
            cbRetRes.marshal,
            cbArgsRes.map(arg -> arg.marshal),
            macro $b{invoke}
          );

          var defCallback = isGlobal
            ? (macro class {
              static var stored:ammer.ffi.Haxe<$funCt> = null;
              public static function store(val:$funCt):Void {
                if (stored != null) stored.decref();
                stored = ammer.Lib.createHaxeRef((_ : $funCt), val);
                stored.incref();
              }
            })
            : (macro class {});
          defCallback.name = callbackTp.name;
          defCallback.pack = callbackTp.pack;
          Utils.defineType(defCallback);

          Reporting.log('exit genericBuildCallback $elId', "stage");
          callbackCt;
        });
      case _: throw 0;
    });
  }

  public static function genericBuildHaxeRef():ComplexType {
    var pos = Context.currentPos();
    return Reporting.withPosition(pos, () -> switch (Context.getLocalType()) {
      // ammer.ffi.HaxeRef<El>
      case TInst(_, [el]):
        var elId = Utils.typeId2(el);
        if (Ammer.mergedInfo.haxeRefs.byElementTypeId.exists(elId)) {
          return Ammer.mergedInfo.haxeRefs.byElementTypeId[elId].marshal.refCt;
        }
        Reporting.log('enter genericBuildHaxeRef $elId', "stage-ffi");

        Ammer.initSubtype('ammer.ffi.Haxe<$elId>', el, ctx -> {
          // was it initialised in the meanwhile?
          if (Ammer.mergedInfo.haxeRefs.byElementTypeId.exists(elId)) {
            return Ammer.mergedInfo.haxeRefs.byElementTypeId[elId].marshal.refCt;
          }
          Reporting.log('process genericBuildHaxeRef $elId', "stage-ffi");

          var elCt = TypeTools.toComplexType(el);
          var marshal = ctx.marshal.haxePtr(elCt);
          var create = marshal.create(macro _hxval);
          var haxeRef = {
            ctx: ctx,
            create: create,
            elementType: el,
            marshal: marshal,
          };

          var typeId = Utils.typeIdTp(ammer.core.utils.TypeUtils.complexTypeToPath(haxeRef.marshal.refCt));
          Ammer.mergedInfo.haxeRefs.byTypeId[typeId] = haxeRef;
          Ammer.mergedInfo.haxeRefs.byElementTypeId[elId] = haxeRef;
          ctx.info.haxeRefs.byTypeId[typeId] = haxeRef;
          ctx.info.haxeRefs.byElementTypeId[elId] = haxeRef;

          Reporting.log('exit genericBuildHaxeRef $elId', "stage-ffi");
          haxeRef.marshal.refCt;
        }, ctxLibTypes -> {
          var elCt = TypeTools.toComplexType(el);
          Ammer.mergedInfo.haxeRefs.byElementTypeId.exists(".Any.Any") || throw 0;
          //var anyRefCt = Ammer.haxes.byElementTypeId[".Any.Any"].marshal.refCt;

          // TODO: emit warning?
          Reporting.log('exit genericBuildHaxeRef $elId (as HaxeAnyRef)', "stage-ffi");
          (macro : ammer.internal.LibTypes.HaxeAnyRef<$elCt>);
        });
      case _: throw 0;
    });
  }

  public static function genericBuildLibrary():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.def.Library<Name>
      case TInst(_, [tp1]):
        var e1 = Utils.exprOfType(tp1);
        (e1 != null && Utils.stringOfParam(tp1) != null)
          || throw Reporting.error("ammer.def.Library: type parameter should be a string literal");
        TPath({
          pack: ["ammer", "internal"],
          name: "Entrypoint",
          sub: "LibraryProcessed",
          params: [TPExpr(e1)],
        });
      case _: throw 0;
    });
  }

  public static function genericBuildOpaque():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.def.Opaque<Name, Lib>
      case TInst(_, [tp1, tp2]):
        var e1 = Utils.exprOfType(tp1);
        (e1 != null && Utils.stringOfParam(tp1) != null)
          || throw Reporting.error("ammer.def.Opaque: first type parameter should be a string literal");
        Utils.classOfParam(tp2) != null
          || throw Reporting.error("ammer.def.Opaque: second type parameter should be the parent library");
        TPath({
          pack: ["ammer", "internal"],
          name: "Entrypoint",
          sub: "OpaqueProcessed",
          params: [TPExpr(e1), TPType(TypeTools.toComplexType(tp2))],
        });
      case _: throw 0;
    });
  }

  public static function genericBuildStruct():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.def.Struct<Name, Lib>
      case TInst(_, params = [tp1, tp2]):
        var e1 = Utils.exprOfType(tp1);
        (e1 != null && Utils.stringOfParam(tp1) != null)
          || throw Reporting.error("ammer.def.Opaque: first type parameter should be a string literal");
        Utils.classOfParam(tp2) != null
          || throw Reporting.error("ammer.def.Opaque: second type parameter should be the parent library");
        TPath({
          pack: ["ammer", "internal"],
          name: "Entrypoint",
          sub: "StructProcessed",
          params: [TPExpr(e1), TPType(TypeTools.toComplexType(tp2))],
        });
      case _: throw 0;
    });
  }

  public static function genericBuildSublibrary():ComplexType {
    return Reporting.withCurrentPos(() -> switch (Context.getLocalType()) {
      // ammer.def.Sublibrary<Lib>
      case TInst(_, [tp1]):
        Utils.classOfParam(tp1) != null
          || throw Reporting.error("ammer.def.Sublibrary: type parameter should be the parent library");
        TPath({
          pack: ["ammer", "internal"],
          name: "Entrypoint",
          sub: "SublibraryProcessed",
          params: [TPType(TypeTools.toComplexType(tp1))],
        });
      case _: throw 0;
    });
  }

  public static function buildEnum(name:String, el:Expr, lib:Expr):Array<Field> {
    return Reporting.withCurrentPos(() -> {
      var implType = Context.getLocalClass().get();
      var absType = (switch (implType.kind) {
        case KAbstractImpl(_.get() => abs): abs;
        case _: throw Reporting.error("ammer.def.Enum.build should be applied onto an enum abstract");
      });
      var implId = Utils.typeId(absType);
      Reporting.log('enter buildEnum $implId "$name"', "stage");

      var haxeEl = absType.type;

      var elCt = Utils.complexTypeExpr(el);
      elCt != null || throw Reporting.error("ammer.def.Enum.build second argument should be an ammer FFI type");
      var el = Context.resolveType(elCt, Reporting.currentPos());

      var libCt = Utils.complexTypeExpr(lib);
      libCt != null || throw Reporting.error("ammer.def.Enum.build third argument should be the parent library");
      var lib = Context.resolveType(libCt, Reporting.currentPos());

      var options:ammer.internal.v1.LibInfo.LibInfoEnum = {};
      Ammer.mergedInfo.enums[implId] = options;

      var implFields = Context.getBuildFields();
      var fields:Array<Field> = Ammer.initSubtype(implId, lib, ctx -> {
        Reporting.log('process buildEnum $implId "$name"', "stage");

        var rawElRes = Types.resolveType(el, ctx);
        var elRes = ctx.marshal.enumInt(name, rawElRes.marshal);
        switch (elRes.mangled) {
          case "u1" | "i8" | "i16" | "i32" | "u8" | "u16" | "u32":
            // TODO: other types: (though floats and strings don't make much sense for enums)
            // "i64" | "u64"
            // "f32" | "f64"
            // "s"
          case _: throw Reporting.error("ammer.def.Enum.build first argument can only be a primitve type");
        }
        options.marshal = elRes;

        var extract = new ammer.core.utils.LineBuf()
          .ail('#include <stdio.h>')
          .ail('int main() {')
          .i();
        var extractedFields = [];
        var dbgCtr = 0;
        for (field in implFields) switch (field.kind) {
          case FVar(_, null) if (!field.access.contains(AStatic)):
            var native = field.name;
            for (meta in Meta.extract(field.meta, Meta.ENUM_FIELD)) switch (meta) {
              case PMNative(name): native = name;
              case _: throw 0;
            }
            extract.ail('printf("%d\\n", $native);');
            extractedFields.push(field);
          case _: throw Reporting.error("unexpected field");
        }
        extract.d().ail("}");

        var data = ctx.prebuildImmediate(extract.done()).split("\n");
        [ for (field in implFields) {
          var index = extractedFields.indexOf(field);
          if (index == -1) {
            field;
          } else {
            var val = Std.parseInt(data[index]);
            Utils.updateField(field, FVar(null, macro $v{val}));
          }
        } ];
        // TODO: re-process through Fields?
      });

      Reporting.log('exit buildEnum $implId "$name" (${fields.length} fields)', "stage");
      Utils.modifyType(implType, fields);
    });
  }

  public static function autoBuildLibrary():Array<Field> {
    return Reporting.withCurrentPos(() -> {
      var implType = Context.getLocalClass().get();
      var implId = Utils.typeId(implType);
      var libname = Utils.stringOfParam(implType.superClass.params[0]);
      libname != null || throw 0;

      Reporting.log('enter autoBuildLibrary $implId "$libname"', "stage");

      var options:LibContext.LibContextOptions = {
        name: libname,
        headers: [],
        defines: [],
        definesCodeOnly: [],
        includePaths: [],
        libraryPaths: [],
        frameworks: [],
        language: C,
        linkNames: [],
      };
      var optionsLinkNameDefault = true;
      var fieldOptions:ammer.internal.v1.LibInfo.LibInfoLibrary = {};
      var subtypes = [];

      var pathToFile = Path.normalize(Path.directory(haxe.macro.PositionTools.getInfos(implType.pos).file));
      if (!Path.isAbsolute(pathToFile)) pathToFile = Path.join([Sys.getCwd(), pathToFile]);
      function relPath(p:String):{rel:String, abs:String} {
        return {
          rel: Path.normalize('${implType.pack.join("/")}/$p'),
          abs: Path.join([pathToFile, p]),
        };
      }

      for (meta in Meta.extract(implType.meta.get(), Meta.LIBRARY_CLASS)) switch (meta) {
        case PMLib_Define(v): options.defines.push(v);
        case PMLib_Define_CodeOnly(v): options.definesCodeOnly.push(v);
        case PMLib_Framework(v): options.frameworks.push(v);
        case PMLib_Frameworks(v): options.frameworks = options.frameworks.concat(v);
        case PMLib_IncludePath(v): options.includePaths.push(relPath(v));
        case PMLib_IncludePaths(v): options.includePaths = options.includePaths.concat(v.map(relPath));
        case PMLib_Language(v): options.language = v;
        case PMLib_LibraryPath(v): options.libraryPaths.push(relPath(v));
        case PMLib_LibraryPaths(v): options.libraryPaths = options.libraryPaths.concat(v.map(relPath));
        case PMLib_LinkName(v): optionsLinkNameDefault = false; options.linkNames.push(v);
        case PMLib_LinkNames(v): optionsLinkNameDefault = false; options.linkNames = options.linkNames.concat(v);
        case PMLib_Headers_Include(v): options.headers.push(IncludeLocal(v));
        case PMLib_Headers_Import(v): options.headers.push(ImportLocal(v));
        case PMLib_Headers_IncludeLocal(v): options.headers.push(IncludeLocal(v));
        case PMLib_Headers_ImportLocal(v): options.headers.push(ImportLocal(v));
        case PMLib_Headers_IncludeGlobal(v): options.headers.push(IncludeGlobal(v));
        case PMLib_Headers_ImportGlobal(v): options.headers.push(ImportGlobal(v));
        case PMNativePrefix(v): fieldOptions.nativePrefix = v;
        case PMSub(v): subtypes.push(v);
        case _: throw 0;
      }
      if (optionsLinkNameDefault) options.linkNames.push(libname);

      var isLibTypes = (implId == "ammer.internal.LibTypes.LibTypes");
      var fields:Array<Field>;
      var implFields = Context.getBuildFields();
      if (isLibTypes && Bakery.isBaking) {
        // When baking, `LibTypes` is treated as a sublibrary of the main
        // library. As a result, its methods are compiled into the main library
        // and it is not necessary to distribute an additional dynamic library
        // with the program. When multiple baked libraries are used together,
        // one `LibTypes` version is selected according to the order in which
        // the baked libraries are introduced in the compiler invocation.
        Reporting.log('processing autoBuildLibrary $implId as a sublibrary for the main type', "stage");

        var options:ammer.internal.v1.LibInfo.LibInfoSublibrary = {};
        Ammer.mergedInfo.sublibraries[implId] = options;

        fields = Ammer.initSubtype(implId, Bakery.mainType, ctx -> {
          Reporting.log('process autoBuildLibrary $implId "$libname"', "stage");
          options.ctx = ctx;
          ctx.info.sublibraries[implId] = options;

          // TODO: this is a bit hacky; it exists so that `Types.resolveContext`
          // finds the main library instead of `LibTypes`.
          Ammer.libraries.byLibraryName["libtypes"] = ctx;
          Ammer.libraries.byTypeId[implId] = ctx;

          Ammer.contextReady(implType, ctx);
          subtypes.iter(Utils.triggerTyping);
          Fields.process(
            implFields,
            ctx,
            FCSublibrary(options)
          );
        });
      } else {
        var ctx = Ammer.initLibrary(implType, libname, options);
        subtypes.iter(Utils.triggerTyping);
        fields = Fields.process(
          implFields,
          ctx,
          FCLibrary(fieldOptions)
        );
        ctx.finalise();
      }

      Reporting.log('exit autoBuildLibrary $implId "$libname" (${fields.length} fields)', "stage");
      Utils.modifyType(implType, fields);
    });
  }

  public static function autoBuildOpaque():Array<Field> {
    return Reporting.withCurrentPos(() -> {
      var implRef = Context.getLocalClass();
      var implType = implRef.get();
      var implId = Utils.typeId(implType);
      var opaqueName = Utils.stringOfParam(implType.superClass.params[0]);
      opaqueName != null || throw 0;

      Reporting.log('enter autoBuildOpaque $implId "$opaqueName"', "stage");

      implType.params.length == 0 || throw Reporting.error("ammer opaque types cannot have type parameters");

      var lib = Utils.classOfParam(implType.superClass.params[1]);
      var options:ammer.internal.v1.LibInfo.LibInfoOpaque = {
        implType: TInst(implRef, []),
        opaqueName: opaqueName,
      };
      Ammer.mergedInfo.opaques[implId] = options;

      for (meta in Meta.extract(implType.meta.get(), Meta.OPAQUE_CLASS)) switch (meta) {
        case PMNativePrefix(v): options.nativePrefix = v;
        case _: throw 0;
      }

      var implFields = Context.getBuildFields();
      var fields:Array<Field> = Ammer.initSubtype(implId, implType.superClass.params[1], ctx -> {
        Reporting.log('process autoBuildOpaque $implId "$opaqueName"', "stage");
        options.ctx = ctx;
        ctx.info.opaques[implId] = options;
        Fields.process(
          implFields,
          ctx,
          FCOpaque(options)
        );
      });

      Reporting.log('exit autoBuildOpaque $implId "$opaqueName" (${fields.length} fields)', "stage");
      Utils.modifyType(implType, fields);
    });
  }

  public static function autoBuildStruct():Array<Field> {
    return Reporting.withCurrentPos(() -> {
      var implRef = Context.getLocalClass();
      var implType = implRef.get();
      var implId = Utils.typeId(implType);
      var structName = Utils.stringOfParam(implType.superClass.params[0]);
      structName != null || throw 0;

      Reporting.log('enter autoBuildStruct $implId "$structName"', "stage");

      implType.params.length == 0 || throw Reporting.error("ammer struct types cannot have type parameters");

      var lib = Utils.classOfParam(implType.superClass.params[1]);
      var alloc = false;
      var options:ammer.internal.v1.LibInfo.LibInfoStruct = {
        alloc: false,
        gen: {},
        implType: TInst(implRef, []),
        structName: structName,
      };
      Ammer.mergedInfo.structs[implId] = options;

      for (meta in Meta.extract(implType.meta.get(), Meta.STRUCT_CLASS)) switch (meta) {
        case PMAlloc:
          options.alloc = true;
          options.gen = {
            alloc: "alloc",
            free: "free",
            nullPtr: "nullPtr",
          };
        case PMGen_Alloc(v):
          options.alloc = true;
          options.gen.alloc = v;
        case PMGen_Free(v):
          options.alloc = true;
          options.gen.free = v;
        case PMGen_NullPtr(v):
          options.alloc = true;
          options.gen.nullPtr = v;
        case PMNativePrefix(v): options.nativePrefix = v;
        case PMSub(v): Utils.triggerTyping(v); // TODO: copy approach in Sublibrary
        case _: throw 0;
      }

      var implFields = Context.getBuildFields();
      var fields:Array<Field> = Ammer.initSubtype(implId, implType.superClass.params[1], ctx -> {
        Reporting.log('process autoBuildStruct $implId "$structName"', "stage");

        // On C++, we add an include of the glue code generated by `ammer-core`,
        // such that the types declared therein (or in the headers transitively
        // included by the glue code) are visible in the C++ definitions.
        if (Context.definedValue("target.name") == "cpp") {
          var exth = ctx.libraryOptions.language.extensionHeader();
          var headerCode = '#include "${implType.pack.map(_ -> "../").join("")}../ammer_build/ammer_${ctx.name}/lib.cpp_static.$exth"';
          implType.meta.add(":headerCode", [macro $v{headerCode}], Reporting.currentPos());
        }

        options.ctx = ctx;
        ctx.info.structs[implId] = options;
        Fields.process(
          implFields,
          ctx,
          FCStruct(options)
        );
      });

      Reporting.log('exit autoBuildStruct $implId "$structName" (${fields.length} fields)', "stage");
      Utils.modifyType(implType, fields);
    });
  }

  public static function autoBuildSublibrary():Array<Field> {
    return Reporting.withCurrentPos(() -> {
      var implRef = Context.getLocalClass();
      var implType = implRef.get();
      var implId = Utils.typeId(implType);
      Reporting.log('enter autoBuildSublibrary $implId', "stage");

      var lib = Utils.classOfParam(implType.superClass.params[0]);
      var options:ammer.internal.v1.LibInfo.LibInfoSublibrary = {};
      var subtypes = [];
      Ammer.mergedInfo.sublibraries[implId] = options;

      for (meta in Meta.extract(implType.meta.get(), Meta.SUBLIBRARY_CLASS)) switch (meta) {
        case PMNativePrefix(v): options.nativePrefix = v;
        case PMSub(v): subtypes.push(v);
        case _: throw 0;
      }

      var implFields = Context.getBuildFields();
      var fields:Array<Field> = Ammer.initSubtype(implId, implType.superClass.params[0], ctx -> {
        Reporting.log('process autoBuildSublibrary $implId', "stage");
        options.ctx = ctx;
        ctx.info.sublibraries[implId] = options;
        Ammer.contextReady(implType, ctx);
        subtypes.iter(Utils.triggerTyping);
        Fields.process(
          implFields,
          ctx,
          FCSublibrary(options)
        );
      });

      Reporting.log('exit autoBuildSublibrary $implId (${fields.length} fields)', "stage");
      Utils.modifyType(implType, fields);
    });
  }
}

#else

@:autoBuild(ammer.internal.Entrypoint.autoBuildLibrary())
class LibraryProcessed<@:const Name> {}

@:autoBuild(ammer.internal.Entrypoint.autoBuildOpaque())
class OpaqueProcessed<@:const Name, Lib> {}

@:autoBuild(ammer.internal.Entrypoint.autoBuildStruct())
class StructProcessed<@:const Name, Lib> {}

@:autoBuild(ammer.internal.Entrypoint.autoBuildSublibrary())
class SublibraryProcessed<Lib> {}

#end
