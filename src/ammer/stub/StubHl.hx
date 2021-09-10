package ammer.stub;

import ammer.Config.AmmerLibraryConfig;

using ammer.FFITools;
using StringTools;

class StubHl {
  static var CONSTANT_TYPES_HL:Map<FFIType, {hlt:String, c:String}> = [
    Integer(Signed32) => {hlt: "i32", c: "int"},
    String => {hlt: "bytes", c: "char *"},
    Bool => {hlt: "bool", c: "bool"},
    Float(Float32) => {hlt: "f64", c: "double"},
  ];

  static var library:AmmerLibraryConfig;
  static var lb:LineBuf;

  static function generateHeader():Void {
    lb.a('#define HL_NAME(n) ammer_${library.name}_ ## n\n');
    lb.a('#include <hl.h>\n');
    for (header in library.headers)
      lb.a('#include <${header}>\n');
  }

  static function mapTypeHlFFI(t:FFIType):String {
    return (switch (t) {
      case Void: "_VOID";
      case Bool: "_BOOL";
      case Integer(Signed8 | Unsigned8): "_I8";
      case Integer(Signed16 | Unsigned16): "_I16";
      case Integer(Signed32 | Unsigned32): "_I32";
      case Integer(Signed64 | Unsigned64): "_I64";
      case Float(Float32): "_F32";
      case Float(Float64): "_F64";
      case Bytes: "_BYTES";
      case String: "_BYTES";
      case ArrayDynamic(idx, _) | ArrayFixed(idx, _, _): '_ABSTRACT(${Ammer.typeMap['ammer.externs.AmmerArray_$idx.AmmerArray_$idx'].nativeName})';
      case Derived(_, t): mapTypeHlFFI(t);
      case WithSize(_, t): mapTypeHlFFI(t);
      case Closure(_, args, ret, _): '_FUN(${mapTypeHlFFI(ret)}, ${args.map(mapTypeHlFFI).filter(a -> a != null).join(" ")})';
      case ClosureDataUse: null;
      case ClosureData(_): "_I32"; // dummy
      case LibType(t, _): '_ABSTRACT(${t.nativeName})';
      case LibIntEnum(_, _): "_I32";
      case OutPointer(LibType(t, _)): '_OBJ(_ABSTRACT(${t.nativeName}))';
      case Nested(LibType(t, _)): '_ABSTRACT(${t.nativeName})';
      case Alloc(LibType(t, _)): '_ABSTRACT(${t.nativeName})';
      case NoSize(t): mapTypeHlFFI(t);
      case SizeOfReturn: "_REF(_I32)";
      case SizeOf(_): "_I32";
      case SizeOfField(_): "_I32";
      case SameSizeAs(t, _): mapTypeHlFFI(t);
      case NativeHl(_, ffiName, _): ffiName;
      case Unsupported(_): "_I32"; // dummy
      case _: throw "!";
    });
  }

