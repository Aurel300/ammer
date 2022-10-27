// ammer-bake: ammer Lib.macro macro
package ammer;

import haxe.macro.Context;
import haxe.macro.Context.currentPos;
import haxe.macro.Context.fatalError as fail;
import haxe.macro.Context.resolveType;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import ammer.internal.*;
import ammer.internal.v1.AmmerBaked.mergedInfo as info;

using Lambda;

class Lib {
  static function withPos<T>(pos:Position, f:()->T):T {
    return f();
  }
// ammer-include: internal/Utils.hx lib-baked
// ammer-include: Lib.macro.hx lib-baked
}
