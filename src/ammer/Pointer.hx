package ammer;

@:genericBuild(ammer.Pointer.initType(true))
class Pointer<Const, T> {
  public static macro function initType(star:Bool);
}

@:autoBuild(ammer.Ammer.buildType())
class PointerProcessed<Const, T> {}
