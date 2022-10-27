package ammer.internal;

#if macro

import haxe.macro.Expr;

using Lambda;
using StringTools;

// TODO: parse meta positions as well for more precise errors?
typedef MetaParser = (args:Array<Expr>)->Null<ParsedMeta>;

enum ParsedMeta {
  // c.*
  PMC_Cast(_:String);
  PMC_MacroCall;
  PMC_Prereturn(_:String);
  PMC_Return(_:String);
  // gen.*
  PMGen_Alloc(_:String);
  PMGen_Free(_:String);
  PMGen_NullPtr(_:String);
  // lib.*
  PMLib_Define(_:String);
  PMLib_Define_CodeOnly(_:String);
  // TODO: PMLib_Defines(_:Array<String>);
  PMLib_Framework(_:String);
  PMLib_Frameworks(_:Array<String>);
  PMLib_IncludePath(_:String);
  PMLib_IncludePaths(_:Array<String>);
  PMLib_Language(_:ammer.core.LibraryLanguage);
  PMLib_LibraryPath(_:String);
  PMLib_LibraryPaths(_:Array<String>);
  PMLib_LinkName(_:String);
  PMLib_LinkNames(_:Array<String>);
  PMLib_Headers_Include(_:String);
  PMLib_Headers_Import(_:String);
  PMLib_Headers_IncludeLocal(_:String);
  PMLib_Headers_ImportLocal(_:String);
  PMLib_Headers_IncludeGlobal(_:String);
  PMLib_Headers_ImportGlobal(_:String);
  // ret.*
  PMRet_Derive(e:Expr, ct:ComplexType);
  // other
  PMAlloc; // TODO: rename to something better?
  PMDerive(_:Expr);
  PMHaxe;
  PMNative(_:String);
  PMNativePrefix(_:String);
  PMSkip;
  PMSub(_:ComplexType);
}

class Meta {
  static function parseComplexType(e:Expr, arg:Int):ComplexType {
    var ct = Utils.complexTypeExpr(e);
    if (ct == null)
      throw 'expected reference to type using (_ : path.to.Type) syntax (argument ${arg + 1})';
    return ct;
  }

  static function parseExpr(e:Expr, arg:Int):Expr {
    return e;
  }

  static function parseString(e:Expr, arg:Int):String {
    return (switch (e.expr) {
      case EConst(CString(v)): v;
      case _: throw 'expected string constant (argument ${arg + 1})';
    });
  }

  static function parseStringArray(e:Expr, arg:Int):Array<String> {
    return (switch (e.expr) {
      case EArrayDecl(vs): [ for (v in vs) switch (v.expr) {
          case EConst(CString(v)): v;
          case _: throw 'expected string constant (argument ${arg + 1})';
        } ];
      case _: throw 'expected array of string constants (argument ${arg + 1})';
    });
  }

  static function parseEnum<T>(map:Map<String, T>):(e:Expr, arg:Int)->T {
    return (e:Expr, arg:Int) -> {
      switch (e.expr) {
        case EConst(CIdent(id)):
          if (!map.exists(id)) {
            var keys = [for (k in map.keys()) k];
            keys.sort(Reflect.compare);
            throw 'invalid value, should be one of ${keys.join(", ")} (argument ${arg + 1})';
          }
          map[id];
        case _: throw 'expected identifier (argument ${arg + 1})';
      }
    };
  }

  static function parser0(v:ParsedMeta):MetaParser {
    return (args) -> {
      if (args.length != 0)
        throw 'expected no arguments (${args.length} provided)';
      v;
    };
  }

  static function parser1<T1>(p1:(Expr, Int)->T1, f:(T1)->ParsedMeta):MetaParser {
    return (args) -> {
      if (args.length != 1)
        throw 'expected 1 argument (${args.length} provided)';
      f(p1(args[0], 0));
    };
  }

  static function parser2<T1, T2>(p1:(Expr, Int)->T1, p2:(Expr, Int)->T2, f:(T1, T2)->ParsedMeta):MetaParser {
    return (args) -> {
      if (args.length != 2)
        throw 'expected 2 arguments (${args.length} provided)';
      f(p1(args[0], 0), p2(args[1], 1));
    };
  }

