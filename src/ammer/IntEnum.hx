package ammer;

@:genericBuild(ammer.IntEnum.initType())
class IntEnum<Const, T> {
  public static macro function initType();
}

@:autoBuild(ammer.Ammer.buildType())
class IntEnumProcessed<Const, T> {}
