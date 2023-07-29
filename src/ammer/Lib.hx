// ammer-bake: ammer Lib true
package ammer;

class Lib {
  // struct methods
  public static macro function allocStruct<T>(cls:Class<T>, ?initVals:{}):T;
  public static macro function nullPtrStruct<T>(cls:Class<T>):T;

  // box methods
  public static macro function allocBox<T>(cls:Class<T>, ?initVal:T):ammer.ffi.Box<T>;
  public static macro function nullPtrBox<T>(cls:Class<T>):ammer.ffi.Box<T>;

  // array methods
  public static macro function allocArray<T>(cls:Class<T>, size:Int, ?initVal:T):ammer.ffi.Array<T>;
  public static macro function nullPtrArray<T>(cls:Class<T>):ammer.ffi.Array<T>;

  public static macro function vecToArrayCopy<T>(vec:haxe.ds.Vector<T>):ammer.ffi.Array<T>;
  public static macro function vecToArrayRef<T>(vec:haxe.ds.Vector<T>):ammer.ffi.ArrayRef<T>;
  public static macro function vecToArrayRefForce<T>(vec:haxe.ds.Vector<T>):ammer.ffi.ArrayRef<T>;

  // Haxe ref methods
  public static macro function createHaxeRef<T>(cls:Class<T>, e:T):ammer.ffi.Haxe<T>;
}
