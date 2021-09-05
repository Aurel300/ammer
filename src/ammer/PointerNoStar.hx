package ammer;

@:genericBuild(ammer.Pointer.initType(false))
class PointerNoStar<Const, T> {}

@:autoBuild(ammer.Ammer.buildType())
class PointerNoStarProcessed<Const, T> {}
