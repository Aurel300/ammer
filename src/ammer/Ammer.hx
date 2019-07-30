package ammer;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using ammer.FFITools;

class Ammer {
  static var config:AmmerConfig;
  static var ctx:AmmerContext;

  static function configure():Void {
    function def<T>(key:String, conv:String->T, ?dv:T):T {
      if (Context.defined(key))
        return conv(Context.definedValue(key));
      return dv;
    }
    final defS = (key, ?dv:String) -> def(key, v -> v, dv);
    config = {
      outputDir: defS("AMMER_OUTPUT_DIR", "out"),
      platform: (if (Context.defined("hl")) AmmerPlatform.Hl
        else if (Context.defined("cpp")) AmmerPlatform.Cpp
        else throw "unsupported ammer platform")
    };
  }

  static var typeMap = {
    var m = [
      (macro : Int) => FFIType.Int,
      (macro : String) => FFIType.String,
      (macro : haxe.io.Bytes) => FFIType.Bytes
    ];
    var localPos = Context.makePosition({min: 0, max: 0, file: ""});
    [ for (type => ffi in m) Context.resolveType(type, localPos) => ffi ];
  };

  static function mapType(t:ComplexType, p:Position):FFIType {
    var resolved = Context.resolveType(t, p);
    for (type => ffi in typeMap) {
      if (Context.unify(type, resolved))
        return ffi;
    }
    throw "invalid ffi type";
  }

  static function createFFIMethod(field:Field, f:Function):ammer.FFI.FFIField {
    var ffiArgs = [];
    var hasRetSize = false;
    var needsSizes:Array<String> = [];
    var hasSizes:Array<String> = [];
    var annotations:Array<ammer.FFI.FFIFieldAnnotation> = [];
    // process field meta
    if (field.meta != null) {
      for (meta in field.meta) {
        switch [meta.name, meta.params] {
          case [":ammer.returnSizeSameAs", [{expr: EConst(CIdent(of))}]]:
            if (hasRetSize)
              throw "duplicate";
            hasRetSize = true;
            annotations.push(ReturnSizeSameAs(of));
            // TODO: ensure arg exists
          case _:
            throw "unsupported meta";
        }
      }
      field.meta = [];
    }
    // arguments meta
    for (arg in f.args) {
      var type = mapType(arg.type, field.pos);
      if (type.needsSize()) {
        if (arg.name == "_")
          throw "!";
        needsSizes.push(arg.name);
      }
      if (arg.meta != null) {
        for (meta in arg.meta) {
          switch [meta.name, meta.params] {
            // TODO: for sizes, check the type is int
            case [":ammer.returnSizePtr", null | []]:
              if (hasRetSize)
                throw "duplicate";
              hasRetSize = true;
              type = FFIType.ReturnSizePtr(type);
            case [":ammer.sizeOf", [{expr: EConst(CIdent(of))}]]:
              hasSizes.push(of);
              type = FFIType.SizePtr(type, of);
            case _:
              throw "unsupported meta";
          }
        }
        arg.meta = [];
      }
      ffiArgs.push(type);
    }
    // TODO: check hasSize ~= needsSize
    var ffiRet = mapType(f.ret, field.pos);
    trace(field.name, ffiRet);
    if (ffiRet.needsSize() != hasRetSize)
      throw "invalid retsize";
    return {
      kind: Method(field.name, ffiArgs, ffiRet),
      annotations: annotations
    };
  }

  static function createFFI():Void {
    var ffi = new ammer.FFI(ctx.libname);
    ffi.headers = ['${ctx.libname}.h']; // TODO: by default
    for (field in ctx.implFields) {
      switch (field) {
        case {kind: FFun(f)}:
          if (f.ret == null)
            throw "!";
          for (arg in f.args)
            if (arg.type == null)
              throw "!";
          ffi.fields.push(createFFIMethod(field, f));
        case _:
      }
    }
    trace("FFI FIELDS:", ffi.fields);
    ctx.ffi = ffi;
  }

  static function createStubs():Void {
    var stub = (switch (config.platform) {
      case Hl: new ammer.stub.StubHl(ctx);
      case Cpp: new ammer.stub.StubCpp(ctx);
    });
    stub.generate();
    trace(stub.build());
  }

  static function patchImpl():Void {
    var patcher = (switch (config.platform) {
      case Hl: new ammer.patch.PatchHl(ctx);
      case Cpp: throw "cannot patch!";
    });
    for (i in 0...ctx.ffi.fields.length) {
      var ffiField = ctx.ffi.fields[i];
      var implField = ctx.implFields[i];
      var pos = implField.pos;
      inline function e(e:ExprDef):Expr {
        return {expr: e, pos: pos};
      }
      inline function id(s:String):Expr {
        return e(EConst(CIdent(s)));
      }
      if (implField.meta == null)
        implField.meta = [];
      switch [ffiField.kind, implField.kind] {
        case [Method(mn, ffiArgs, ffiRet), FFun(f)]:
          var mctx:AmmerMethodPatchContext = {
            top: ctx,
            name: implField.name,
            ffiArgs: ffiArgs,
            ffiRet: ffiRet,
            field: implField,
            fn: f,
            callArgs: [],
            callExpr: null,
            wrapArgs: [],
            wrapExpr: null,
            externArgs: []
          };
          var methodPatcher = patcher.visitMethod(mctx);
          mctx.callArgs = [ for (i in 0...ffiArgs.length) id('_arg${i}') ];
          mctx.callExpr = e(ECall(macro $p{["ammer", "externs", ctx.externName, implField.name]}, mctx.callArgs));
          mctx.wrapExpr = mctx.callExpr;
          methodPatcher.visitReturn(ffiRet, f.ret);
          for (i in 0...ffiArgs.length)
            methodPatcher.visitArgument(i, ffiArgs[i], f.args[i]);
          for (annotation in ffiField.annotations)
            methodPatcher.visitAnnotation(annotation);
          methodPatcher.finish();
          f.expr = macro return ${mctx.wrapExpr};
          f.args = mctx.wrapArgs;
        case _:
          throw "?";
      }
    }
  }

  static function createExtern():Void {
    var c = macro class AmmerExtern {};
    c.isExtern = ctx.externIsExtern;
    c.meta = ctx.externMeta;
    c.name = ctx.externName;
    c.pack = ["ammer", "externs"];
    c.fields = ctx.externFields;
    Sys.println(new haxe.macro.Printer().printTypeDefinition(c));
    Context.defineType(c);
  }

  public static function build(libname:String):Array<Field> {
    configure();
    Sys.println('[ammer] building $libname ...');
    ctx = {
      config: config,
      libname: libname,
      implType: Context.getLocalClass().get(),
      implFields: Context.getBuildFields(),
      externName: 'AmmerExtern_$libname',
      externFields: [],
      externIsExtern: true,
      externMeta: [],
      ffi: null,
      stub: null
    };
    createFFI();
    createStubs();
    patchImpl();
    createExtern();
    var ret = ctx.implFields;
    var printer = new haxe.macro.Printer();
    for (f in ret) {
      Sys.println("IMPLFIELD: " + printer.printField(f));
    }
    ctx = null;
    return ret;
  }
}
#end
