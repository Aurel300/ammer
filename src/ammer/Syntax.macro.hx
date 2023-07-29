package ammer;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Syntax {
  public static function build():Array<Field> {
    return [ for (field in Context.getBuildFields()) {
      pos: field.pos,
      name: field.name,
      meta: field.meta,
      kind: (switch (field.kind) {
        case FVar(t, e): FVar(t, e != null ? process(e) : null);
        case FFun(f): FFun({
            ret: f.ret,
            params: f.params,
            expr: f.expr != null ? process(f.expr) : null,
            args: f.args,
          });
        case FProp(get, set, t, e): FProp(get, set, t, e != null ? process(e) : null);
      }),
      doc: field.doc,
      access: field.access,
    } ];
  }

  static function process(e:Expr):Expr {
    return (switch (e) {
      // TODO: support bytes for ref/copy as well
      case macro @copy $expr: macro ammer.Lib.vecToArrayCopy($expr);
      case macro @leak $expr: macro { var _ref = new ammer.ffi.Haxe($expr); _ref.incref(); _ref; }
      // TODO: this @ret solution is not good; process typed fields instead?
      // TODO: reduce duplication
      // TODO: better tempvar names
      case macro @ret $e{{expr: ECall(f, args)}}:
        var block = [];
        var frees = [];
        args = [ for (idx => arg in args) switch (arg) {
          case macro @ref $expr:
            var tmp = '_syntax_arg$idx';
            block.push(macro var $tmp = ammer.Lib.vecToArrayRef($e{process(expr)}));
            frees.push(macro $i{tmp}.unref());
            macro $i{tmp}.array;
          case macro @copyfree $expr:
            var tmp = '_syntax_arg$idx';
            block.push(macro var $tmp = ammer.Lib.vecToArrayCopy($e{process(expr)}));
            frees.push(macro $i{tmp}.free());
            macro $i{tmp};
          case _: process(arg);
        } ];
        if (block.length > 0) {
          var call = {expr: ECall(process(f), args), pos: e.pos};
          block.push(macro var _ret = $call);
          block.push(macro $b{frees});
          block.push(macro _ret);
          macro $b{block};
        } else {
          ExprTools.map(e, process);
        }
      case {expr: ECall(f, args)}:
        var block = [];
        var frees = [];
        args = [ for (idx => arg in args) switch (arg) {
          case macro @ref $expr:
            var tmp = '_syntax_arg$idx';
            block.push(macro var $tmp = ammer.Lib.vecToArrayRef($e{process(expr)}));
            frees.push(macro $i{tmp}.unref());
            macro $i{tmp}.array;
          case macro @copyfree $expr:
            var tmp = '_syntax_arg$idx';
            block.push(macro var $tmp = ammer.Lib.vecToArrayCopy($e{process(expr)}));
            frees.push(macro $i{tmp}.free());
            macro $i{tmp};
          case _: process(arg);
        } ];
        if (block.length > 0) {
          var call = {expr: ECall(process(f), args), pos: e.pos};
          block.push(macro $call);
          block.push(macro if (true) $b{frees});
          macro $b{block};
        } else {
          ExprTools.map(e, process);
        }
      case macro @ref $expr: throw Context.error("@ref can only be used on function call arguments", e.pos);
      case macro @copyfree $expr: throw Context.error("@copyfree can only be used on function call arguments", e.pos);
      case _: ExprTools.map(e, process);
    });
  }
}
