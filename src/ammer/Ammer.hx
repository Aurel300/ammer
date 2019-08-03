package ammer;

import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;
import sys.FileSystem;

using ammer.FFITools;

class Ammer {
  static var config:AmmerConfig;
  static var libraries:Array<AmmerContext> = [];
  static var ctx:AmmerContext;

  public static function getDefine(key:String, ?dv:String, ?doThrow:Bool = false):String {
    if (Context.defined(key))
      return Context.definedValue(key);
    if (doThrow)
      throw 'required: $key';
    return dv;
  }

  public static function getPath(key:String):String {
    var p = getDefine(key, null, true);
    if (!Path.isAbsolute(p))
      p = Path.join([Sys.getCwd(), p]);
    return p;
  }

  public static function update(path:String, content:String):Void {
    if (!FileSystem.exists(path) || sys.io.File.getContent(path) != content)
      File.saveContent(path, content);
  }

  static function configure():Void {
    if (config != null)
      return;
    var platform = (if (Context.defined("hl")) AmmerPlatform.Hl
      else if (Context.defined("cpp")) AmmerPlatform.Cpp
      else throw "unsupported ammer platform");
    var outputDir = platform == Hl ? Path.directory(Compiler.getOutput()) : Compiler.getOutput();
    config = {
      hlBuild: getDefine("ammer.hl.build", outputDir),
      hlOutput: getDefine("ammer.hl.output", outputDir),
      debug: Context.defined("ammer.debug"),
      platform: platform
    };
    inline function mk(dir:String):Void {
      if (!sys.FileSystem.exists(dir))
        sys.FileSystem.createDirectory(dir);
    }
    switch (platform) {
      case Hl:
        mk(config.hlBuild);
        mk(config.hlOutput);
      case _:
    }
    Context.onAfterGenerate(runBuild);
  }

  static function mapFFIType(t:FFIType):ComplexType {
    return (switch (t) {
      case Bool: (macro : Bool);
      case Int: (macro : Int);
      case Bytes: (macro : haxe.io.Bytes);
      case String: (macro : String);
      case SameSizeAs(t, _): mapFFIType(t);
      case _: throw "!";
    });
  }

  static function mapTypeFFIResolved(resolved:Type, ?annotated:Bool = false):FFIType {
    var pos = (macro null).pos;
    var ret = null;
    function c(type:ComplexType, ffi:FFIType):Bool {
      if (Context.unify(Context.resolveType(type, pos), resolved)) {
        ret = ffi;
        return true;
      }
      return false;
    }
    c((macro : Int), Int)
    || c((macro : String), String)
    || c((macro : haxe.io.Bytes), Bytes)
    || c((macro : ammer.ffi.SizeOfReturn), SizeOfReturn);
    if (ret == null)
      switch (resolved) {
        case TInst(
          _.get() => {name: "SameSizeAs", pack: ["ammer", "ffi"]},
          [inner, TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]
        ) if (!annotated):
          return SameSizeAs(mapTypeFFIResolved(inner, true), argName);
        case TInst(
          _.get() => {name: "SizeOf", pack: ["ammer", "ffi"]},
          [TInst(_.get() => {kind: KExpr({expr: EConst(CString(argName))})}, [])]
        ) if (!annotated):
          return SizeOf(argName);
        case _:
          throw "invalid ffi type";
      }
    return ret;
  }

  static function mapTypeFFI(t:ComplexType, p:Position):FFIType {
    return mapTypeFFIResolved(Context.resolveType(t, p));
  }

  static function createFFIMethod(field:Field, f:Function):FFIField {
    // null in the needsSizes and hasSizes arrays signifies the return
    var needsSizes:Array<String> = [];
    var hasSizes:Array<String> = [];

    var ffiArgs = [ for (arg in f.args) {
      var type = mapTypeFFI(arg.type, field.pos);
      if (!type.isArgumentType())
        throw "!";
      if (type.needsSize()) {
        if (arg.name == "_")
          throw "!";
        needsSizes.push(arg.name);
      }
      switch (type) {
        case SizeOf(arg):
          if (hasSizes.indexOf(arg) != -1)
            throw "duplicate";
          hasSizes.push(arg);
        case SizeOfReturn:
          if (hasSizes.indexOf(null) != -1)
            throw "duplicate";
          hasSizes.push(null);
        case _:
      }
      type;
    } ];

    var ffiRet = mapTypeFFI(f.ret, field.pos);
    if (!ffiRet.isReturnType())
      throw "!";
    if (ffiRet.needsSize())
      needsSizes.push(null);

    for (need in needsSizes) {
      if (hasSizes.indexOf(need) == -1)
        throw "!";
      hasSizes.remove(need);
    }
    if (hasSizes.length > 0)
      throw "!";

    return Method(field.name, ffiArgs, ffiRet);
  }

  static function createFFI():Void {
    var ffi = new ammer.FFI(ctx.libname);
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
    if (config.debug)
      trace("FFI FIELDS:", ffi.fields);
    ctx.ffi = ffi;
  }

  static function createStubs():Void {
    switch (config.platform) {
      case Hl:
        new ammer.stub.StubHl(ctx).generate();
      case _:
    }
  }

  static function patchImpl():Void {
    var patcher = (switch (config.platform) {
      case Hl: new ammer.patch.PatchHl(ctx);
      case Cpp: new ammer.patch.PatchCpp(ctx);
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
      switch [ffiField, implField.kind] {
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
          methodPatcher.finish();
          f.expr = macro return ${mctx.wrapExpr};
          f.args = mctx.wrapArgs;
          f.ret = mapFFIType(ffiRet);
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
    if (config.debug)
      Sys.println(new haxe.macro.Printer().printTypeDefinition(c));
    Context.defineType(c);
  }

  public static function build():Array<Field> {
    configure();
    var implType = Context.getLocalClass().get();
    var libname = (switch (implType.superClass.params[0]) {
      case TInst(_.get() => {kind: KExpr({expr: EConst(CString(libname))})}, []):
        libname;
      case _:
        throw "!";
    });
    if (config.debug)
      Sys.println('[ammer] building $libname ...');
    ctx = {
      config: config,
      libname: libname,
      includePath: getPath('ammer.lib.${libname}.include'),
      libraryPath: getPath('ammer.lib.${libname}.library'),
      headers: getDefine('ammer.lib.${libname}.headers', '${libname}.h').split(","),
      implType: implType,
      implFields: Context.getBuildFields(),
      externName: 'AmmerExtern_$libname',
      externFields: [],
      externIsExtern: true,
      externMeta: [],
      ffi: null,
      stub: null
    };
    libraries.push(ctx);
    createFFI();
    createStubs();
    patchImpl();
    createExtern();
    var ret = ctx.implFields;
    if (config.debug) {
      var printer = new haxe.macro.Printer();
      for (f in ret) {
        Sys.println("IMPLFIELD: " + printer.printField(f));
      }
    }
    ctx = null;
    return ret;
  }

  static function runBuild():Void {
    switch (config.platform) {
      case Hl:
        ammer.build.BuildHl.build(config, libraries);
      case _:
    }
  }
}
