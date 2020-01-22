package ammer.stub;

import ammer.FFIType;

class StubBaseC {
  public static function mapTypeC(t:FFIType):String {
    return (switch (t) {
      case Void: "void";
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
      case This: throw "!";
      case Opaque(id, _): '${Ammer.opaqueMap[id].nativeName} *';
      //case Deref(t): '${mapTypeC(t)} *';
      case NoSize(t): mapTypeC(t);
      case SizeOfReturn: "size_t *";
      case SizeOf(_): "int";
      case SameSizeAs(t, _): mapTypeC(t);
    });
  }
}
