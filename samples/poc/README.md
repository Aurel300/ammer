# Sample `ammer` project

This is a sample project for the `ammer` library, based on the requirements of [the bounty by Lars Doucet](https://github.com/larsiusprime/larsBounties/issues/2). It contains the sources to a simple library called `adder`, its `ammer` library definition, and a trivial Haxe program using the library.

---

 - [Directory structure](#directory-structure)
 - [Building the native library](#building-the-native-library)
   - [On Windows](#on-windows)
   - [On OS X](#on-os-x)
 - [Building the Haxe project](#building-the-haxe-project)
 - [Running](#running)
   - [On Windows](#on-windows-1)
   - [On OS X](#on-os-x-1)

## Directory structure

 - [`Adder.hx`](Adder.hx) - `ammer` library definition for the `adder` library. This class essentially maps Haxe types to the C library.
 - [`Main.hx`](Main.hx) - main program using the library in regular Haxe code.
 - [`build-common.hxml`](build-common.hxml) - build configuration common to all targets.
 - [`build-cpp.hxml`](build-cpp.hxml) - build configuration for hxcpp.
 - [`build-eval.hxml`](build-eval.hxml) - build configuration for Eval.
 - [`build-hl.hxml`](build-hl.hxml) - build configuration for HashLink.
 - [`dummy.txt`](dummy.txt) - file containing some UTF-8 text, loaded by `Main` to demonstrate one function of the `adder` library.
 - [`native`](native) - contains sources to the `adder` library.
   - [`adder.c`](native/adder.c)
   - [`adder.h`](native/adder.h)
   - [`Makefile.osx`](native/Makefile.osx) - build script for building the library on OS X.
   - [`Makefile.win`](native/Makefile.win) - build script for building the library on Windows (using MSVC).

## Building the native library

The native library in this project needs to be compiled to a binary format before it can be used. In practice, `ammer` only needs the compiled binary of a library (`.dll`, `.dylib`, `.so`) and its header files (`.h` files) to be able to use it. Many popular libraries provide pre-compiled releases. Here we will compile `adder` for completion's sake.

### On Windows

Assuming [MSVC](https://visualstudio.microsoft.com/downloads/) is set up on the local machine, navigate to the `native` directory in a Visual Studio Developer Command Prompt, then use the provided `Makefile.win`:

```bash
$ cd <path to poc directory>/native
$ nmake /F Makefile.win
```

This should create (among others) the files `adder.dll` and `adder.lib` in the `native` directory.

### On OS X

Assuming any reasonably modern C compiler (`gcc` or `clang`) is set up on the local machine, navigate to the `native` directory in a terminal, then use the provided `Makefile.osx`:

```bash
$ cd <path to poc directory>/native
$ make -f Makefile.osx
```

This should create (among others) the file `libadder.dylib` in the `native` directory.

## Building the Haxe project

Once the native library is built, the Haxe project itself can be compiled. The necessary configuration is already provided in the HXML files. Some targets require additional configuration, which needs to be provided on the command line via a define:

```bash
$ haxe -D ammer.hl.hlDir=<path to the hl include directory> build-hl.hxml
$ haxe build-hxcpp.hxml
$ haxe -D ammer.eval.haxeDir=<path to haxe clone> build-eval.hxml
```

## Running

`ammer` works with dynamic libraries (except on hxcpp on Windows), which must either be distributed alongside with the program or already be present on the system. Since the sample `adder` library is specific to this project, it needs to be placed next to the binary.

One of the test functions in the Haxe project tries to load the file `dummy.txt`. It should be copied into each directory in `bin`.

### On Windows

```bash
$ cp native/adder.dll bin/hl
$ cd bin/hl
$ hl sample.hl
```

```bash
$ cd bin/cpp
$ ./Main
```

### On OS X

When running the project, the current working directory will not be searched for dynamic libraries by default, so the `DYLD_LIBRARY_PATH` variable must be used.

```bash
$ cd bin/hl
$ DYLD_LIBRARY_PATH=../../native hl sample.hl
```

```bash
cd bin/cpp
$ DYLD_LIBRARY_PATH=../../native ./Main
````
