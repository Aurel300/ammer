package ammer.internal;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import ammer.internal.Reporting.currentPos;
import ammer.internal.Reporting.resolveType;

using Lambda;

class Utils {
  // These methods are inserted into `Lib.macro.hx` when baking a library.
  // This avoids code duplication/synchronisation issues. Importantly, the code
  // is just string-pasted, so it is important that the `import`s that are
  // in `Lib.macro.baked.hx` are sufficient for the code to work.

// ammer-fragment-begin: lib-baked
  public static function access(t:{pack:Array<String>, module:String, name:String}, ?field:String):Array<String> {
    return t.pack.concat([t.module.split(".").pop(), t.name]).concat(field != null ? [field] : []);
  }

  public static function accessTp(t:TypePath):Array<String> {
    return t.pack.concat([t.name]).concat(t.sub != null ? [t.sub] : []);
  }

  public static function complexTypeExpr(e:Expr):Null<ComplexType> {
    function helper(e:Expr, fallback:Bool):Null<ComplexType> {
      return (switch (e.expr) {
        case EParenthesis(e): complexTypeExpr(e);
        case ECheckType(_, ct): ct;
        case _ if (!fallback):
          // TODO: kind of a hack
          var str = new haxe.macro.Printer().printExpr(e);
          helper(Context.parse('(_ : $str)', e.pos), true);
        case _: null;
      });
    }
    return helper(e, false);
  }

  public static function isNull(e:Expr):Bool {
    return e == null || e.expr.match(EConst(CIdent("null")));
  }

  // FFI type resolution allows some convenience shortcuts (e.g. Haxe `Int` is
  // the same as `ammer.ffi.Int32`). To avoid conflicts with multiple type IDs
  // resolving to the same thing, this function normalises the Haxe shortcuts
  // back to the `ammer.ffi.*` equivalents.
  public static function normaliseTypeId(id:String):String {
    return (switch (id) {
      case ".StdTypes.Void": "ammer.ffi.Void.Void";
      case ".StdTypes.Bool": "ammer.ffi.Bool.Bool";
      case ".UInt.UInt": "ammer.ffi.UInt32.UInt32";
      case ".StdTypes.Int": "ammer.ffi.Int32.Int32";
      case "haxe.Int64.Int64": "ammer.ffi.Int64.Int64";
      case ".StdTypes.Single": "ammer.ffi.Float32.Float32";
      case ".StdTypes.Float": "ammer.ffi.Float64.Float64";
      case ".String.String": "ammer.ffi.String.String";

      // platform specific
      case "cs.StdTypes.UInt8": "ammer.ffi.UInt8.UInt8";
      case "hl.UI16.UI16": "ammer.ffi.UInt16.UInt16";
      case "java.StdTypes.Int8": "ammer.ffi.Int8.Int8";
      case "java.StdTypes.Char16": "ammer.ffi.UInt16.UInt16";
      case "java.StdTypes.Int16": "ammer.ffi.Int16.Int16";

      case _: id;
    });
  }

  public static function triggerTyping(ct:ComplexType):Null<ClassType> {
    var type = resolveType(ct, currentPos());
    return (switch (type) {
      case TInst(ref, _): ref.get();
      case _: null;
    });
  }

  public static function typeId(t:{pack:Array<String>, module:String, name:String}):String {
    return normaliseTypeId('${t.pack.join(".")}.${t.module.split(".").pop()}.${t.name}');
  }

  public static function typeId2(t:Type):String {
    return normaliseTypeId(switch (t) {
      case TInst(_.get() => t, _): '${t.pack.join(".")}.${t.module.split(".").pop()}.${t.name}';
      case TAbstract(_.get() => t, _): '${t.pack.join(".")}.${t.module.split(".").pop()}.${t.name}';
      case TFun(args, ret): '(${args.map(arg -> typeId2(arg.t)).join(",")})->${typeId2(ret)}';
      case TType(_.get() => t, []): typeId2(t.type);
      case TDynamic(_): ".Any.Any"; // ?
      case _: trace(t); throw 0;
    });
  }

  public static function typeIdCt(ct:ComplexType):String {
    return normaliseTypeId(switch (ct) {
      case TPath(tp): '${tp.pack.join(".")}.${tp.name}.${tp.sub == null ? tp.name : tp.sub}';
      case _: throw 0;
    });
  }

  public static function expectTypePath(ct:ComplexType):TypePath {
    return (switch (ct) {
      case TPath(tp): tp;
      case _: throw 0;
    });
  }
// ammer-fragment-end: lib-baked

  public static function typeIdTp(tp:TypePath):String {
    return normaliseTypeId('${tp.pack.join(".")}.${tp.name}.${tp.sub == null ? tp.name : tp.sub}');
  }

  public static function exprOfType(ty:Type):Null<Expr> {
    return (switch (ty) {
      case TInst(_.get() => {kind: KExpr(expr)}, []): expr;
      case _: null;
    });
  }

  public static function exprArrayOfType(ty:Type):Null<Array<Expr>> {
    return (switch (ty) {
      case TInst(_.get() => {kind: KExpr({expr: EArrayDecl(exprs)})}, []): exprs;
      case _: null;
    });
  }

  public static function stringOfParam(ty:Type):Null<String> {
    return (switch (ty) {
      case TInst(_.get() => {kind: KExpr({expr: EConst(CString(val))})}, []): val;
      case _: null;
    });
  }

  public static function stringArrayOfParam(ty:Type):Null<Array<String>> {
    return (switch (ty) {
      case TInst(_.get() => {kind: KExpr({expr: EArrayDecl(vals)})}, []):
        [ for (val in vals) switch (val.expr) {
          case EConst(CString(val)): val;
          case _: return null;
        } ];
      case _: null;
    });
  }

  public static function classOfParam(tp:Type):Null<Ref<ClassType>> {
    return (switch (tp) {
      case TInst(lib, []): lib;
      case _: null;
    });
  }

  public static function funOfParam(tp:Type):Null<{args:Array<{t:Type, opt:Bool, name:String}>, ret:Type}> {
    return (switch (tp) {
      case TFun(args, ret): {args: args, ret: ret};
      case _: null;
    });
  }

  public static function updateField(field:Field, kind:FieldType):Field {
    return {
      pos: field.pos,
      name: field.name,
      meta: [],
      kind: kind,
      doc: field.doc,
      access: field.access,
    };
  }

  public static function exprMap(e:Expr, op:Null<Expr->Expr>):Expr {
    if (op == null)
      return e;
    return op(e);
  }

  public static var definedTypes:Array<TypeDefinition> = [];
  public static function defineType(tdef:TypeDefinition):Void {
    definedTypes.push(tdef);
    Context.defineType(tdef);
  }

  public static var modifiedTypes:Array<{t:ClassType, fields:Array<Field>}> = [];
  public static function modifyType(t:ClassType, fields:Array<Field>):Array<Field> {
    modifiedTypes.push({t: t, fields: fields});
    return fields;
  }
}

#end
