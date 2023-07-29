package ammer.ffi;

#if !macro

class FilePtr extends ammer.def.Opaque<"FILE*", ammer.internal.LibTypes> {
  public static final SEEK_SET:Int;
  public static final SEEK_CUR:Int;
  public static final SEEK_END:Int;
  public static final BUFSIZ:Int;
  public static final EOF:Int;
  public static final _IOFBF:Int;
  public static final _IOLBF:Int;
  public static final _IONBF:Int;
  public static final FILENAME_MAX:Int;
  public static final FOPEN_MAX:Int;
  public static final TMP_MAX:Int;
  public static final L_tmpnam:Int;

  public static final stderr:FilePtr;
  public static final stdin:FilePtr;
  public static final stdout:FilePtr;

  public static function fopen(filename:String, mode:String):FilePtr;
  public static function getchar():Int;
  public static function perror(str:String):Void;
  public static function putchar(char:Int):Int;
  public static function puts(str:String):Int;
  public static function remove(filename:String):Int;
  public static function rename(oldname:String, newname:String):Int;
  public static function tmpfile():FilePtr;
  // public static function tmpnam(str:String):String; // deprecated

  public function fclose(_:This):Void;
  public function feof(_:This):Bool;
  public function ferror(_:This):Int;
  public function fflush(_:This):Int;
  public function fgetc(_:This):Int;
  public function fgetpos(_:This, pos:FilePos):Int;
  //fgets
  //fprintf?
  public function fputc(char:Int, _:This):Int;
  public function fputs(str:String, _:This):Int;
  public function fread(ptr:Bytes, size:Size, count:Size, _:This):Size;
  public function freopen(filename:String, mode:String, _:This):FilePtr;
  // public function fscanf(_:This, format: ...)
  public function fseek(_:This, offset:Int64, origin:Int):Int;
  public function fsetpos(_:This, pos:FilePos):Int;
  public function ftell(_:This):Int64;
  public function fwrite(ptr:Bytes, size:Size, count:Size, _:This):Size;
  // getc -> fgetc
  // gets // removed
  // public static function printf(...)
  public function putc(char:Int, _:This):Int;
  public function rewind(_:This):Void;
  // public static function scanf(...)
  public function setbuf(_:This, @:ammer.c.cast("char*") buffer:Bytes):Void;
  public function setvbuf(_:This, @:ammer.c.cast("char*") buffer:Bytes, mode:Int, size:Size):Int;
  // public static function snprintf(...)
  // public static function sprintf(...)
  // public static function sscanf(...)
  public function ungetc(char:Int, _:This):Int;
  // public function vfprintf(...)
  // public function vfscanf(...)
  // public function vprintf(...)
  // public function vscanf(...)
  // public function vsnprintf(...)
  // public function vsprintf(...)
  // public function vsscanf(...)

  @:ammer.haxe public function output():haxe.io.Output return @:privateAccess new ammer.internal.FilePtrOutput(this);
  //public function input():haxe.io.Input return @:privateAccess new ammer.internal.FilePtrInput(this);
}

@:ammer.alloc
class FilePos extends ammer.def.Struct<"fpos_t", ammer.internal.LibTypes> {}

#end
