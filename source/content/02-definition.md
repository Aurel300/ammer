<!--menu:Definition-->
<!--label:definition-->
# Definition

An `ammer` library is a set of library and library datatype definitions. Since Haxe organises code into modules and classes, both libraries and library datatypes are defined using Haxe classes.

### Libraries

The APIs of native libraries consist of a set of exported functions. An `ammer` library definition should list these functions and adapt their signatures to Haxe types. Library definitions can also expose constants.

**Read on: [Library definition](definition-library)**

### Library datatypes

In addition to functions, libraries often define their own datatypes which group together data in a meaningful way. In C, these correspond to pointers to `struct` types.

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

### Metadata applicable to library definitions

 - [`@:ammer.nativePrefix`](definition-metadata#ammer.native)
 - [`@:ammer.sub`](definition-metadata#ammer.sub)

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

 - variables - expression re-evaluated every time the variable is used
 - bitwise flags - same as `Int` constants, but type safe for bitwise-or combinations

<!--label:definition-link-->
### Linking subdefinitions

In addition to libraries, `ammer` offers three kinds of "subdefinitions":

 - [Sublibraries](definition-sub)
 - [Library datatypes](definition-type)
 - [Enumerations](definition-enum)

Each forms a link to the parent in its declaration (e.g. `... extends ammer.Sublibrary<ParentLibrary> ...`). However, this link may need to also be declared on the parent library using the [`@:ammer.sub`](definition-metadata#ammer.sub) metadata.

<div class="example">

### Example: linking a sublibrary

```haxe
// in file Foobar.hx
@:ammer.sub((_ : FoobarSub))
class Foobar extends ammer.Library<"foobar"> {}

// in file FoobarSub.hx
class FoobarSub extends ammer.Sublibrary<Foobar> {}
```

In this example, the `Foobar` library "discovers" the `FoobarSub` sublibrary because of the `@:ammer.sub` metadata. The `FoobarSub` sublibrary "discovers" its parent library because it is the type parameter to `ammer.Sublibrary`.
</div>

In most cases, `@:ammer.sub` is not required. Subdefinitions belonging to the library are also discovered by following the types used in the library functions and variables. However, there may be cases when a subdefinition is not referred to in the parent library code. If the subdefinition is also in a separate module (file), and the compiler happens to type the parent library first, compilation will fail. As such, it is recommended to always declare subdefinitions using `@:ammer.sub`.

<!--label:definition-sub-->
## Sublibraries

For better code organisation, it is possible to split a library definition into multiple classes. If the separate class still consists of static functions and not "instance" methods (in which case a [library datatype](definition-type) is more appropriate), it can be defined as a sublibrary.

To define a sublibrary, extend `ammer.Sublibrary<...>` with a regular Haxe class. The type parameter for `ammer.Sublibrary` should be the `ammer` library this class belongs to.

<div class="example">

### Example: sublibrary definition

```haxe
package foo;

@:ammer.sub((_ : FoobarSub))
class Foobar extends ammer.Library<"foobar"> {}

class FoobarSub extends ammer.Sublibrary<Foobar> {
  // ...
}
```

In this example, `FoobarSub` is a sublibrary belonging to `Foobar`.
</div>

Apart from forming a separate Haxe class, sublibraries are behave identically to [libraries](definition-library).

### Linking

Sublibraries might need to be linked with the parent library using `@:ammer.sub(...)`. See [linking subdefinitions](definition-link).

### Metadata applicable to sublibraries

 - [`@:ammer.nativePrefix`](definition-metadata#ammer.native)

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

The rules for identifying the native function names are the same as for library functions. Unlike libraries, library datatypes cannot contain `static` functions or constants.

<!--sublabel:variables-->
### Variables

Library datatypes can also have variables. Variables must be declared using `public var` fields.

<div class="example">

### Example: library datatype variables

```haxe
class FoobarType extends ammer.Pointer<"foobar_t", Foobar> {
  public var bar:Int;
}
```

In this example, `FoobarType` is a library datatype for the `Foobar` library. It has a `bar` variable that can be read or written:

```haxe
var x:FoobarType = ...;
x.bar = 3;
var y = x.bar;
```
</div>

Variables map to pointer accesses in C code, so a `bar` variable is read as `(someStruct)->bar` and written as `(someStruct)->bar = value`. Note that any read or write variable access has a runtime cost of a function call.

The rules for identifying the native variable names are the same as for functions.

<!--sublabel:struct-types-->
### Struct types

[`@:ammer.struct`](definition-metadata#ammer.struct) can be used to specify that the pointer is a pointer to a struct known at compile time (not an incomplete or `extern` struct). Doing this adds the static method `alloc` and the instance method `free` to the type.

<div class="example">

### Example: library datatype struct

```haxe
@:ammer.struct
class FoobarType extends ammer.Pointer<"foobar_t", Foobar> {
  public var bar:Int;
}
```

In this example, `FoobarType` is a library datatype for the `Foobar` library. It is declared a struct, which means that the `alloc` and `free` methods are implicitly added. Supposing there is a `Foobar.takeStruct(x:FoobarType)` method:

```haxe
var x = FoobarType.alloc();
x.bar = 42;
Foobar.takeStruct(x);
x.free();
```
</div>

Note that incorrect use of `alloc` and `free` may lead to memory leaks or segmentation faults at runtime. A struct that is `alloc`'ed once must be `free`'d manually at a later point, because the garbage collector cannot do it automatically. Once a struct is `free`'d, its fields should not be accessed, nor should the Haxe object referencing the struct be passed into any library functions, because the pointer becomes invalid.

### Linking

Library datatypes might need to be linked with the parent library using `@:ammer.sub(...)`. See [linking subdefinitions](definition-link).

### Metadata applicable to library datatypes

 - [`@:ammer.nativePrefix`](definition-metadata#ammer.nativePrefix)
 - [`@:ammer.struct`](definition-metadata#ammer.struct)

### Planned features

See [related issue](issue:3).

 - Pass-by-value semantics.
 - Optimised variable access without a function call.

<!--label:definition-type-nested-->
### Nested data

Instances of [library datatypes](definition-type) in `ammer` refer to pointers to the actual data, which is allocated on the heap. This is true even if the instance is contained in a field that is already a part of a struct.

<div class="example">

### Example: struct referring to struct by pointer

```haxe
class FoobarA extends ammer.Pointer<"foobar_a_t", Foobar> {
  public var val:Int;
}

class FoobarB extends ammer.Pointer<"foobar_b_t", Foobar> {
  public var bar:FoobarA;
}
```

In this example, `FoobarA` and `FoobarB` are library datatype for the `Foobar` library. `FoobarB` has a field `bar`, which refers by pointer to an instance of `FoobarA`. The example might correspond to the following C structs:

```c
typedef struct {
  int val;
} foobar_a_t;

typedef struct {
  foobar_a_t *bar;
} foobar_b_t;
```

Note the `*` on `bar`.
</div>

If a field is instead meant to represent the struct itself, rather than a pointer to it, `ammer.ffi.Nested<...>` can be used.

<div class="example">

### Example: struct referring to struct by value

```haxe
class FoobarA extends ammer.Pointer<"foobar_a_t", Foobar> {
  public var val:Int;
}

class FoobarB extends ammer.Pointer<"foobar_b_t", Foobar> {
  public var bar:ammer.ffi.Nested<FoobarA>;
}
```

In this example, `FoobarB` contains an instance of `FoobarA`. The example might correspond to the following C structs:

```c
typedef struct {
  int val;
} foobar_a_t;

typedef struct {
  foobar_a_t bar;
} foobar_b_t;
```

Note that `foobar_a_t` is embedded directly into `foobar_b_t`.
</div>

`ammer.ffi.Nested<...>` can also be used to model the fields of a `union` (and C-like ADTs).

<div class="example">

### Example: unions and ADTs

```haxe
class FoobarParent extends ammer.Pointer<"foobar_parent_t", Foobar> {
  public var isTypeA:Bool;
  public var aData:ammer.ffi.Nested<FoobarA>;
  public var bData:ammer.ffi.Nested<FoobarB>;
}

class FoobarA extends ammer.Pointer<"foobar_a_t", Foobar> {
  public var x:Int;
  public var y:Int;
}

class FoobarB extends ammer.Pointer<"foobar_b_t", Foobar> {
  public var f:Float;
}
```

In this example, `FoobarParent` "contains" both data for a `FoobarA` instance and a `FoobarB` instance. Assuming a C definition as shown below, this could form a simple ADT.

```c
typedef struct {
  int x;
  int y;
} foobar_a_t;

typedef struct {
  double f;
} foobar_b_t;

typedef struct {
  bool isTypeA;
  union {
    foobar_a_t aData;
    foobar_b_t bData;
  };
}
```

In Haxe, one could use the ADT with a `switch` like so:

```haxe
var x:FoobarParent = ...;
switch [x.isTypeA, x] {
  case [true, _.aData => data]:
    trace("FoobarA", data.x, data.y);
  case [false, _.bData => data]:
    trace("FoobarB", data.f);
}
```
</div>

<!--label:definition-enum-->
## Enumerations

Enumerations are collections of integer values, each with a label. In this context they should be understood as C `enum`s, rather than Haxe's `enum`s, which are more complex.

To define an enumeration, extend `ammer.IntEnum<..., ...>` with a regular Haxe class. The first type parameter for `ammer.IntEnum` should be a string identifying the native C type name (which may or may not include `enum` at the beginning). The second type parameter should be the `ammer` library this type belongs to.

<div class="example">

### Example: enumeration definition

```haxe
class FoobarEnum extends ammer.IntEnum<"enum foobar_enum_t", Foobar> {
  // ...
}
```

In this example, `FoobarEnum` is an enumeration for the `Foobar` library. The first type parameter is `enum foobar_enum_t`, which means functions which work with this datatype would accept `enum foobar_enum_t`.
</div>

Individual cases of an enumeration are defined as [constants](definition-library-constants).

<div class="example">

### Example: enumeration cases

```haxe
class FoobarEnum extends ammer.IntEnum<"enum foobar_enum_t", Foobar> {
  public static var E_FOO:FoobarEnum;
  public static var E_BAR:FoobarEnum;
}
```

This example could correspond to the following C definition:

```c
enum foobar_enum_t {
  E_FOO,
  E_BAR
};
```
</div>

[`@:ammer.native`](https://aurel300.github.io/ammer/definition-metadata.html#ammer.native) can be used on enumeration cases, just like any other constant.

Multiple enumeration cases can have the same underlying value. However, if this is the case, the reverse mapping (when receiving a value from a native library) is not guaranteed to work.

### Linking

Enumerations might need to be linked with the parent library using `@:ammer.sub(...)`. See [linking subdefinitions](definition-link).

<!--label:definition-metadata-->
## Metadata

| Metadata | Applicable to |
| --- | --- |
| [`@:ammer.c.prereturn`](definition-metadata#ammer.c.prereturn) | Functions |
| [`@:ammer.c.return`](definition-metadata#ammer.c.return) | Functions |
| [`@:ammer.macroCall`](definition-metadata#ammer.macroCall) | Functions |
| [`@:ammer.native`](definition-metadata#ammer.native) | Functions, constants, library datatypes |
| [`@:ammer.nativePrefix`](definition-metadata#ammer.nativePrefix) | Libraries, sublibraries, library datatypes, enumerations |
| [`@:ammer.struct`](definition-metadata#ammer.struct) | Library datatypes |
| [`@:ammer.sub`](definition-metadata#ammer.sub) | Libraries |

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

<!--sublabel:ammer.struct-->
### `@:ammer.struct`

Applied on a library datatype to indicate that the pointer is a pointer to a struct with a known size at compile time. Adds the static method `alloc` and the instance method `free`. See [struct types](definition-type#struct-types).

<!--sublabel:ammer.sub-->
### `@:ammer.sub((_ : <Type>))`

Applied on a library to indicate additional subdefinitions. The parameter must be in the form `(_ : SomeType)`. Due to Haxe's syntax for `ECheckType`, the parentheses are not optional, i.e. `@:ammer.sub(_ : SomeType)` is not valid, but `@:ammer.sub((_ : SomeType))` is. See [linking subdefinitions](definition-link).

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
| | `ammer.ffi.Nested<...>` | `<type>` | See [nested data](definition-type-nested). |
| **Enumerations** | subtypes of `ammer.IntEnum<...>` | `<type>` | See [enumerations](definition-enum). |
| **Callbacks** | Haxe function types wrapped in `ammer.ffi.Callback<..., mode>` | `<type> (*)(<type...>)` | See [callbacks](definition-ffi-callbacks). |

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

<!--label:definition-ffi-callbacks-->
### Callbacks

Native libraries can expose functions that take another function, or a "callback" as an argument. Unlike Haxe, C does not support native closures, so the most common way to emulate passing context back to a function is via "user data", an additional `void *` argument that is passed next to the callback. When the native library needs to call the callback, it will pass back the user data in one of its arguments.

`ammer` supports callbacks via function pointers and user data. The user data is automatically created when a closure is sent to the native library, and automatically consumed when the closure needs to be invoked.

A callback declaration consists of three parts split across two arguments:

 - The actual function argument, of type `ammer.ffi.Closure` with two type parameters:
   - The function signature. One of the arguments of the function must be of type `ammer.ffi.ClosureDataUse`.
   - The GC mode, one of `"none"`, `"once"`, `"forever"`. See [GC mode](definition-ffi-callbacks#gc-mode).
 - A callback data argument, of type `ammer.ffi.ClosureData` with a type parameter that is a string referring to the name of the function argument.

`ClosureDataUse` and `ClosureData` arguments are only present in the API definition. At runtime, only the function argument must be passed in, with a compatible function instance.

<div class="example">

### Example: callback

```haxe
import ammer.ffi.*;
class Foobar extends ammer.Library<"foobar"> {
  public static function store(func:Closure<(Int, Int, ClosureDataUse)->Float, "once">, _:ClosureData<"func">):Void;
  public static function use():Void;
}
```

In this example, `Foobar` is a library with two methods. `store` takes a Haxe function and stores it, and `use` invokes it again. The C API for the above might be:

```c
void store(int (*func)(int, int, void*), void *user_data);
void use(void);
```

To use this library in Haxe code, the `ClosureData` and `ClosureDataUse` arguments are omitted, because they are inserted automatically.

```haxe
var counter = 0;
Foobar.store((a, b) -> {
  trace("counter", counter++);
  return a / b;
});

// later:
Foobar.use(); // counter, 0
Foobar.use(); // counter, 1
Foobar.use(); // counter, 2
```

Note that just like a regular Haxe closure, the closure retains a reference to its context, and with it a reference to its local copy of `counter`.
</div>

<!--sublabel:gc-mode-->
### GC mode

When passing Haxe closures to native libraries, a lot of care must be taken to avoid potential memory leaks and segmentation faults. In all Haxe targets, the GC (garbage collector) must be able to reach Haxe-allocated objects, otherwise it deems them safe to be collected and may free their memory. This is a problem when Haxe objects are referenced by non-Haxe code, because the GC cannot follow pointers it has not allocated. Instead, they need to be explicitly registered with the GC as "GC roots".

To solve this issue, `ammer` allows three GC modes as the second type parameter of `ammer.ffi.Closure`:

 - `"none"` - The closure is never rooted. May work with functions that are immediately invoked, or static functions.
 - `"once"` - The closure is rooted once, when given to the native library, and unrooted when it is invoked. Useful for one-time callbacks.
 - `"forever"` - The closure is rooted once, when given to the native library, and then never unrooted. Potentially useful for long-living recurring events.
