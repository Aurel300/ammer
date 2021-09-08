package ammer.stub;

import ammer.FFIType;

class StubBaseC {
  public static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case Void: "void";
      case Bool: "bool";
      case Integer(Signed8): "int8_t";
      case Integer(Signed16): "int16_t";
      case Integer(Signed32): "int32_t";
      case Integer(Signed64): "int64_t";
      case Integer(Unsigned8): "uint8_t";
      case Integer(Unsigned16): "uint16_t";
      case Integer(Unsigned32): "uint32_t";
      case Integer(Unsigned64): "uint64_t";
      case Float(Float32): "float";
      case Float(Float64): "double";
      case Bytes: "unsigned char *";
      case String: "const char *";
      case ArrayDynamic(_, t): '${mapTypeC(t, "")} *';
      case ArrayFixed(_, t, _): '${mapTypeC(t, "")} *';
      case This: throw "!";
      case LibType(t, _) | Nested(LibType(t, _)) | Alloc(LibType(t, _)):
        t.kind.match(Pointer(false)) ? t.nativeName : '${t.nativeName} *';
      case LibIntEnum(t, _): '${t.nativeName}';
      case LibSub(_): throw "!";
      case OutPointer(LibType(t, _)):
        t.kind.match(Pointer(false)) ? '${t.nativeName} *' : '${t.nativeName} **';
      case OutPointer(_): throw "!";
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
      case Unsupported(cName): cName;
      case NativeHl(_, _, _): throw "!";
    }) + (name != "" ? ' $name' : "");
  }
}
