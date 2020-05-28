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
      case Bytes: "unsigned char *";
      case String: "char *";
      case This: throw "!";
      case LibType(id, _): '${Ammer.typeMap[id].nativeName} *';
      case LibEnum(id): '${Ammer.typeMap[id].nativeName}';
      case LibSub(_): throw "!";
      case OutPointer(LibType(id, _)): '${Ammer.typeMap[id].nativeName} **';
      case OutPointer(_): throw "!";
      case Derived(_, t): return mapTypeC(t, name);
      case Closure(_, args, ret, _):
        return '${mapTypeC(ret, "")} (* $name)(${args.map(mapTypeC.bind(_, "")).join(", ")})';
      case ClosureDataUse: "void *";
      case ClosureData(_): "void *";
      case NoSize(t): return mapTypeC(t, name);
      case SizeOfReturn: "size_t *";
      case SizeOf(_): "int";
      case SameSizeAs(t, _): return mapTypeC(t, name);
    }) + (name != "" ? ' $name' : "");
  }
}
