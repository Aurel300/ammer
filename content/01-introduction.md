<!--menu:Introduction-->
<!--label:index-->
# Introduction

`ammer` is a [Haxe](https://haxe.org/) 4 library which brings native libraries (`.dll`, `.dylib`, `.so`) to a variety of Haxe targets without requiring the user to manually write similar but slightly different `extern` definitions and target-specific stub/glue code.

It is intended to be a tool for Haxe library creators. The goal is for end-users to be able to install a C library and its corresponding `ammer` library, then be able to use the C library in Haxe code on any `ammer`-supported platform.

### Supported platforms

 - [C++](target-hxcpp)
 - [HashLink](target-hashlink)
 - [Lua](target-lua)

See also the [detailed feature matrix](target).

### Planned platforms

 - [Eval](target-eval) - temporarily broken, see [related issue](issue:20)
 - Javascript/Node.js - using [N-API](https://nodejs.org/api/n-api.html)

<!--label:intro-start-->
## Getting started

To use an existing native library, all that is required is a [library definition](definition-library):

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function repeat(word:String, count:Int):String;
}
```

The types used in the arguments must be among the supported [FFI types](definition-ffi). Libraries can define [functions](definition-library-functions), [constants](definition-library-constants), and [library datatypes](definition-type).

The functions can then be called like regular static functions:

```haxe
class Main {
  public static function main():Void {
    trace(Foobar.repeat("hello", 3));
  }
}
```

During compilation, the `ammer` haxelib must be added in addition to library-specific configuration:

```hxml
--library ammer
-D ammer.lib.foobar.include=include
-D ammer.lib.foobar.library=lib
--main Main
--hl out.hl
```

A variety of configuration flags can be defined, see the [configuration](configuration) section.

<!--label:intro-installation-->
## Installation

`ammer` can be installed as a `git` library:

```bash
$ haxelib git ammer git@github.com:Aurel300/ammer.git
# or
$ haxelib git ammer https://github.com/Aurel300/ammer.git
```

Alternatively, the Github repository can be cloned and `ammer` can be installed as a `dev` library:

```bash
$ git clone git@github.com:Aurel300/ammer.git
$ cd ammer
$ haxelib dev ammer .
```

`ammer` requires that a C compiler toolkit is installed. Any GCC-compatible compiler should work, as well as MSVC. `make` or `nmake` (when using MSVC) is used to invoke the compiler. Each target may have additional dependencies – see [target details](target).

<!--label:intro-sample-->
## Sample project

A sample project is provided with step-by-step build instructions in the [`samples/poc`](repo:samples/poc/) directory of the main repository.

<!-- TODO: more about the sample project, copy docs over -->

<!--label:intro-use-->
## Use cases

<!-- TODO: expand -->

 - expanding the Haxe ecosystem with high quality libraries
   - adding scripting support to Haxe projects with embeddable languages like Lua
   - adding native UI to Haxe projects
 - writing performance-intensive code in C, then using it in Haxe
   - compiling against platforms like CUDA with C code

<!--label:intro-troubleshooting-->
## Troubleshooting

Please try to build the [sample project](repo:samples/poc/) first. The sample README includes a [troubleshooting section](repo:samples/poc/#troubleshooting) which describes the solutions to some common problems. If the problem still persists, please [open an issue](https://github.com/Aurel300/ammer/issues/new).