  static function mapTypeC(t:FFIType, name:String, closure:Bool = false):String {
    return (switch (t) {
      case Closure(_, _, _, _): 'vclosure *$name';
      case ClosureDataUse: 'void *$name';
      case ClosureData(_): 'int $name';
      case OutPointer(LibType(_, _)): 'vdynamic *$name';
      case Nested(LibType(t, _)) if (closure): '${t.nativeName} $name';
      case NativeHl(_, _, cName): '$cName $name';
      case Unsupported(_): 'int $name';
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  static function generateClosureWrappers(ctx:AmmerContext):Void {
    for (i in 0...ctx.closureTypes.length) {
      var method = ctx.closureTypes[i];
      lb.ai('static ${mapTypeC(method.ret, "")} wc_${i}_${ctx.index}(');
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i', true) ].filter(a -> a != null).join(", "));
      lb.a(") {\n");
      lb.indent(() -> {
        lb.ai('vclosure *cl = (vclosure *)(${method.dataAccess.join("->")});\n');
        inline function print(withValue:Bool):Void {
          if (method.ret == Void)
            lb.ai("");
          else
            lb.ai("return ");
          lb.a('((');
          lb.a(mapTypeC(method.ret, ""));
          lb.a(' (*)(');
          lb.a((withValue ? ["vdynamic *"] : []).concat([ for (i in 0...method.args.length) switch (method.args[i]) {
            case ClosureDataUse: continue;
            case _: mapTypeC(method.args[i], "");
          } ]).filter(a -> a != null).join(", "));
          lb.a('))(cl->fun))(');
          lb.a((withValue ? ["cl->value"] : []).concat([ for (i in 0...method.args.length) switch (method.args[i]) {
            case ClosureDataUse: continue;
            case Nested(LibType(t, _)): '&arg_$i';
            case _: 'arg_$i';
          } ]).join(", "));
          lb.a(');\n');
        }
        lb.ai("if (cl->hasValue)\n");
        lb.indent(() -> print(true));
        lb.ai("else\n");
        lb.indent(() -> print(false));
      });
      lb.ai("}\n");
    }
  }

  static function generateArrayWrappers(ctx:AmmerContext):Void {
    for (i in 0...ctx.arrayTypes.length) {
      lb.ai('typedef ${mapTypeC(ctx.arrayTypes[i].ffi, "")} wt_array_${i}_${ctx.index};\n');
    }
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function generateMethod(method:FFIMethod, ctx:AmmerContext):Void {
    lb.ai('HL_PRIM ${mapTypeC(method.ret, "")} HL_NAME(${mapMethodName(method.uniqueName)})(');
    if (method.args.length == 0)
      lb.a("void");
    else
      lb.a([ for (i in 0...method.args.length) mapTypeC(method.args[i], 'arg_$i') ].filter(a -> a != null).join(", "));
    lb.a(") {\n");
    lb.indent(() -> {
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      switch (method.ret) {
        case Alloc(LibType(t, _)):
          lb.ai('${t.nativeName} *ret_alloc = (${t.nativeName} *)malloc(sizeof(${t.nativeName}));\n');
        case _:
      }
      var callArgs = [ for (i in 0...method.args.length) {
        switch (method.args[i]) {
          case Closure(idx, _, _, _): '&wc_${idx}_${ctx.index}';
          case ClosureData(f): '(void *)arg_$f';
          case OutPointer(LibType(t, _)): '(${t.nativeName} **)(&(((void **)arg_$i)[1]))';
          case Nested(LibType(_, _)): '(*arg_$i)';
          case Unsupported(cName): '($cName)0';
          case _: 'arg_$i';
        }
      } ];
      if (method.isCppMemberCall)
        callArgs.pop();
      var call = '${method.native}(' + callArgs.join(", ") + ')';
      if (method.isCppConstructor)
        call = 'new $call';
      if (method.isCppMemberCall)
        call = 'arg_${callArgs.length}->$call';
      if (method.ret == Void)
        lb.ai("");
      else if (method.ret.match(Alloc(LibType(_, _))))
        lb.ai("*ret_alloc = ");
      else
        lb.ai("return ");
      if (method.cReturn != null) {
        // TODO: RET_ELEM_TYPE should be implemented better
        // TODO: remove duplication of this in StubCpp and StubLua
        lb.a(method.cReturn
          .replace("%RET_ELEM_TYPE%", switch (mapTypeC(method.ret, "")) {
            case t if (t.endsWith(" *")): t.substr(0, t.length - 2);
            case _: "?";
          })
          .replace("%RET_TYPE%", mapTypeC(method.ret, ""))
          .replace("%CALL%", call));
        lb.a(";\n");
      }
      else
        lb.a('$call;\n');
      if (method.ret.match(Alloc(LibType(_, _))))
        lb.ai("return ret_alloc;\n");
    });
    lb.ai("}\n");
    lb.ai('DEFINE_PRIM(${mapTypeHlFFI(method.ret)}, ${mapMethodName(method.uniqueName)}, ');
    if (method.args.length == 0)
      lb.a("_NO_ARG");
    else
      lb.a([ for (arg in method.args) mapTypeHlFFI(arg) ].filter(a -> a != null).join(" "));
    lb.a(");\n");
  }

  static function generateConstants(ctx:AmmerContext):Void {
    for (t in FFITools.CONSTANT_TYPES) {
      if (!ctx.ffiConstants.exists(t.ffi))
        continue;
      lb.ai('HL_PRIM varray *HL_NAME(g_${t.name}_${ctx.index})(void) {\n');
      lb.indent(() -> {
        lb.ai('varray *ret = hl_alloc_array(&hlt_${CONSTANT_TYPES_HL[t.ffi].hlt}, ${ctx.ffiConstants[t.ffi].length});\n');
        for (constant in ctx.ffiConstants[t.ffi]) {
          lb.ai('hl_aptr(ret, ${CONSTANT_TYPES_HL[t.ffi].c})[${constant.index}] = ${constant.native};\n');
        }
        lb.ai('return ret;\n');
      });
      lb.ai("}\n");
      lb.ai('DEFINE_PRIM(_ARR, g_${t.name}_${ctx.index}, _NO_ARG);\n');
    }
  }

  public static function generate(config:Config, library:AmmerLibraryConfig):Void {
    StubHl.library = library;
    lb = new LineBuf();
    generateHeader();
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      generateClosureWrappers(ctx);
      generateArrayWrappers(ctx);
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.uniqueName))
          continue; // TODO: make sure the field has the same signature
        generated[method.uniqueName] = true;
        generateMethod(method, ctx);
      }
      generateConstants(ctx);
    }
    Utils.update('${config.hl.build}/ammer_${library.name}.hl.${library.abi.fileExtension()}', lb.dump());
  }
}
