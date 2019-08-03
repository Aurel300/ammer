package ammer;

class LineBuf {
  var currentIndent:String = "";
  var buf = new StringBuf();

  public function new() {}

  public inline function ai(data:String):Void {
    buf.add('$currentIndent$data');
  }

  public inline function a(data:String):Void {
    buf.add(data);
  }

  public function indent(f:() -> Void):Void {
    var prev = currentIndent;
    currentIndent += "  ";
    f();
    currentIndent = prev;
  }

  public function dump():String {
    var ret = buf.toString();
    buf = new StringBuf();
    return ret;
  }
}
