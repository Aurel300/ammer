package ammer;

class FFITools {
  public static function isArgumentType(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _) | Void: false;
      case _: true;
    });
  }

  public static function isReturnType(t:FFIType):Bool {
    return (switch (t) {
      case SizeOf(_) | SizeOfReturn: false;
      case _: true;
    });
  }

  public static function isVariableType(t:FFIType):Bool {
    return (switch (t) {
      case Int: true;
      case String: true;
      case Bool: true;
      case Float: true;
      case _: false;
    });
  }

  public static function needsSize(t:FFIType):Bool {
    return (switch (t) {
      case SameSizeAs(_, _): false;
      case /*String | */Bytes: true;
      case _: false;
    });
  }
}
