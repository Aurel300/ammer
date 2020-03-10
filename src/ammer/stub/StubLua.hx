package ammer.stub;

import ammer.Config.AmmerLibraryConfig;

using ammer.FFITools;
using StringTools;

class StubLua {
  static var library:AmmerLibraryConfig;
  static var lb:LineBuf;

  static function generateHeader():Void {
    lb.ai("#ifdef __cplusplus\n");
    lb.ai("extern \"C\" {\n");
    lb.ai("#endif\n");
    lb.ai('#include <lua.h>\n');
    lb.ai('#include <lualib.h>\n');
    lb.ai('#include <lauxlib.h>\n');
    lb.ai("#ifdef __cplusplus\n");
    lb.ai("}\n");
    lb.ai("#endif\n");
    for (header in library.headers)
      lb.ai('#include <${header}>\n');
  }

  static function mapTypeC(t:FFIType, name:String):String {
    return (switch (t) {
      case SizeOfReturn: "size_t" + (name != "" ? ' $name' : "");
      case _: StubBaseC.mapTypeC(t, name);
    });
  }

  public static function mapMethodName(name:String):String {
    return 'w_$name';
  }

  static function box(t:FFIType, expr:String, size:Null<String>):String {
    return (switch (t) {
      case Bool: 'lua_pushboolean(L, $expr)';
      case Int: 'lua_pushinteger(L, $expr)';
      case Float: 'lua_pushnumber(L, $expr)';
      case String | Bytes if (size != null): 'lua_pushlstring(L, $expr, $size)';
      case String | Bytes: 'lua_pushstring(L, $expr)';
      case SameSizeAs(t, _): box(t, expr, size);
      case LibType(_, _): 'lua_pushlightuserdata(L, $expr)';
      case _: throw "!";
    });
  }

  static function unbox(t:FFIType, i:Int):String {
    return (switch (t) {
      case Void: null;
      case Bool: 'lua_toboolean(L, $i)';
      case Int: 'lua_tointeger(L, $i)';
      case Float: 'lua_tonumber(L, $i)';
      case String:
        lb.ai('size_t arg_${i - 1}_size = 0;\n');
        'lua_tolstring(L, $i, &arg_${i - 1}_size)';
      case Bytes:
        lb.ai('size_t arg_${i - 1}_size = 0;\n');
        '(unsigned char *)lua_tolstring(L, $i, &arg_${i - 1}_size)';
      case NoSize(t): unbox(t, i);
      case SizeOf(_): 'lua_tointeger(L, $i)';
      case SizeOfReturn: "0";
      case LibType(_, _): 'lua_touserdata(L, $i)';
      case _: throw "!";
    });
  }

  static function generateMethod(method:FFIMethod):Void {
    lb.ai('static int ${mapMethodName(method.name)}(lua_State *L) {\n');
    lb.indent(() -> {
      var sizeOfReturn = null;
      for (i in 0...method.args.length) {
        if (method.args[i] == SizeOfReturn)
          sizeOfReturn = 'arg_$i';
        var unboxed = unbox(method.args[i], i + 1);
        if (unboxed == null)
          continue;
        lb.ai('${mapTypeC(method.args[i], 'arg_$i')} = $unboxed;\n');
      }
      switch (method.ret) {
        case SameSizeAs(_, i): sizeOfReturn = 'arg_${i}_size';
        case _:
      }
      if (method.cPrereturn != null)
        lb.ai('${method.cPrereturn}\n');
      var call = '${method.native}(' + [ for (i in 0...method.args.length) switch (method.args[i]) {
        case SizeOfReturn: '&arg_$i';
        case _: 'arg_$i';
      } ].join(", ") + ')';
      if (method.ret == Void)
        lb.ai("");
      else
        lb.ai('${mapTypeC(method.ret, 'ret')} = ');
      if (method.cReturn != null)
        lb.a('${method.cReturn.replace("%CALL%", call)};\n');
      else
        lb.a('$call;\n');
      if (method.ret == Void)
        lb.ai("return 0;\n");
      else {
        lb.ai(box(method.ret, "ret", sizeOfReturn));
        lb.a(";\n");
        lb.ai("return 1;\n");
      }
    });
    lb.ai("}\n");
  }

  static function generateVariables(ctx:AmmerContext):Array<String> {
    return [ for (t in ([
      {ffi: Int, lua: "integer", name: "int"},
      {ffi: String, lua: "string", name: "string"},
      {ffi: Bool, lua: "boolean", name: "bool"},
      {ffi: Float, lua: "number", name: "float"}
    ]:Array<{ffi:FFIType, lua:String, name:String}>)) {
      if (!ctx.varCounter.exists(t.ffi))
        continue;
      var method = 'g_${t.name}_${ctx.index}';
      lb.ai('static int $method(lua_State *L) {\n');
      lb.indent(() -> {
        lb.ai("lua_newtable(L);\n");
        for (variable in ctx.ffiVariables) {
          if (variable.type == t.ffi) {
            lb.ai('lua_pushinteger(L, ${variable.index});\n');
            lb.ai('lua_push${t.lua}(L, ${variable.native});\n');
            lb.ai("lua_settable(L, -3);\n");
          }
        }
        lb.ai('return 1;\n');
      });
      lb.ai("}\n");
      method;
    } ];
  }

  static function generateInit(ctx:AmmerContext, varMethods:Array<String>):Void {
    lb.ai("#ifdef __cplusplus\n");
    lb.ai("extern \"C\" {\n");
    lb.ai("#endif\n");
    lb.ai('int g_init_${ctx.index}(lua_State *L) {\n');
    lb.indent(() -> {
      lb.ai("luaL_Reg wrap[] = {\n");
      lb.indent(() -> {
        for (method in ctx.ffiMethods) {
          lb.ai('{"${mapMethodName(method.name)}", ${mapMethodName(method.name)}},\n');
        }
        for (method in varMethods) {
          lb.ai('{"$method", $method},\n');
        }
        lb.ai("{NULL, NULL}\n");
      });
      lb.ai("};\n");
      lb.ai("lua_newtable(L);\n");
      lb.ai("luaL_setfuncs(L, wrap, 0);\n");
      lb.ai("return 1;\n");
    });
    lb.ai("}\n");
    lb.ai("#ifdef __cplusplus\n");
    lb.ai("}\n");
    lb.ai("#endif\n");
  }

  public static function generate(config:Config, library:AmmerLibraryConfig):Void {
    StubLua.library = library;
    lb = new LineBuf();
    generateHeader();
    var generated:Map<String, Bool> = [];
    for (ctx in library.contexts) {
      for (method in ctx.ffiMethods) {
        if (generated.exists(method.name))
          continue; // TODO: make sure the field has the same signature
        generated[method.name] = true;
        generateMethod(method);
      }
      var varMethods = generateVariables(ctx);
      generateInit(ctx, varMethods);
    }
    Utils.update('${config.lua.build}/ammer_${library.name}.lua.${library.abi == Cpp ? "cpp" : "c"}', lb.dump());
  }
}
