package ammer;

typedef AmmerConfig = {
  eval:AmmerConfigEval,
  hl:AmmerConfigHl,
  debug:Bool,
  platform:AmmerPlatform
};

typedef AmmerConfigEval = {
  build:String,
  output:String,
  haxeDir:String,
  bytecode:Bool
};

typedef AmmerConfigHl = {
  build:String,
  output:String
};
