package ammer.stub;

import ammer.FFIType;

class StubBaseC {
  public static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case Void: "void";
      case Bool: "bool";
      case Int: "int";
      case I8(null): "int";
      /*
      case I8(null): "char";
      case I16(null): "short";
      case I32(null): "int";
      case I64(null): "long";
      case UI8(null): "unsigned char";
      case UI16(null): "unsigned short";
      case UI32(null): "unsigned int";
      case UI64(null): "unsigned long";
      */
      case I8(a) | I16(a) | I32(a) | I64(a) | UI8(a) | UI16(a) | UI32(a) | UI64(a): a;
      case Float: "double";
      case Single: "float";
      case Bytes: "unsigned char *";
      case String: "const char *";
      case ArrayDynamic(_, t): '${mapTypeC(t, "")} *';
      case ArrayFixed(_, t, _): '${mapTypeC(t, "")} *';
      case This: throw "!";
      case LibType(t, _): '${t.nativeName} *';
      case LibIntEnum(t, _): '${t.nativeName}';
      case LibSub(_): throw "!";
      case OutPointer(LibType(t, _)): '${t.nativeName} **';
      case OutPointer(_): throw "!";
      case Nested(LibType(t, _)) | Alloc(LibType(t, _)): '${t.nativeName} *';
      case Nested(_) | Alloc(_): throw "!";
      case Derived(_, t): return mapTypeC(t, name);
      case WithSize(_, t): return mapTypeC(t, name);
      case Closure(_, args, ret, _):
        return '${mapTypeC(ret, "")} (* $name)(${args.map(mapTypeC.bind(_, "")).join(", ")})';
      case ClosureDataUse: "void *";
      case ClosureData(_): "void *";
      case NoSize(t): return mapTypeC(t, name);
      case SizeOfReturn: "size_t *";
      case SizeOf(_): "int";
      case SizeOfField(_): "int";
      case SameSizeAs(t, _): return mapTypeC(t, name);
      case NativeHl(_, _, _): throw "!";
    }) + (name != "" ? ' $name' : "");
  }
}
