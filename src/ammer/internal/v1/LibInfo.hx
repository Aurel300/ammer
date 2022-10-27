// ammer-bake: ammer.internal.v1 LibInfo true
package ammer.internal.v1;

#if macro

import haxe.macro.Expr;
import haxe.macro.Type;

typedef LibInfoArray = {
  arrayCt:ComplexType,
  arrayRefCt:ComplexType,
  alloc:Expr, // == arrayMarshal.alloc(macro _size)
  fromHaxeCopy:Expr, // == arrayMarshal.fromHaxeCopy(macro _vec)
  fromHaxeRef:Null<Expr>, // == arrayMarshal.fromHaxeRef(macro _vec)

  #if ammer
  ?elementType:Type,
  ?arrayMarshal:ammer.core.MarshalArray<ammer.core.TypeMarshal>,
  #end
};

typedef LibInfoBox = {
  boxCt:ComplexType,
  alloc:Expr, // == boxMarshal.alloc

  #if ammer
  ?elementType:Type,
  ?boxMarshal:ammer.core.MarshalBox<ammer.core.TypeMarshal>,
  #end
};

typedef LibInfoCallback = {
  isGlobal:Bool,
  callbackCt:ComplexType,
  funCt:ComplexType,
  callbackName:String,

  #if ammer
  ?ctx:LibContext,
  #end
};

typedef LibInfoEnum = {
  #if ammer
  ?marshal:ammer.core.TypeMarshal,
  #end
};

typedef LibInfoHaxeRef = {
  create:Expr, // == marshal.create(macro _hxval)

  #if ammer
  ?ctx:LibContext,
  ?elementType:Type,
  ?marshal:ammer.core.MarshalHaxe<ammer.core.TypeMarshal>,
  #end
};

typedef LibInfoLibrary = {
  #if ammer
  ?nativePrefix:String,
  #end
};

typedef LibInfoOpaque = {
  opaqueName:String,

  #if ammer
  ?ctx:LibContext,
  ?implType:Type,
  ?marshal:ammer.core.MarshalOpaque<ammer.core.TypeMarshal>,
  ?nativePrefix:String,
  #end
};

typedef LibInfoStruct = {
  alloc:Bool,
  ?gen:{
    ?alloc:String,
    ?free:String,
    ?nullPtr:String,
  },
  structName:String,

  #if ammer
  ?ctx:LibContext,
  ?implType:Type,
  // used for recursive field refs
  ?marshalOpaque:ammer.core.TypeMarshal,
  ?marshalDeref:ammer.core.TypeMarshal,
  ?marshal:ammer.core.MarshalStruct<ammer.core.TypeMarshal>,
  ?nativePrefix:String,
  #end
};

typedef LibInfoSublibrary = {
  #if ammer
  ?ctx:LibContext,
  ?nativePrefix:String,
  #end
};

typedef LibInfoFileSource = {
  // local filename
  ?name:String,

  ?description:String,

  // hash of file
  //?digest:String,

  // pre-baked release download info
  // URL for automatic download
  ?downloadFrom:String,

  // operating system
  ?os:String,

  // supported architectures (an array to support fat binaries)
  ?architectures:Array<String>,

  // minimum OS version supported by file
  ?minVersion:String,

  // maximum OS version supported by file
  ?maxVersion:String,
};

typedef LibInfoFile = {
  // destination filename (may contain %DLL% etc)
  dst:String,
  sources:Array<LibInfoFileSource>,
};

class LibInfo {
  public var name:String;
  public var herePos:Position;
  public var setupToBin:String;

  // String key is typeId of the implType

  public var arrays:{
    byTypeId:Map<String, LibInfoArray>,
    byElementTypeId:Map<String, LibInfoArray>,
  } = {
    byTypeId: [],
    byElementTypeId: [],
  };
  public var boxes:{
    byTypeId:Map<String, LibInfoBox>,
    byElementTypeId:Map<String, LibInfoBox>,
  } = {
    byTypeId: [],
    byElementTypeId: [],
  };
  public var callbacks:{
    byTypeId:Map<String, LibInfoCallback>,
    byElementTypeId:Map<String, LibInfoCallback>,
  } = {
    byTypeId: [],
    byElementTypeId: [],
  };
  public var enums:Map<String, LibInfoEnum> = [];
  public var haxeRefs:{
    byTypeId:Map<String, LibInfoHaxeRef>,
    byElementTypeId:Map<String, LibInfoHaxeRef>,
  } = {
    byTypeId: [],
    byElementTypeId: [],
  };
  public var opaques:Map<String, LibInfoOpaque> = [];
  public var structs:Map<String, LibInfoStruct> = [];
  public var sublibraries:Map<String, LibInfoSublibrary> = [];
  public var files:Array<LibInfoFile> = [];

  public function new() {}
}

#end
