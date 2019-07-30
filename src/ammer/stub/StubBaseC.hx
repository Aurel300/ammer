package ammer.stub;

import ammer.FFI;
import ammer.FFIType;

class StubBaseC implements Stub {
  var ctx:AmmerContext;
  var ai:String->Void; // with indent
  var a:String->Void;
  var currentIndent:String = "";

  function indent(f:() -> Void):Void {
    var prev = currentIndent;
    currentIndent += "  ";
    f();
    currentIndent = prev;
  }

  function mapTypeC(t:FFIType):String {
    return (switch (t) {
      case Bool: "bool";
      case Int: "int";
      case I8(null): "char";
      case I16(null): "short";
      case I32(null): "int";
      case I64(null): "long";
      case UI8(null): "unsigned char";
      case UI16(null): "unsigned short";
      case UI32(null): "unsigned int";
      case UI64(null): "unsigned long";
      case I8(a) | I16(a) | I32(a) | I64(a) | UI8(a) | UI16(a) | UI32(a) | UI64(a): a;
      case Float: "double";
      case Bytes: "unsigned char *";
      case String: "char *";
      case ReturnSizePtr(t): "size_t *";
      case SizePtr(t, _): mapTypeC(t);
    });
  }

  public function generate():Void
    throw "not implemented";

  public function build():Array<String>
    throw "not implemented";
}
