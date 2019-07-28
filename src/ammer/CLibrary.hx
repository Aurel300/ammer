package ammer;

@:genericBuild(ammer.CLibrary.initLibrary())
class CLibrary<Const> {
  public static macro function initLibrary();
  public static macro function build();
}

@:autoBuild(ammer.CLibrary.build())
class CLibraryProcessed {}