  /**
    Metadata allowed for the class defining a library.
  **/
  public static final LIBRARY_CLASS = [
    "lib.define" => parser1(parseString, PMLib_Define),
    "lib.define.codeOnly" => parser1(parseString, PMLib_Define_CodeOnly),
    "lib.framework" => parser1(parseString, PMLib_Framework),
    "lib.frameworks" => parser1(parseStringArray, PMLib_Frameworks),
    "lib.includePath" => parser1(parseString, PMLib_IncludePath),
    "lib.includePaths" => parser1(parseStringArray, PMLib_IncludePaths),
    "lib.libraryPath" => parser1(parseString, PMLib_LibraryPath),
    "lib.libraryPaths" => parser1(parseStringArray, PMLib_LibraryPaths),
    "lib.language" => parser1(parseEnum([
        "C" => ammer.core.LibraryLanguage.C,
        "Cpp" => Cpp,
        "ObjC" => ObjectiveC,
        "ObjCpp" => ObjectiveCpp,
      ]), PMLib_Language),
    "lib.linkName" => parser1(parseString, PMLib_LinkName),
    "lib.linkNames" => parser1(parseStringArray, PMLib_LinkNames),
    "lib.headers.include" => parser1(parseString, PMLib_Headers_Include),
    "lib.headers.import" => parser1(parseString, PMLib_Headers_Import),
    "lib.headers.includeLocal" => parser1(parseString, PMLib_Headers_IncludeLocal),
    "lib.headers.importLocal" => parser1(parseString, PMLib_Headers_ImportLocal),
    "lib.headers.includeGlobal" => parser1(parseString, PMLib_Headers_IncludeGlobal),
    "lib.headers.importGlobal" => parser1(parseString, PMLib_Headers_ImportGlobal),
    "nativePrefix" => parser1(parseString, PMNativePrefix),
    "sub" => parser1(parseComplexType, PMSub),
  ];

  /**
    Metadata allowed for the class defining a sublibrary.
  **/
  public static final SUBLIBRARY_CLASS = [
    "nativePrefix" => parser1(parseString, PMNativePrefix),
    "sub" => parser1(parseComplexType, PMSub), // TODO: disallow?
  ];

  public static final COMMON_METHOD = [
    "haxe" => parser0(PMHaxe),
    "native" => parser1(parseString, PMNative),
    "macroCall" => parser0(PMC_MacroCall),
    "c.cast" => parser1(parseString, PMC_Cast),
    "c.macroCall" => parser0(PMC_MacroCall),
    "c.prereturn" => parser1(parseString, PMC_Prereturn),
    "c.return" => parser1(parseString, PMC_Return),
    // "cpp.constructor",
    // "cpp.member",
    "ret.derive" => parser2(parseExpr, parseComplexType, PMRet_Derive),
  ];

  /**
    Metadata allowed for a method of a library.
  **/
  public static final LIBRARY_METHOD = COMMON_METHOD;

  /**
    Metadata allowed for a method of a struct.
  **/
  public static final STRUCT_METHOD = COMMON_METHOD;

  /**
    Metadata allowed for a variable of a struct.
  **/
  public static final STRUCT_VAR = [
    "haxe" => parser0(PMHaxe),
    "native" => parser1(parseString, PMNative),
    // TODO: get/set/ref
  ];

  public static final COMMON_FIELD = [
    "haxe" => parser0(PMHaxe),
    "native" => parser1(parseString, PMNative),
  ];

  public static final ENUM_FIELD = [
    "native" => parser1(parseString, PMNative),
  ];

  // /**
  //   Metadata allowed for a variable of a library.
  // **/
  // public static final LIBRARY_VARIABLE = [
  //   "native",
  // ];

  /**
    Metadata allowed for the class defining a struct type.
  **/
  public static final STRUCT_CLASS = [
    "alloc" => parser0(PMAlloc),
    "nativePrefix" => parser1(parseString, PMNativePrefix),
    "sub" => parser1(parseComplexType, PMSub),
    // "struct", // TODO: deprecation warning?
    "gen.alloc" => parser1(parseString, PMGen_Alloc),
    "gen.free" => parser1(parseString, PMGen_Free),
    "gen.nullPtr" => parser1(parseString, PMGen_NullPtr),
  ];

  /**
    Metadata allowed for the class defining an opaque type.
  **/
  public static final OPAQUE_CLASS = [
    "nativePrefix" => parser1(parseString, PMNativePrefix),
    //"sub" => parser1(parseComplexType, PMSub),
  ];

  public static final METHOD_ARG = [
    "c.cast" => parser1(parseString, PMC_Cast),
    "skip" => parser0(PMSkip),
    "derive" => parser1(parseExpr, PMDerive),
  ];

  /**
    Iterate through the given `metas`. Any entries that do not start with
    `:ammer` will be ignored.

    If `strict` is `true`, all `:ammer.*` metadata must be present in the
    `parsers` map to be accepted; an error is thrown if not.

    If `strict` is `false`, `:ammer.*` metadata which are not present in the
    `parsers` map are ignored.
  **/
  public static function extract(
    metas:Metadata,
    parsers:Map<String, MetaParser>,
    strict:Bool = true
  ):Array<ParsedMeta> {
    var ret = [];
    for (meta in metas) {
      if (!meta.name.startsWith(":ammer."))
        continue;
      var id = meta.name.substr(":ammer.".length);
      Reporting.withPosition(meta.pos, () -> {
        var parser = parsers[id];
        if (parser == null) {
          if (strict) {
            var ids = [ for (k => _ in parsers) k ];
            ids.sort(Reflect.compare);
            Reporting.error('unsupported or incorrectly specified ammer metadata ${meta.name} (should be one of ${ids.join(", ")})');
          }
          return;
        }
        try {
          ret.push(parser(meta.params));
        } catch (error:String) {
          Reporting.error('cannot parse ammer metadata ${meta.name}: $error');
        }
      });
    }
    return ret;
  }
}

#end
