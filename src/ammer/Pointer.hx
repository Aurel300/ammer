package ammer;

@:genericBuild(ammer.Pointer.initType())
class Pointer<Const, T> {
  public static macro function initType();
}

@:autoBuild(ammer.Ammer.buildType())
class PointerProcessed<Const, T> {}
