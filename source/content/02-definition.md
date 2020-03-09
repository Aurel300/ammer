<!--menu:Definition-->
<!--label:definition-->
# Definition

An `ammer` library is a set of library and library datatype definitions. Since Haxe organises code into modules and classes, both libraries and library datatypes are defined using Haxe classes.

### Libraries

The APIs of native libraries consist of a set of exported functions. An `ammer` library definition should list these functions and adapt their signatures to Haxe types. Library definitions can also expose constants.

**Read on: [Library definition](definition-library)**

### Library datatypes

In addition to functions, libraries often define their own datatypes which group together data in a meaningful way. In C, these correspond to `struct` types, or pointers to `struct` types.

**Read on: [Library datatype definition](definition-type)**

<!--label:definition-library-->
## Library definition

To define a library, extend `ammer.Library<...>` with a regular Haxe class. The type parameter for `ammer.Library` should be a string identifier for the native library. This identifier is used in the [library configuration](configuration-library), so it should only consist of letters and underscores.

<div class="example">

### Example: library definition

```haxe
package foo;

class Foobar extends ammer.Library<"foobar"> {
  // ...
}
```

In this example, `foo.Foobar` is an `ammer` library definition for the native library called `foobar`. Such a definition will require at least the [`ammer.lib.foobar.include`](configuration-library#ammer.lib.include) and [`ammer.lib.foobar.library`](configuration-library#ammer.lib.library) compile-time defines to build. See [configuration](configuration).
</div>

The fields of a library definition consist of [functions](definition-library-functions) and [constants](definition-library-constants).

<!--label:definition-library-functions-->
### Functions

Functions can be declared in library definitions using `public static fuction` fields with no function body (similar to Haxe `extern`s).

<div class="example">

### Example: function in library definition

```haxe
class Foobar extends ammer.Library<"foobar"> {
  public static function hello(a:Int, b:String):Float;
}
```

In this example, `hello` is a function for the `Foobar` `ammer` library definition. The function `double hello(int a, char *b)` must be available from the `foobar` native library.
</div>

All return types and argument types must be written explicitly, since Haxe type inference is not compatible with native libraries. Only a subset of Haxe types can be used, and there may be some restrictions on argument names. See [FFI types](definition-ffi).

### Macros

The same `public static function` syntax can be used to declare C preprocessor macro calls, but the additional metadata [`@:ammer.macroCall`](definition-metadata#ammer.macroCall) should be applied. Macros which require unusual C syntax may cause a compilation failure.

### Metadata applicable to functions

Metadata can be used to inject additional C code into the wrapper code, mark functions as macro calls, or provide the native name for a function. See the full metadata descriptions for more information:

 - [`@:ammer.c.prereturn`](definition-metadata#ammer.c.prereturn)
 - [`@:ammer.c.return`](definition-metadata#ammer.c.return)
 - [`@:ammer.macroCall`](definition-metadata#ammer.macroCall)
 - [`@:ammer.native`](definition-metadata#ammer.native)

<!--label:definition-library-constants-->
### Constants

Constants can be declared in library definitions using `public static final` fields. Their value should correspond to values which are made available by the library without any prior initialisation. Typically, these are C preprocessor defines or C enum values, available from the library headers.

<div class="example">

### Example: constant in library definition

```haxe
class Foobar extends ammer.Library<"foobar"> {
  @:ammer.native("HELLO_WORLD")
  public static final helloWorld:String;
}
```

In this example, `helloWorld` is a string constant for the `Foobar` `ammer` library definition. The headers of the `foobar` native library must ensure that `HELLO_WORLD` is a valid C expression, for example with `#define HELLO_WORLD "hello world"`.
</div>

[`@:ammer.native`](definition-metadata#ammer.native) can be used to specify the C expression which will be used to determine the value of a constant. There is no restriction to what the expression can be: it may be a literal, a constant, the result of a library call, and so forth. However, all constant values are initialised at the same time, typically before Haxe `main` is reached, so the C expression should not be a mutable value, because it will not be updated.

Constants are restricted to a small subset of Haxe types:

 - `Bool`
 - `Float`
 - `Int`
 - `String`

### Metadata applicable to constants

 - [`@:ammer.native`](definition-metadata#ammer.native)

### Planned features

See [related issue](issue:17).

 - variables - expression re-evaluated everytime the variable is used
 - enums - declared as actual `enum`s in Haxe code
 - bitwise flags - same as `Int` constants, but type safe for bitwise-or combinations

<!--label:definition-type-->
## Library datatype definition

To define a library datatype, extend `ammer.Pointer<..., ...>` with a regular Haxe class. The first type parameter for `ammer.Pointer` should be a string identifying the native C type name (without the `*`). The second type parameter should be the `ammer` library this type belongs to.

<div class="example">

### Example: library datatype definition

```haxe
class FoobarType extends ammer.Pointer<"foobar_t", Foobar> {
  // ...
}
```

In this example, `FoobarType` is a library datatype for the `Foobar` library. The first type parameter is `foobar_t`, which means functions which work with this datatype would accept `foobar_t *`.
</div>

Sometimes it is useful to associate some functions of a library with the datatype rather than the library itself, then in Haxe code use them as non-static instance methods rather than static methods. Library datatype functions are defined just like [library functions](definition-library-functions), with two differences:

 - they are declared as `public function`
 - one of their arguments must be of the special `ammer.ffi.This` type

When calling instance functions of a library datatype, the `This` argument is omitted, as it is automatically filled in with the used instance.

<div class="example">

### Example: library datatype function

```haxe
class FoobarType extends ammer.Pointer<"foobar_t", Foobar> {
  public function doFoobarAction(_:ammer.ffi.This, a:Int, b:Int):Int;
}
```

In this example, `doFoobarAction` is a datatype function. In Haxe code, it could be used like this:

```haxe
var x:FoobarType = ...;
x.doFoobarAction(3, 4);
```

Note that the first argument for `doFoobarAction` is not specified – `x` is used automatically.
</div>

Unlike libraries, library datatypes cannot contain `static` functions or constants.

### Metadata applicable to library datatypes

 - [`@:ammer.nativePrefix`](definition-metadata#ammer.nativePrefix)

### Planned features

See [related issue](issue:3).

 - struct types - passed by value, not by pointer
 - struct constructors
 - variable getters and setters

<!--label:definition-metadata-->
## Metadata

| Metadata | Applicable to |
| --- | --- |
| [`@:ammer.c.prereturn`](definition-metadata#ammer.c.prereturn) | Functions |
| [`@:ammer.c.return`](definition-metadata#ammer.c.return) | Functions |
| [`@:ammer.macroCall`](definition-metadata#ammer.macroCall) | Functions |
| [`@:ammer.native`](definition-metadata#ammer.native) | Functions, constants, library datatypes |
| [`@:ammer.nativePrefix`](definition-metadata#ammer.nativePrefix) | Libraries, library datatypes |

<!--sublabel:ammer.c.prereturn-->
### `@:ammer.c.prereturn(code:String)`

Applied to a function declaration to inject C code directly before the native function call.

<!--sublabel:ammer.c.return-->
### `@:ammer.c.return(code:String)`

Applied to a function declaration to inject C code that replaces the native function call. The `code` string may contain the `%CALL%`, which will expand to the full native call.

Can be useful to dereference the value returned from the native library:

```haxe
// native library has: float *version(void);
@:ammer.c.return("*(%CALL%)") public static function version():Float;
```

<!--sublabel:ammer.macroCall-->
### `@:ammer.macroCall`

Applied to a function declaration to specify that is is a macro call, not a real function. This currently only makes a difference for the C++ target.

```haxe
@:ammer.macroCall @:ammer.native("foo") public static function foo(a:Int):Int;
```

<!--sublabel:ammer.native-->
### `@:ammer.native(name:String)`

Applied to a function declaration to specify that it has a different name in the native library than the one declared in Haxe.

```haxe
@:ammer.native("foo_bar") public static function fooBar():Void;
```

Can be useful to avoid Haxe-reserved keywords or to preserve Haxe-like function naming conventions. Additionally allows C++ template instances to be used - multiple functions with different type signatures and names but same `@:ammer.native` metadata can be specified:

```haxe
@:ammer.native("foo") public static function fooInt(arg:Int):Int;
@:ammer.native("foo") public static function fooFloat(arg:Float):Float;
```

<!--sublabel:ammer.nativePrefix-->
### `@:ammer.nativePrefix(prefix:String)`

Applied on a library or library datatype to specify that the native names of its functions consist of `prefix + function name`.

```haxe
@:ammer.nativePrefix("foo_")
class Foobar extends ammer.Library<"foobar"> {
  // this function will use foo_bar in the C APIs:
  public static function bar():Void;
}
```

`@:ammer.native` on a field overrides `@:ammer.nativePrefix` on its containing class.

<!--label:definition-ffi-->
## FFI types

Haxe employs a rich type system, but many of its features cannot be translated meaningfully into library definitions, hence only a subset of basic Haxe types are supported in `ammer` libraries:

| Category | Haxe type | C type | Note |
| --- | --- | --- | --- |
| **Built-in types** | [`Void`](api:Void) | `void` | Only for return types. |
| | [`Bool`](api:Bool) | `bool` | From `<stdbool.h>`. |
| | [`Float`](api:Float) | `double` | Double-precision (64-bit) floating-point number. |
| | [`Int`](api:Int) | `int` | 32-bit wide signed integer. |
| | [`UInt`](api:UInt) | `unsigned int` | 32-bit wide unsigned integer. |
| **Size types** | [`String`](api:String) | `char *` | See [`String`](definition-ffi-size#string). |
| | [`haxe.io.Bytes`](api:haxe.io.Bytes) | `unsigned char *` and `size_t` | See [`Bytes`](definition-ffi-size#bytes). |
| | `ammer.ffi.SizeOf<arg>` | `size_t` | |
| | `ammer.ffi.SameSizeAs<T, arg>` | | |
| | `ammer.ffi.SizeOfReturn` | `size_t *` | |
| | `ammer.ffi.NoSize<T>` | | |
| **Library datatypes** | subtypes of `ammer.Pointer<...>` | `<type> *` | See [library datatypes](definition-type). |
| | `ammer.ffi.This` | `<type> *` | Only usable as an argument type in [library datatype functions](definition-type). |

<!--label:definition-ffi-size-->
### Size types

### `String`

Since Haxe 4, `String`s consist of Unicode codepoints. Internally, different targets represent strings differently, but in `ammer` library definitions, strings are always understood as valid UTF-8 sequences.

Although the null byte is a valid Unicode codepoint, some Haxe targets use it to terminate strings, and C libraries in general use it as an end-of-string marker. This is why a single `char *` argument is sufficient to pass a string to native libraries; the null byte is used to detect the end of the string. To pass UTF-8 data which includes null bytes, `haxe.io.Bytes` has to be used instead.

### `Bytes`

`haxe.io.Bytes` values represent arbitrary binary data. In terms of C types, these can be thought of as a pointer (`unsigned char *`) and a corresponding length (`size_t` or `int`). When a native library expects arbitrary binary data, it often needs to know both of these values, passed as separate arguments. On the Haxe side, however, a single argument is sufficient. To facilitate this difference, the length argument given to the native library is marked with the type `ammer.ffi.SizeOf` with the name of the corresponding argument as a type parameter. In Haxe code, the marked argument is not present, as it is always based on the length of the `Bytes` instance.

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

If the size of a `Bytes` object is not passed along to the library at all, the argument type should be wrapped in `ammer.ffi.NoSize`:

```haxe
public static function takeBuffer(buf:ammer.ffi.NoSize<haxe.io.Bytes>):Void;
```

When a C API returns a binary buffer, one of the arguments may be a pointer to which the size of the buffer will be written. This can be expressed with the type `ammer.ffi.SizeOfReturn`. Once again, in Haxe code, this argument will not be present.

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

When a native library returns a binary buffer that is the same size as one of the input arguments, the return type can be wrapped with `ammer.ffi.SameSizeAs`:

```haxe
public static function reverseBuffer(buf:haxe.io.Bytes, len:ammer.ffi.SizeOf<"buf">):ammer.ffi.SameSizeAs<haxe.io.Bytes, "buf">;
```
