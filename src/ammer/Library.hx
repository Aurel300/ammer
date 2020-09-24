package ammer;
#if lua
typedef Single = Float;
#end

@:genericBuild(ammer.Library.initLibrary())
class Library<Const> {
  public static macro function initLibrary();
}

@:autoBuild(ammer.Ammer.build())
class LibraryProcessed<Const> {}
