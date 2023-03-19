<!--menu:Introduction-->
<!--label:index-->
# Introduction

<!--include:diagram-ammer-->

`ammer` is a [Haxe](https://haxe.org/) library which brings native libraries (`.dll`, `.dylib`, `.so`) to a variety of Haxe targets without requiring the user to manually write similar but slightly different `extern` definitions and target-specific stub/glue code.

It is intended to be a tool for Haxe library creators. The goal is for end-users to be able to install a native library and its corresponding `ammer` library, then be able to use the native library in Haxe code on any `ammer`-supported platform.

<!--label:intro-overview-->
## Overview

This document aims to be the definitive, exhaustive documentation for the `ammer` project and its associated repositories ([`ammer-core`](https://github.com/Aurel300/ammer-core), [`HaxeAmmer/amlib-*`](https://github.com/haxeammer)). Knowledge of the Haxe language is assumed (see the [Haxe manual](https://haxe.org/manual/)), as well as some knowledge of the C language.

The sections are organised as follows:

- [Introduction](index) — General overview.
  - [Overview](intro-overview)
  - [Terminology](intro-terminology)
  - [Why `ammer`?](intro-use)
  - [Installation](intro-installation)
  - [Getting started](intro-start)
- [Definition](definition) — Guide-level explanation of writing library definitions using `ammer`.
  - [Library definition](definition-library)
  - [Datatypes](definition-type)
- [Configuration](configuration) — Guide-level explanation of library configuration.
  - [Providing flags](configuration-providing)
  - [Project-wide configuration](configuration-project)
  - [Library configuration](configuration-library)
- [Target details](target) — Target-specific information.
  - [Feature parity](target-feature-parity)
  - [C++](target-hxcpp)
  - [C#](target-cs)
  - [Eval](target-eval)
  - [HashLink](target-hashlink) (both JIT and HL/C)
  - [Java](target-java) (both Java and JVM)
  - [Lua](target-lua)
  - [Neko](target-neko)
  - [Node.js](target-nodejs)
  - [Python](target-python)
- [Reference](ref) — Full reference of the available APIs, metadata, and `ammer` types.
  - [FFI types](ref-ffi)
  - [`ammer.def.*` types](ref-def)
  - [`ammer.Lib`](ref-lib)
  - [List of configuration flags](ref-flags)
  - [List of annotations](ref-annot)
- [`amlib`](amlib) — Writing and publishing `ammer` libraries.
  - Conventions
  - CI
  - Baking
- [Advanced topics](advanced) — More advanced considerations when writing library definitions.
  - [Type cycles](advanced-cycles)
  - Garbage collection
  - String encoding
  - Static and dynamic linking
  - Packaging and distribution
  - Creating new platforms
  - Performance
- [`ammer-core`](core) — About the underlying framework.

<!--label:intro-terminology-->
## Terminology

In the context of Haxe and its use with `ammer`, terms such as "native" or "library" can be ambiguous. Throughout this document, the terms will have the following meaning:

- **native library** — Native libraries is typically distributed as `.dll` (on Windows), `.dylib` (on macOS), or `.so` (on Linux). Usually such libraries are written in a system language such as C, and compiled into machine code "native" to a particular architecture or operating system.
  - Examples: [libPNG](http://www.libpng.org/pub/png/libpng.html), [SDL 2](https://libsdl.org/), [libuv](https://libuv.org/).
- **Haxe library** — Haxe libraries are packages containing Haxe code, distributed via [haxelib](https://lib.haxe.org/), Github, or other means.
  - Examples: [HaxeUI](http://haxeui.org/), [OpenFL](https://www.openfl.org/), [pecan](https://github.com/Aurel300/pecan).
- **`ammer` library** — A subset of the previous, `ammer` libraries are Haxe libraries made using `ammer`.
- **library** — One the above. Should only be used when the context makes it clear which one is meant!
- **`ammer` library definition** — To create an `ammer` library, a "definition" is needed, consisting of specially annotated Haxe classes and methods, as described in the [Definition section](definition).
- **extern** — Haxe allows marking classes and other types as externs (see the [Externs section](https://haxe.org/manual/lf-externs.html) in the Haxe manual), which allows non-Haxe code (such as functions written in Javascript) to be used safely from within Haxe code.
- **target** — The Haxe compiler compiles Haxe code into one of its various targets, such as C#, Javascript, or HashLink. However, this is not precise enough: it is also important to know how the resulting code is compiled and how it will be executed. In this document, "target" refers to such a more precise combination of target language + runtime platform.
  - Examples: Javascript on Node.js, HashLink in HL/C mode.
- **FFI** — Foreign Function Interface. On targets with an interpreter (such as Node.js/V8) or a virtual machine (such as the JVM) this generally refers to a mechanism that allows code to interact with native libraries.

With the above in mind, `ammer` is a Haxe library which is used to create `ammer` libraries. Typically, their function is to make a native library usable from Haxe. The author of an `ammer` library creates a library definition corresponding to the API of a native library. Although `ammer` uses externs under the hood (on some targets), this is not directly visible; in other words, `ammer` library definitions aim to be a more general concept than externs.

<!--menu:Why <code>ammer</code>?-->
<!--titleplain:Why ammer?-->
<!--label:intro-use-->
## Why `ammer`?

<!--include:diagram-ammer-->

Unlike Haxe externs and manually written glue code, `ammer` definitions provide a unified interface: the same definition can be used for C++, for HashLink, for Node.js, etc. Additionally, writing externs and glue code is extremely error-prone and tedious, and requires detailed knowledge of the FFI mechanism used by each platform. `ammer` aims to hide this technical complexity, allowing library authors to focus purely on the API of the library they are defining. Any necessary externs and glue code is generated automatically. Any issues that are identified in this process can be fixed once, to the benefit of all `ammer` libraries.

`ammer` can be seen as an extension of the "Haxe promise": write code once and run it anywhere. With `ammer` this is true also for code that interacts with native libraries, which is crucial for real-world codebases.

<!--label:intro-installation-->
## Installation

`ammer` can be installed as a `git` library:

```bash
# using SSH
$ haxelib git ammer git@github.com:Aurel300/ammer.git
# or using HTTPS
$ haxelib git ammer https://github.com/Aurel300/ammer.git
```

Alternatively, the Github repository can be cloned manually and `ammer` can be installed as a `dev` library:

```bash
$ git clone git@github.com:Aurel300/ammer.git
$ cd ammer
$ haxelib dev ammer .
```

`ammer` requires a C compiler toolchain to be installed. Any GCC-compatible compiler should work, as well as MSVC. Each target may have additional dependencies — see [target details](target).

<!--label:intro-start-->
## Getting started

To use an existing native library, all that is required is to write a [library definition](definition-library):

```haxe
class Foobar extends ammer.def.Library<"foobar"> {
  public static function repeat(word:String, count:Int):String;
}
```

The types used in the arguments must be among the supported [FFI types](ref-ffi). Libraries can define [functions](definition-library-functions), [variables](definition-library-variables), and [datatypes](definition-type). The functions can then be called like regular Haxe functions:

```haxe
class Main {
  public static function main():Void {
    trace(Foobar.repeat("hello", 3));
  }
}
```

During compilation, the `ammer` haxelib must be used. Library-specific configuration can be added either using metadata or define flags. The define flags must include at least a build path (used for intermediate files) and an output path (where the `ammer`-generated dynamic libraries will be placed):

```hxml
--library ammer
-D ammer.buildPath=build
-D ammer.outputPath=bin
--main Main
--hl bin/out.hl
```

A variety of configuration flags can be provided; see [configuration](configuration) for more details.
