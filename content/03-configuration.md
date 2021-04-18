<!--menu:Configuration-->
<!--label:configuration-->
# Configuration

Various defines can be specified at compile-time to configure `ammer` behaviour. Some of the defines below are specific to a particular target; they are ignored when compiling for a different target. Follow the links below to see longer descriptions of each define.

| Category | Define | Type | Required | Description |
| --- | --- | --- | --- | -- |
| [**General**](configuration-general) | [`ammer.makefiles`](configuration-general#ammer.makefiles) | boolean | no | Enable/disable Makefile generation |
| | [`ammer.msvc`](configuration-general#ammer.msvc) | boolean | no | Enable/disable MSVC compilation |
| | [`ammer.msvcPath`](configuration-general#ammer.msvcPath) | string | no | Path to MSVC binaries |
| [**Library**](configuration-library) | [`ammer.lib.<name>.include`](configuration-library#ammer.lib.include) | string | **yes** | Include path |
| | [`ammer.lib.<name>.library`](configuration-library#ammer.lib.library) | string | **yes** | Library path |
| | [`ammer.lib.<name>.headers`](configuration-library#ammer.lib.headers) | string (comma-separated list) | no | Headers to include |
| | [`ammer.lib.<name>.abi`](configuration-library#ammer.lib.abi) | string | no | C or C++ ABI |
| | [`ammer.lib.<name>.linkName`](configuration-library#ammer.lib.linkName) | string | no | Library name during linking |
| [**Eval-specific**](target-eval) | [`ammer.eval.build`](target-eval#ammer.eval.build) | string | no | Eval build path |
| | [`ammer.eval.output`](target-eval#ammer.eval.output) | string | no | Eval output path |
| | [`ammer.eval.haxeDir`](target-eval#ammer.eval.haxeDir) | string | no | |
| | [`ammer.eval.bytecode`](target-eval#ammer.eval.bytecode) | boolean | no | |
| [**HashLink-specific**](target-hashlink) | [`ammer.hl.build`](target-hashlink#ammer.hl.build) | string | no | HashLink build path |
| | [`ammer.hl.output`](target-hashlink#ammer.hl.output) | string | no | HashLink output path |
| | [`ammer.hl.hlInclude`](target-hashlink#ammer.hl.hlInclude) | string | no | HashLink include path |
| | [`ammer.hl.hlLibrary`](target-hashlink#ammer.hl.hlInclude) | string | no | HashLink library path |
| [**Lua-specific**](target-lua) | [`ammer.lua.build`](target-lua#ammer.lua.build) | string | no | Lua build path |
| | [`ammer.lua.output`](target-lua#ammer.lua.output) | string | no | Lua output path |
| | [`ammer.lua.hlInclude`](target-lua#ammer.lua.hlInclude) | string | no | Lua include path |
| | [`ammer.lua.hlLibrary`](target-lua#ammer.lua.hlInclude) | string | no | Lua library path |

A boolean define is assumed to be `true` when set without a value as `-D someDefine`. Setting a boolean define to `false` can be achieved with `-D someDefine=off`, or `-D someDefine=false`.

<!--label:configuration-general-->
## General configuration

<!--sublabel:ammer.makefiles-->
### `ammer.makefiles`

**Optional, default value: `yes`**

When defined and the value is not `no`, `Makefile`s will be generated. Otherwise, `ammer` will try to emulate the behaviour of `make` and invoke compilers directly when changes are detected.

<!--sublabel:ammer.msvc-->
### `ammer.msvc`

**Optional, default value: `yes` on Windows, `no` on other platforms**

When defined and the value is not `no`, `Makefile`s will be generated for use with MSVC compiler tools.

```hxml
# don't use MSVC even on Windows
-D ammer.msvc=no
```

<!--sublabel:ammer.msvcPath-->
### `ammer.msvcPath`

**Optional, default value: `""`**

By default, `nmake` and `cl` are assumed to be in the environment's `PATH` and are invoked directly. When `ammer.msvcPath` is defined and MSVC is used, calls to `nmake` and `cl` will be prefixed with the defined path instead. 

<!--label:configuration-library-->
## Library configuration

External libraries are declared by defining a Haxe class which extends `ammer.Library<...>`, with the type parameter being the identifier used for the library in the rest of the configuration.

```haxe
class Foobar extends ammer.Library<"foobar"> { ... }
```

The identifier should only consist of letters and should be unique. Additional configuration of the library is done with compile-time defines, ideally placed in the project's `hxml` build file. In the following paragraph, `<name>` should be replaced by the library identifier.

<!--sublabel:ammer.lib.include-->
### `ammer.lib.<name>.include`

**Required**

The path to the `include` directory of the library, which contains the header files (`.h`). This path may be relative to the current working directory that `haxe` was invoked in.

<!--sublabel:ammer.lib.library-->
### `ammer.lib.<name>.library`

**Required**

The path to the `lib` directory of the library, which contains the dynamic library files (`.dll`, `.dylib`, `.so`). This path may be relative to the current working directory that `haxe` was invoked in.

<!--sublabel:ammer.lib.headers-->
### `ammer.lib.<name>.headers`

**Optional, default value: `<name>.h`**

Comma-separated list of headers that need to be included from the library.

```hxml
-D ammer.lib.foobar.headers=foobar.h,foobar-support.h
```

<!--sublabel:ammer.lib.abi-->
### `ammer.lib.<name>.abi`

**Optional, default value: `c`**

Specify the ABI (Application Binary Interface) for the library. Supported values are:

 - `c` - regular linkage, C libraries
 - `cpp` - C++ linkage

<!--sublabel:ammer.lib.linkName-->
### `ammer.lib.<name>.linkName`

**Optional, default value: `<name>`**

The name to use when linking the library. This is the name appended to `-l` for GCC-based compilers.

```hxml
-D ammer.lib.zlib.linkName=z
# library "zlib" will be linked with "-lz"
```
