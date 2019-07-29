package ammer;

@:genericBuild(ammer.Library.initLibrary())
class Library<Const> {
  public static macro function initLibrary();
  public static macro function build();
}

@:autoBuild(ammer.Library.build())
class LibraryProcessed {}
