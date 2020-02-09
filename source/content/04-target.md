<!--menu:Target details-->
<!--label:target-->
# Target details

### Feature matrix

All features listed should eventually be available on all supported platforms.

| Feature | [C++](target-hxcpp) | [Eval](target-eval) | [HashLink](target-hashlink) | [Lua](target-lua) |
| --- |:---:|:---:|:---:|:---:|
| [Functions](definition-library-functions) | **yes** | **yes** | **yes** | **yes** |
| [C code injection](definition-metadata#ammer.c.prereturn) | no | no | **yes** | no |
| [Constants](definition-library-constants) | **yes** | no | **yes** | no |
| [Library datatypes](definition-type) | **yes** | no | **yes** | no |
| Callbacks | no | no | **yes** | no |

<!--label:target-hxcpp-->
## C++

hxcpp includes a native compilation stage, so external libraries can be dynamically linked directly, without relying on FFI methods.

If the Haxe class has the same name as the main header file of the library, a problem might occur - hxcpp also generates header files that carry the name of the class they represent. To circumvent this problem, create a copy with a different filename, then use [`ammer.lib.<name>.headers`](configuration-library#ammer.lib.headers):

```bash
$ cp foobar.h tmp.foobar.h
```

```hxml
-D ammer.lib.foobar.headers=tmp.foobar.h
```

<!-- TODO: rename hxcpp to C++ everywhere? -->

<!--label:target-eval-->
## Eval

Native extensions for eval are supported via the [plugin](https://api.haxe.org/v/development/eval/vm/Context.html#loadPlugin) system in Haxe. Dynamic libraries can be linked to an OCaml dynamic library (`.cmxs` or `.cmo`), which can be loaded at runtime by Haxe. However, the plugin must be compiled with the exact same OCaml version and configuration as Haxe itself. Therefore Eval is only supported with Haxe set up to [compile from its sources](https://github.com/HaxeFoundation/haxe/blob/development/extra/BUILDING.md). The `ammer.eval.haxeDir` define must be set to point to the `haxe` repository directory. `ammer.eval.bytecode` may be defined to indicate that Haxe is built using the bytecode compiler, which means the native library must also be compiled in this mode.

During compilation with `ammer`, the `.cmxs` (or `.cmo`) file for a native library needs to be (re-)compiled whenever the native library or the Haxe library definition changes.

This process is facilitated by creating a `Makefile` and FFI-defining C files in the directory defined by `ammer.eval.build`. The compiled `cmxs` files are then placed into the directory defined by `ammer.eval.output`. Both directories default to the current working directory when not specified.

<!--label:target-hashlink-->
## HashLink

HashLink can use native libraries when given `.hdll` files containing the stubs, which take HashLink types and pass them onto the dynamically-loaded library. The `.hdll` files specify dynamic linkage and provide HashLink FFI, as understood by the HashLink interpreter/VM `hl`.

During compilation with `ammer`, the `.hdll` file for a native library needs to be (re-)compiled whenever the native library or the Haxe library definition changes.

This process is facilitated by creating a `Makefile` and FFI-defining C files in the directory defined by `ammer.hl.build`. The compiled `hdll` files are then placed into the directory defined by `ammer.hl.output`. Both directories are the same as the `.hl` output by default.

```hxml
-D ammer.hl.build=where/to/place/the/stubs
-D ammer.hl.output=where/to/place/the/hdll/files
--hl where/to/place/the/output.hl
```

When running, the `.hdll` file must be present either in the current working directory, or in the library directory (e.g. `/usr/local/lib`). For distributing programs to end users, the former is preferred (since the `.hdll` files need not be installed).

<!--sublabel:ammer.hl.hlInclude-->
### `ammer.hl.hlInclude`, `ammer.hl.hlLibrary`

**Optional**

Compilation of HashLink `.hdll` files relies on the `hl.h` header and the `libhl` library (the `libhl.dylib` or `libhl.lib` file in particular). These defines should be used if the HashLink headers are not present in the default include path.

When using HashLink built from source, `ammer.hl.hlInclude` should point to the `src` directory of the HashLink repository clone, and `ammer.hl.hlLibrary` to the directory containing the binaries produced during HashLink compilation.

When using a binary release of HashLink, both paths should point to the `include` directory distributed along with the executable.

<!--label:target-lua-->
## Lua

<!-- TODO: Lua -->
