package ammer.ffi;

#if !macro

@:genericBuild(ammer.internal.Entrypoint.genericBuildCallback())
class Callback<
  // function type as seen by the native library
  // e.g. (Int32, Haxe<(Int) -> Int>) -> Int32
  CallbackType,

  // function type as seen by Haxe
  // e.g. (Int) -> Int
  FunctionType,

  // where to find the function in CallbackType
  @:const CallTarget,

  // which arguments to pass through to the Haxe function
  @:const CallArgs,

  // parent library
  Lib
> {}

#end
