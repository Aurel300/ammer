package ammer.patch;

import haxe.macro.Expr;

interface Patch {
  function visitMethod(mctx:AmmerMethodPatchContext):PatchMethod;
}

interface PatchMethod {
  function visitAnnotation(annotation:ammer.FFI.FFIFieldAnnotation):Void;
  function visitArgument(i:Int, ffi:FFIType, original:FunctionArg):Void;
  function visitReturn(ffi:FFIType, original:ComplexType):ComplexType;
  function finish():Void;
}
