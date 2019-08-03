# `ammer`

Unified FFI for native extensions for [Haxe](https://haxe.org/).

 - [Usage](#usage)
 - [Types](#types)
   - [`String`](#string)
   - [`Bytes`](#bytes)
 - [Configuration](#configuration)
   - [Library configuration](#library-configuration)
 - [Target specifics](#target-specifics)
   - [HashLink](#hashlink)
   - [hxcpp](#hxcpp)
 - [General notes about dynamic libraries](#general-notes-about-dynamic-libraries)
 - [Implementation details](#implementation-details)

---

`ammer` allows Haxe code to use external native libraries (`.dll`, `.dylib`, `.so`) from a variety of targets without having to manually write similar but slightly different `extern` definitions and target-specific stub/glue code.

The platforms that are currently supported are:

 - [HashLink](#hashlink)
 - [C++](#hxcpp)

## Usage

To use an existing native library, all that is required is a `class` definition:

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function repeat(word:String, count:Int):String;
}
```

The types used in the arguments are regular Haxe types, but keep in mind custom classes are not supported. See [types](#types) below.

The functions can be called like any other static function:

```haxe
class Main {
  public static function main():Void {
    trace(Foobar.repeat("hello", 3));
  }
}
```

During compilation, the `ammer` haxelib must be added:

```hxml
--library ammer
-D ammer.lib.foobar.include=include
-D ammer.lib.foobar.library=lib
--main Main
--hl out.hl
```

A variety of configuration flags can be defined, see [configuration](#configuration) below.

## Types

Haxe employs a rich type system, but many of its features cannot be translated meaningfully into library externs, hence only a subset of basic Haxe types are supported in `ammer` library externs:

| Haxe type | C type | Note |
| --------- | ------ | ---- |
| `Int` | `int` | 32-bit wide signed integer. |
| `UInt` | `unsigned int` | 32-bit wide unsigned integer. |
| `String` | `char *` | See [`String`](#string). |
| `haxe.io.Bytes` | `unsigned char *data` + `int length` | See [`Bytes`](#bytes). |

### `String`

Since Haxe 4, `String`s represent a string of Unicode codepoints. Internally, different targets represent strings differently, but in `ammer` library definitions, strings are always understood as valid UTF-8 sequences.

Although the null byte is a valid Unicode codepoint, some Haxe targets use it to terminate strings, and C APIs in general use it as a end-of-string marker. This is why a single `char *` argument is sufficient to pass a string to native libraries; the null byte is used to detect the end of the string. To pass UTF-8 data which includes null bytes, `haxe.io.Bytes` has to be used instead.

### `Bytes`

`haxe.io.Bytes` values represent arbitrary binary data. In terms of C types, this can be thought of as a pointer (`unsigned char *`) and a corresponding length (`int`). Whenever a native library expects arbitrary binary data, it needs to know both of these values, passed as separate arguments. On the Haxe side, however, a single argument is sufficient. To facilitate this difference, the length argument given to the C API is marked with the type `ammer.ffi.SizeOf` with the name of the corresponding argument as a type parameter. In Haxe code, the marked argument is not present, as it is always based on the length of the `Bytes` instance.

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function validate(buf:haxe.io.Bytes, len:ammer.ffi.SizeOf<"buf">):Bool;
}

class Main {
  public static function main():Void {
    // note the `len` argument is not given:
    trace(Foobar.validate(haxe.io.Bytes.ofHex("CAFFE00CAFFE")));
  }
}
```

When a C API returns a binary buffer, one of the arguments is typically a pointer to which the size of the buffer will be written. This can be expressed with the type `ammer.ffi.SizeOfReturn`. Once again, in Haxe code, this argument will not be present.

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function makeData(len:ammer.ffi.SizeOfReturn):haxe.io.Bytes;
}

class Main {
  public static function main():Void {
    // note the `len` argument is not given:
    trace(Foobar.makeData());
  }
}
```

Finally, if a C API returns a binary buffer that is the same size as one of the arguments, the return type can be wrapped with `ammer.ffi.SameSizeAs`:

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function reverseBuffer(buf:haxe.io.Bytes, len:ammer.ffi.SizeOf<"buf">):ammer.ffi.SameSizeAs<haxe.io.Bytes, "buf">;
}
```

## Configuration

Various defines can be specified at compile-time to configure `ammer` behaviour.

 - [library configuration](#library-configuration)
   - `ammer.lib.<name>.headers`
   - `ammer.lib.<name>.include` 
   - `ammer.lib.<name>.library`
 - [HashLink configuration](#hashlink)

### Library configuration

External libraries are declared by defining a Haxe class which extends `ammer.Library<...>`, with the type parameter being the identifier used for the library in the rest of the configuration.

```haxe
class Foobar extends ammer.Library<"foobar"> { ... }
```

The identifier should only consist of letters and should be unique. Additional configuration of the library is done with compile-time defines, ideally placed in the project's `hxml` build file. In the following paragraph, `<name>` should be replaced by the library identifier.

#### `ammer.lib.<name>.include` (required)

The path to the `include` directory of the library, which contains the header files (`.h`). This path may be relative to the current working directory that `haxe` was invoked in.

#### `ammer.lib.<name>.library` (required)

The path to the `lib` directory of the library, which contains the dynamic library files (`.dll`, `.dylib`, `.so`). This path may be relative to the current working directory that `haxe` was invoked in.

#### `ammer.lib.<name>.headers` (optional)

Comma-separated list of headers that need to be included from the library.

```hxml
-D ammer.lib.foobar.headers=foobar.h,foobar-support.h
```

## Target specifics

### HashLink

HashLink can use native libraries when given `.hdll` files containing the stubs, which take HashLink types and pass them onto the dynamically-loaded library. The `.hdll` files specify dynamic linkage and provide HashLink FFI, as understood by the HashLink interpreter/VM `hl`.

During compilation with `ammer`, the `.hdll` file for a native library needs to be (re-)compiled whenever the native library or the Haxe library definition changes.

This process is facilitated by creating a `Makefile` and FFI-defining C files in the directory defined by `ammer.hl.build`. The compiled `hdll` files are then placed into the directory defined by `ammer.hl.output`. Both directories are the same as the `.hl` output by default.

```hxml
-D ammer.hl.build=where/to/place/the/stubs
-D ammer.hl.output=where/to/place/the/hdll/files
--hl where/to/place/the/output.hl
```

When running, the `.hdll` file must be present either in the current working directory, or in the library directory (e.g. `/usr/local/lib`). For distributing programs to end users, the former is preferred (since the `.hdll` files need not be installed).

### hxcpp

hxcpp includes a native compilation stage, so external libraries can be dynamically linked directly, without relying on FFI methods.

## General notes about dynamic libraries

If you are creating a native library from scratch, ensure that it is compiled as a dynamic library.

> See http://www.microhowto.info/howto/build_a_shared_library_using_gcc.html, https://stackoverflow.com/questions/14173260/creating-shared-libraries-in-c-for-osx, or search for "dynamic library c".

The important things to remember are: compile object files with `-fPIC` (position-independent code), and compile the library with `-dynamiclib`.

To actually use a dynamic library at run-time, it must be present in a place in which the OS will know to look. This differs from platform to platform:

 - OS X - the dynamic linker will look in `/usr/lib`, `/usr/local/lib`, paths specified in the environment variables `DYLD_LIBRARY_PATH`, `DYLD_FALLBACK_LIBRARY_PATH`, `DYLD_VERSIONED_LIBRARY_PATH`, the special `@executable_path`, and more (see  https://www.mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html)

## Implementation details

External libraries are build in up to four separate stages:

 - FFI type processing - common to all targets, runs once per library. In this stage, the special [FFI types](#types) are checked. See [`ammer.Ammer.createFFIMethod`](src/ammer/Ammer.hx).
 - Stub creation - target-specifc, runs once per library. In this stage, files containing the FFI stubs are created for the library if they are needed. See [`ammer.stub`](src/ammer/stub).
 - Type patching - target-specific, runs once per library. In this stage, an `extern class` containing the native or FFI-linked methods is defined, and the methods of the original class are rewritten to map Haxe types to the target-specific ones and vice versa. See [`ammer.patch`](src/ammer/patch).
 - Build - target-specific, runs once per project. In this stage, the stubs for all the libraries are compiled if needed. See [`ammer.build`](src/ammer/build).
