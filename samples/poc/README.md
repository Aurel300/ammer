# Sample `ammer` project

This is a sample project for the `ammer` library, based on the requirements of [the bounty by Lars Doucet](https://github.com/larsiusprime/larsBounties/issues/2). It contains the sources to a simple library called `adder`, its `ammer` library definition, and a trivial Haxe program using the library.

---

 - [Directory structure](#directory-structure)
 - [Building the native library](#building-the-native-library)
   - [On Windows](#on-windows)
   - [On OS X](#on-os-x)
   - [On Linux](#on-linux)
 - [Building the Haxe project](#building-the-haxe-project)
 - [Running](#running)
   - [On Windows](#on-windows-1)
   - [On OS X](#on-os-x-1)
   - [On Linux](#on-linux-1)
 - [Troubleshooting](#troubleshooting)

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
   - [`Makefile.win`](native/Makefile.win) - build script for building the library on Windows (using MSVC).
   - [`Makefile.osx`](native/Makefile.osx) - build script for building the library on OS X.
   - [`Makefile.linux`](native/Makefile.linux) - build script for building the library on Linux.

## Building the native library

Many popular libraries provide pre-compiled releases, but in this example, the native library needs to be compiled to a binary format before it can be used. In practice, `ammer` only needs the compiled binary of a library (`.dll`, `.dylib`, `.so`) and its header files (`.h` files) to be able to use it.

### On Windows

Assuming [MSVC](https://visualstudio.microsoft.com/downloads/) is set up on the local machine, navigate to the `native` directory in a Visual Studio Developer Command Prompt (or a regular command prompt initialised by running `vcvars32`), then use the provided `Makefile.win`:

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

### On Linux

Assuming any reasonably modern C compiler (`gcc` or `clang`) is set up on the local machine, navigate to the `native` directory in a terminal, then use the provided `Makefile.linux`:

```bash
$ cd <path to poc directory>/native
$ make -f Makefile.linux
```

This should create (among others) the file `libadder.so` in the `native` directory.

## Building the Haxe project

Once the native library is built, the Haxe project itself can be compiled. The necessary configuration is already provided in the HXML files. Some targets require additional configuration, which needs to be provided on the command line via a define. See the [target-specific configuration](https://github.com/Aurel300/ammer#target-specifics) section in the main README for more information about these defines.

```bash
$ haxe -D ammer.hl.hlInclude=<path to the hl include directory> -D ammer.hl.hlLibrary=<path to the hl library directory> build-hl.hxml
$ haxe build-cpp.hxml
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

### On Linux

When running the project, the current working directory will not be searched for dynamic libraries by default, so the `LD_LIBRARY_PATH` variable must be used.

```bash
$ cd bin/hl
$ LD_LIBRARY_PATH=../../native hl sample.hl
```

```bash
cd bin/cpp
$ LD_LIBRARY_PATH=../../native ./Main
````

## Troubleshooting

This section lists some problems you may come across while following the steps described above.

#### "hl.h": no such file or directory

This error can occur during the build phase when targeting HashLink. It indicates that the native compiler cannot find the `hl.h` header file. Use the [`ammer.hl.hlInclude`](https://github.com/Aurel300/ammer#ammerhlhlinclude-ammerhlhllibrary-optional) option to point the compiler to a directory containing the `hl.h` file.

 - When using HashLink binary distributions, the directory is `include` in the downloaded folder.
 - When using HashLink built from source, the directory is `src` in the repository root.

#### "stddef.h": no such file or directory

This error can occur during the build phase when using MSVC on Windows. It indicates that the native compiler cannot find header files of the C standard library. To solve this:

 - Either use the "Visual Studio Developer Command Prompt"; or
 - Use a regular command-line prompt, but use the [`vcvars32` script](https://stackoverflow.com/questions/42805662/vsvars32-bat-in-visual-studio-2017) to initialise the environment.

#### Failed to load library ammer_adder.hdll

This error can occur when testing HashLink for two reasons (possibly both at the same time):

##### 1. `ammer_adder.hdll` is not in the CWD

The `hl` command will look for `hdll` files in the current working directory as well as the system library directories. Therefore, if `ammer_adder.hdll` is in the `bin/hl` directory (which is the case if the default configuration of this project is used), invoking `hl` from the `samples/poc` directory will NOT work.

 - Either `cd bin/hl` before invoking `hl`; or
 - Copy `ammer_adder.hdll` from `bin/hl` into the current working directory.

##### 2. The dynamic library cannot be found

Refer to the next section.

#### Image not found / Library not loaded

This error can occur when the system cannot find the compiled native library (`.dll`, `.dylib`, or `.so` file).

On Windows, the system will look for `dll` files in the current working directory.

 - Copy `adder.dll` from the `native` directory into the current working directory.

On OS X and Linux, the dynamic linker needs to be told where to look for additional dynamic libraries with an environment variable.

 - On OS X, prepend `DYLD_LIBRARY_PATH=<path to samples/poc/native>` to the command, e.g. `DYLD_LIBRARY_PATH=../../native hl sample.hl`.
 - On Linux, prepend `LD_LIBRARY_PATH=<path to samples/poc/native>` to the command, e.g. `LD_LIBRARY_PATH=../../native hl sample.hl`.

See also [general notes about dynamic libraries](https://github.com/Aurel300/ammer#general-notes-about-dynamic-libraries) in the main README.
