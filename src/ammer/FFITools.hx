package ammer;

class FFITools {
  public static function isVirtualType(t:ammer.FFI.FFIType):Bool {
    return (switch (t) {
      case ReturnSizePtr(_): true;
      case SizePtr(_, _): true;
      case _: false;
    });
  }

  public static function needsSize(t:ammer.FFI.FFIType):Bool {
    return (switch (t) {
      case /*String | */Bytes: true;
      case _: false;
    });
  }
}
