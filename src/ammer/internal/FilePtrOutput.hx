// ammer-bake: ammer.internal FilePtrOutput !macro
package ammer.internal;

import ammer.ffi.FilePtr;

class FilePtrOutput extends haxe.io.Output {
  var file:FilePtr;
  function new(file:FilePtr) {
    this.file = file;
  }

  override public function writeByte(c:Int):Void file.fputc(c);
  override public function writeBytes(s:haxe.io.Bytes, pos:Int, len:Int):Int {
    if (pos < 0 || len < 0 || pos + len > s.length)
      throw haxe.io.Error.OutsideBounds;
    var bytesRef = ammer.ffi.Bytes.fromHaxeRef(s.sub(pos, len));
    var ret = file.fwrite(bytesRef.bytes.offset(pos), 1, len);
    bytesRef.unref();
    return ret;
  }
  override public function flush():Void file.fflush();
  override public function close():Void file.fclose(); // TODO: only close output?
}
