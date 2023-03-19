<!--menu:Configuration-->
<!--label:configuration-->
# Configuration

In addition to [library definitions](definition) consisting of annotated Haxe classes, an `ammer` library must be configured such that it can be compiled properly. This section provides a guide-level explanation of the different aspects of `ammer` configuration, with examples. Further detail can be found in later sections.

### Providing flags

Most configuration flags can be set using metadata or using compile-time defines.

**Read on: [Providing flags](configuration-providing)**

### Project-wide configuration

`ammer` requires a few flags to be set for the project as a whole before compilation can proceed.

**Read on: [Project-wide configuration](configuration-project)**

### Library configuration

Libraries can be configured to include particular header files, to use certain paths as the include/library paths for the C compiler, to define C preprocessor values, and so forth.

**Read on: [Library configuration](configuration-library)**

<!--label:configuration-providing-->
## Providing flags

A "configuration flag" in this document refers to a string key, such as `ammer.buildPath` associated to a value of a given type, such as `String`. Most configuration flags can be set using two ways:

- Either by annotating a [library definition](definition-library) with metadata; or
- by providing a [compile-time define](https://haxe.org/manual/lf-condition-compilation.html) when invoking the Haxe compiler.

For configuration [flags associated to a particular library](configuration-library) (for example: "which header files should be included when compiling this library"), using metadata is the more natural option. The relevant metadata are written in the same file as the definition of the library itself, which means information is not spread across too many places. Nevertheless, defines can be used to override the library behaviour on a per-project basis.

[Configuration flags which are not associated to any library](configuration-project) can only be provided using defines.

<div class="example">

### Example: providing flags

```haxe
@:ammer.lib.headers.include("png.h")
class LibPng extends ammer.def.Library<"png"> {
  // ...
}
```

In this example, the `LibPng` library is configured to include the `png.h` header file during compilation using metadata. Alternatively, the metadata can be omitted, and the flag provided using a compile-time define:

```hxml
-D ammer.lib.png.headers.include=png.h
```

Note the naming convention: in the metadata case, the metadata is attached directly to the `LibPng` class, so providing the `png` identifier as part of the metadata name would be redundant. On the other hand, the compile-time define must specify which library it is referring to by using the `png` identifier as part of the define name.
</div>

<!--label:configuration-project-->
## Project-wide configuration

When building a project that uses an `ammer` library there are two flags which are required: the [build and output paths](configuration-project#paths). Other, optional flags, allow enabling the [debug mode](configuration-project#debug) for `ammer`, setting [target-specific options](configuration-project#target), or configuring the [build system](configuration-project#build).

<!--sublabel:paths-->
### Paths

There are two paths that need to be configured before `ammer` can continue compilation.

The build path, configured using `#lang-hxml -D ammer.buildPath`, specifies a path used as an intermediate directory. During compilation, `ammer` creates C files containing the glue code required to use a native library with the currently selected Haxe target. These files, as well as the intermediate outputs of the C compiler, are all placed into the build path. The build path is created if it does not exist.

The output path, configured using `#lang-hxml -D ammer.outputPath`, specifies the path for the resulting `ammer`-built dynamic libraries, which are files with the extensions `.dll`, `.so`, `.dylib`, `.hdll`, or `.ndll`. **These files must be distributed with the final executable for the library to function properly.**

<!--sublabel:debug-->
### Debug mode

Full debug logging for `ammer` can be enabled using `#lang-hxml -D ammer.debug=all`. During compilation, this will cause a lot of additional output that may be useful for `ammer`-debugging purposes.

<!--sublabel:target-->
### Target-specific configuration

The configuration flags specific to each target are described in the [target details](target) section. These flags are prefixed with the target they apply to. For example, `ammer.hl.` is the prefix for all HashLink-specific configuration flags.

<!--sublabel:build-->
### Build system configuration

(TODO)

<!--label:configuration-library-->
## Library configuration

Configuration flags specific to a library are typically provided by annotating the [library definition](definition-library) with metadata, although they can be overridden on a per-project basis using defines (see [providing flags](configuration-providing)).

<!--sublabel:includes-->
### Includes

The API of C libraries, consisting of function signatures and types, is typically made available by including a header file.

<div class="example">

### Example: including a header file

```haxe
@:ammer.lib.headers.include("png.h")
class LibPng extends ammer.def.Library<"png"> {
  // ...
}
```

In this example, the `LibPng` library is configured to include the `png.h` header file during compilation using metadata. This corresponds to the C code:

```c
#include "png.h"
```
</div>

There are different styles of includes, see [`@:ammer.lib.headers.includes`](ref-flags#lib.headers).

<!--sublabel:link-names-->
### Link names

The [`@:ammer.lib.linkName`](ref-flags#lib.linknames) metadata configures the name(s) of the dynamic library that `ammer` should link against such that native functions are available. This corresponds to the GCC flag `-l`.

<div class="example">

### Example: setting the link name

```haxe
@:ammer.lib.linkName("png")
class LibPng extends ammer.def.Library<"png"> {
  // ...
}
```

In this example, the `LibPng` library is configured to link against the `png` dynamic library. The C compiler will receive the argument `-lpng`.
</div>

Unless configured otherwise, an `ammer` library uses its [identifier](definition-library) as the link name. Some libraries (e.g. "header-only" libraries where the implementation is enabled with a [preprocessor define](#defines)) have no dynamic library to link against: in this case, [`@:ammer.lib.linkNames([])`](ref-flags#lib.linknames) can be used to clear the list of link names.

On macOS, "frameworks" are packages of headers and dynamic libraries. The [`@:ammer.lib.framework`](ref-flags#lib.frameworks) metadata can be used to declare that an `ammer` library uses a particular framework.

<!--sublabel:defines-->
### Defines

C preprocessor defines can be enabled for a library using the [`@:ammer.lib.define`](ref-flags#lib.defines) metadata.

<!--sublabel:paths-->
### Paths

When resolving [header includes](#includes) and when linking, the compiler needs to know where to look. `ammer` libraries can be configured with include paths and library paths. These paths correspond to the GCC flags `-I` and `-L`, respectively.

Include paths can be configured using the [`@:ammer.lib.includePath`](ref-flags#lib.includepaths) metadata, library paths can be configured using the [`@:ammer.lib.libraryPath`](ref-flags#lib.librarypaths) metadata.

Both include paths and library paths are set **relative to the file they are declared in**.

<div class="example">

### Example: setting the include path

```haxe
@:ammer.lib.includePath("../../native")
@:ammer.lib.headers.include("png.h")
class LibPng extends ammer.def.Library<"png"> {
  // ...
}
```

Assuming the directory hierarchy is as follows:

```
native/
  png.h
haxe/
  src/
    LibPng.hx
```

The compiler will look for the `png.h` header file in the directory `native`.
</div>

<!--sublabel:language-->
### Language

By default, `ammer` generates glue code in the C language. For libraries requiring the use of another language, the language can be changed using the [`@:ammer.lib.language`](ref-flags#lib.language) metadata. Currently supported languages are:

- `C` - C
- `Cpp` - C++
- `ObjC` - Objective-C
- `ObjCpp` - Objective-C++
