package ammer;

typedef AmmerConfig = {
  eval:AmmerConfigEval,
  hl:AmmerConfigHl,
  debug:Array<String>,
  platform:AmmerPlatform,
  useMSVC:Bool
};

typedef AmmerConfigEval = {
  build:String,
  output:String,
  haxeDir:String,
  bytecode:Bool
};

typedef AmmerConfigHl = {
  build:String,
  output:String,
  hlIncludePath:String,
  hlLibraryPath:String
};

typedef AmmerLibraryConfig = {
  name:String,
  includePath:String,
  libraryPath:String,
  headers:Array<String>,
  abi:AmmerAbi,
  contexts:Array<AmmerContext>
};

enum AmmerAbi {
  C;
  Cpp;
}
