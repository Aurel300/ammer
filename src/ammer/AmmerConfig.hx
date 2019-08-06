package ammer;

typedef AmmerConfig = {
  eval:AmmerConfigEval,
  hl:AmmerConfigHl,
  debug:Bool,
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
