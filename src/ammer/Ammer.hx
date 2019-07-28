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
      (macro : Int) => ammer.FFI.FFIType.Int,
      (macro : String) => ammer.FFI.FFIType.String,
      (macro : haxe.io.Bytes) => ammer.FFI.FFIType.Bytes
    ];
    var localPos = Context.makePosition({min: 0, max: 0, file: ""});
    [ for (type => ffi in m) Context.resolveType(type, localPos) => ffi ];
  };

  static function mapType(t:ComplexType, p:Position):ammer.FFI.FFIType {
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
              type = ammer.FFI.FFIType.ReturnSizePtr(type);
            case [":ammer.sizeOf", [{expr: EConst(CIdent(of))}]]:
              hasSizes.push(of);
              type = ammer.FFI.FFIType.SizePtr(type, of);
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

  static function initStubs():Void {
    ctx.stub = (switch (config.platform) {
      case Hl: new ammer.stub.StubHL();
      case Cpp: null; // new ammer.stub.StubCpp();
    });
  }

  static function createStubs():Void {
    ctx.stub.generate(ctx);
    trace(ctx.stub.build(ctx));
  }

  static function patchImpl():Void {
    ctx.stub.patch(ctx);
  }

  static function createExtern():Void {
    var c = macro class AmmerExtern {};
    c.isExtern = true;
    c.name = ctx.externName;
    c.pack = ["ammer", "externs"];
    for (f in ctx.externFields)
      c.fields.push(f);
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
      ffi: null,
      stub: null
    };
    createFFI();
    initStubs();
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

typedef AmmerConfig = {
  outputDir:String,
  platform:AmmerPlatform
};

typedef AmmerContext = {
  config:AmmerConfig,
  libname:String,
  // impl = the original class (extends CLibrary ...)
  implType:ClassType,
  implFields:Array<Field>,
  // extern = field with extern functions, hlNative ...
  externName:String,
  externFields:Array<Field>,
  ffi:FFI,
  stub:ammer.stub.Stub
};

enum AmmerPlatform {
  Hl;
  Cpp;
}
#end
