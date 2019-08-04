package ammer;

class LineBuf {
  var currentIndent:String = "";
  var buf = new StringBuf();
  var tmpCounter = 0;

  public function new() {}

  public inline function ai(data:String):Void {
    buf.add('$currentIndent$data');
  }

  public inline function a(data:String):Void {
    buf.add(data);
  }

  public inline function fresh():Int {
    return tmpCounter++;
  }

  public function indent(f:() -> Void, ?with:String = "  "):Void {
    var prev = currentIndent;
    currentIndent += with;
    f();
    currentIndent = prev;
  }

  public function dump():String {
    var ret = buf.toString();
    buf = new StringBuf();
    tmpCounter = 0;
    return ret;
  }
}
