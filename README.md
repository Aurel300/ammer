# `ammer`

Unified FFI for native extensions for [Haxe](https://haxe.org/).

---

`ammer` allows Haxe code to use external native libraries (`.dll`, `.dylib`, `.so`) from a variety of targets without having to manually write similar but slightly different `extern` definitions and target-specific stub/glue code.

The platforms that are currently supported are:

 - [HashLink](#hashlink-specifics)
 - C++ (TODO)
 - Eval (TODO)

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
| `haxe.io.Bytes` | `unsigned char *data` + `int length` | See [`haxe.io.Bytes`](#haxeiobytes) |

### `String`

Since Haxe 4, `String`s represent a string of Unicode codepoints. Internally, different targets represent strings differently, but in `ammer` library definitions, strings are always understood as valid UTF-8 sequences.

Although the null byte is a valid Unicode codepoint, some Haxe targets use it to terminate strings, and C APIs in general use it as a end-of-string marker. This is why a single `char *` argument is sufficient to pass a string to native libraries; the null byte is used to detect the end of the string. To pass UTF-8 data which includes null bytes, `haxe.io.Bytes` has to be used instead.

### `haxe.io.Bytes`

`Bytes` represent arbitrary binary data. In terms of C types, this can be thought of as a pointer (`unsigned char *`) and a corresponding length (`int`). Whenever a native library expects arbitrary binary data, it needs to know both of these values, passed as separate types. On the Haxe side, however, a single argument is sufficient. To facilitate this difference, the length argument given to the C API is marked with the metadata `:ammer.sizeOf` with the name of the corresponding argument as a parameter. In Haxe code, the marked argument is not present, as it is always based on the length of the `Bytes` instance.

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function validate(buf:haxe.io.Bytes, @:ammer.sizeOf(buf) len:Int):Bool;
}

class Main {
  public static function main():Void {
    // note the `len` argument is not given:
    trace(Foobar.validate(haxe.io.Bytes.ofHex("CAFFE00CAFFE")));
  }
}
```

## Configuration

Various defines can be specified at compile-time to configure `ammer` behaviour.

 - `ammer.rebuild` - when defined, stub files are always regenerated; the default behaviour is to only generate the stub files when they are missing.
 - `ammer.hl.output` - see [HashLink specifics](#hashlink-specifics).

## HashLink specifics

HashLink can use native libraries when given `.hdll` files containing the stubs, which take HashLink types and pass them onto the dynamically-loaded library. The `.hdll` files specify dynamic linkage and provide HashLink FFI, as understood by the HashLink interpreter/VM `hl`.

During compilation with `ammer`, the `.hdll` file for a native library needs to be (re-)generated whenever the native library or the Haxe library definition changes. By default, these files will be placed in the same directory as the `.hl` output file. This can be changed by using the `ammer.hl.output` define:

```hxml
# ...
-D ammer.hl.output=where/to/place/the/hdll/files
--hl where/to/place/the/output.hl
```

When running, the `.hdll` file must be present either next to the `.hl` file, or in the library directory (e.g. `/usr/local/lib`). For distributing programs to end users, the former is preferred (since the `.hdll` files need not be installed).

## General notes about dynamic libraries

If you are creating a native library from scratch, ensure that it is compiled as a dynamic library.

> See http://www.microhowto.info/howto/build_a_shared_library_using_gcc.html, https://stackoverflow.com/questions/14173260/creating-shared-libraries-in-c-for-osx, or search for "dynamic library c".

The important things to remember are: compile object files with `-fPIC` (position-independent code), and compile the library with `-dynamiclib`.

To actually use a dynamic library at run-time, it must be present in a place in which the OS will know to look. This differs from platform to platform:

 - OS X - the dynamic linker will look in `/usr/lib`, `/usr/local/lib`, paths specified in the environment variables `DYLD_LIBRARY_PATH`, `DYLD_FALLBACK_LIBRARY_PATH`, `DYLD_VERSIONED_LIBRARY_PATH`, the special `@executable_path`, and more (see  https://www.mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html)
