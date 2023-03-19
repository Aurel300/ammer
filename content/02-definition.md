<!--label:definition-->
# Definition

An `ammer` library is a set of library definitions and library datatype definitions. Since Haxe organises code into modules and classes, both libraries and library datatypes are defined using Haxe classes. This section provides a guide-level explanation of the various parts of a library definition, with examples. Further detail can be found in later sections.

### Libraries

The APIs of native libraries consist of a set of exported functions. An `ammer` library definition should list these functions and adapt their signatures to Haxe types. Library definitions can also expose constants.

**Read on: [Library definition](definition-library)**

### Datatypes

In addition to functions, libraries often define their own datatypes which group together data in a meaningful way. In C, these correspond to pointers to `struct` types, opaque pointers, `enum` types, or `union` types.

**Read on: [Library datatype definition](definition-type)**

<!--  ### Entrypoints (TODO) -->

<!--label:definition-library-->
## Library definition

To define a library, extend `ammer.def.Library<...>` with a Haxe class. The type parameter for `ammer.def.Library` should be a string identifier for the native library. This identifier is used in the [library configuration](configuration-library), so it must only consist of letters and underscores.

<div class="example">

### Example: library definition

```haxe
package foo;

class Foobar extends ammer.def.Library<"foobar"> {
  // ...
}
```

In this example, `foo.Foobar` is an `ammer` library definition for the native library called `foobar`. A library definition typically includes metadata which configures properties such as the include path, the language of the native library, headers to use, etc. See [configuration](configuration) for more details.
</div>

The fields of a library definition consist of [functions](definition-library-functions) and [variables](definition-library-variables). Libraries can also be split up into several classes, see [sublibraries](definition-sub).

### Metadata applicable to library definitions

Metadata can be attached to the library definition class. This allows for configuration of the library compilation, its source language, header files, and more. See the full metadata descriptions for more information:

<!--include:meta-library-->

<!--label:definition-library-functions-->
### Functions

Functions can be declared in library definitions using `public static fuction` fields with no function body (similar to Haxe externs).

<div class="example">

### Example: function in library definition

```haxe
class Foobar extends ammer.def.Library<"foobar"> {
  public static function hello(a:Int, b:String):Float;
}
```

In this example, `hello` is a function in the `Foobar` library. The function maps to the native function `double hello(int a, char *b)` (in C types).
</div>

All return types and argument types must be written explicitly, since Haxe type inference is not compatible with native libraries. Only a subset of Haxe types can be used. See [FFI types](ref-ffi).

<!--sublabel:macros-->
### Macros

The same `public static function` syntax can be used to declare C preprocessor macro calls, but the additional metadata [`@:ammer.macroCall`](ref-annot#c.macrocall) should be applied. Macros which require unusual C syntax may cause a compilation failure: for arbitrary C code expressions, see the [next section](#custom-c).

<!--sublabel:custom-c-->
### Customising the C code

For every method declared in an `ammer` definition, there is glue code generated which has the following general shape:

```c
target_return_type func(args...) {
  native_args = ... // "pre": decode arguments from target-specific representation to C
  ... // "prereturn"
  c_return_type _return =
    native_call(native_args...); // "return"
  ... // "post": encode returned value to a target-specific representation, cleanup, return
}
```

A large part of the function, including its exact signature, depends on the concrete target. However, `ammer` ensures that the initial part of the function code gets the local variables to the same state on any platform: the local variables `_arg0`, ..., `_argN` are of the [C types](ref-ffi) corresponding to the declared argument types.

If there is additional code that should be called before the actual native call happens, it can be inserted at the point marked "prereturn" above. This is accomplished with the [`@:ammer.c.prereturn`](ref-annot#c.prereturn) metadata.

If the native call itself should be replaced with a different C expression, this can be accomplished with the [`@:ammer.c.return`](ref-annot#c.return) metadata. The substring `%CODE%` will be replaced in the provided code with the original call expression.

<!--sublabel:pure-haxe-->
### Pure Haxe functions

The [`@:ammer.haxe`](ref-annot#haxe) metadata can be used to define methods on libraries which are implemented purely in Haxe and have no native counterpart. When this metadata is attached to a method (and *only* then), it may have a body.

### Metadata applicable to functions

Metadata can be used to inject additional C code into the wrapper code, mark functions as macro calls, or provide the native name for a function. See the full metadata descriptions for more information:

- [`@:ammer.haxe`](ref-annot#haxe)
- [`@:ammer.macroCall`](ref-annot#c.macrocall)
- [`@:ammer.native`](ref-annot#native)
- [`@:ammer.c.macroCall`](ref-annot#c.macrocall)
- [`@:ammer.c.prereturn`](ref-annot#c.prereturn)
- [`@:ammer.c.return`](ref-annot#c.return)
- [`@:ammer.ret.derive`](ref-annot#ret.derive)

The following metadata can be attached to function arguments:

- [`@:ammer.skip`](ref-annot#skip)
- [`@:ammer.derive`](ref-annot#derive)
- [`@:ammer.c.cast`](ref-annot#c.cast)

<!--redirect:definition-library-constants-->
<!--label:definition-library-variables-->
### Variables

Variables can be declared in library definitions using `public static var` fields.

<div class="example">

### Example: variable in library definition

```haxe
class Foobar extends ammer.def.Library<"foobar"> {
  public static var bar:Int;
}
```

In this example, `bar` is an integer variable in the `Foobar` library.
</div>

As for function signatures, variable types are restricted to a subset of Haxe types. See [FFI types](ref-ffi).

<!--sublabel:constants-->
### Constants

If a value from a native library is available immediately, such as constants or macro definitions, it can be declared as a constant in the `ammer` definition using a `public static final` field.

<div class="example">

### Example: constant in library definition

```haxe
class Foobar extends ammer.def.Library<"foobar"> {
  @:ammer.native("HELLO_WORLD")
  public static final helloWorld:String;
}
```

In this example, `helloWorld` is a string constant for the `Foobar` `ammer` library definition. The headers of the `foobar` native library must ensure that `HELLO_WORLD` is a valid C expression, for example with `#define HELLO_WORLD "hello world"`.
</div>

[`@:ammer.native`](ref-annot#native) can be used to specify the C expression which will be used to determine the value of a constant. There is no restriction to what the expression can be: it may be a literal, a constant, the result of a library call, and so forth. However, all constant values are initialised at the same time, typically before Haxe `main` is reached, so the C expression should not be a mutable value, because it will not be updated.

### Metadata applicable to variables and constants

- [`@:ammer.native`](ref-annot#native)

<!--label:definition-sub-->
### Sublibraries

For better code organisation, it is possible to split a library definition into multiple classes. If the separate class consists of static functions and not "instance" methods (in which case a [library datatype definition](definition-type) might be more appropriate), it can be defined as a sublibrary.

To define a sublibrary, extend `ammer.def.Sublibrary<...>` with a Haxe class. The type parameter for `ammer.def.Sublibrary` should be the `ammer` library this class belongs to.

<div class="example">

### Example: sublibrary definition

```haxe
@:ammer.sub((_ : FoobarSub))
class Foobar extends ammer.def.Library<"foobar"> {}

class FoobarSub extends ammer.def.Sublibrary<Foobar> {
  // ...
}
```

In this example, `FoobarSub` is a sublibrary belonging to `Foobar`.
</div>

Apart from forming a separate Haxe class, sublibraries behave identically to [libraries](definition-library).

### Linking

Sublibraries should be linked with the parent library using the [`@:ammer.sub(...)`](ref-annot#sub) metadata to avoid compilation errors. See [linking subdefinitions](definition-link).

### Metadata applicable to sublibraries

<!--include:meta-sublibrary-->

<!--label:definition-type-->
## Datatypes

Libraries often group data into complex types such as structs. To make use of these in Haxe code and in `ammer` library definitions, they can be defined as Haxe types.

### Opaque types

Opaque types are types whose fields and layout are only known to the library that defines them. Any interaction with such types happens through methods defined by the library.

**Read on: [Opaque types](definition-type-opaque)**

### Structs

Structs are types which contain fields, which can be read from or written to.

**Read on: [Structs](definition-type-struct)**

### Enums

Enums are sets of named values of the same type.

**Read on: [Enums](definition-type-enum)**

### Haxe types

Native libraries can store pointers to instances of Haxe types.

**Read on: [Haxe types](definition-type-haxe)**

### Callbacks

Callbacks allow Haxe code to be called by the native library.

**Read on: [Callbacks](definition-type-callbacks)**

<!--label:definition-type-opaque-->
### Opaque types

When a native library uses a type in its API without revealing the actual fields and layout of that type (as is the case with [structs](definition-type-struct)), the type can be called opaque. Such values cannot be allocated or freed, and can only be used meaningfully by passing them to the methods of the native library that defined them in the first place.

To define an opaque type, extend `ammer.def.Opaque<...>` with a Haxe class. The first type parameter for `ammer.def.Opaque` should be a string identifying the native C type name. The second type parameter should be the `ammer` library this type belongs to.

Although opaque type definitions cannot contain any variable fields, they may still contain [instance methods](definition-type-instance).

<div class="example">

### Example: opaque type definition

```haxe
class FoobarOpaque extends ammer.def.Opaque<"opaque_t", Foobar> {
  // ...
}
```

In this example, `FoobarOpaque` is an opaque type of the `Foobar` library. The C name for this type is `opaque_t`.
</div>

### Linking

Opaque types should be linked with the parent library using the [`@:ammer.sub(...)`](ref-annot#sub) metadata to avoid compilation errors. See [linking subdefinitions](definition-link).

### Metadata applicable to opaque types

<!--include:meta-opaque-->

<div class="future">

### Not yet implemented: large opaque types

Currently, `ammer` assumes every opaque type is pointer-sized or smaller. This allows passing it between Haxe and native code without any allocations. Supporting opaque types that do not fit into a pointer is a planned feature.
</div>

<!--label:definition-type-struct-->
### Structs

When a struct type is not [opaque](definition-type-opaque), its fields are known and can be read and written directly, without using a library method.

To define a struct type, extend `ammer.def.Struct<..., ...>` with a Haxe class. The first type parameter for `ammer.def.Struct` should be a string identifying the native C type name. The second type parameter should be the `ammer` library this type belongs to.

Struct definitions can contain [variable fields](#variables), as well as [instance methods](definition-type-instance).

<div class="example">

### Example: library datatype definition

```haxe
class FoobarStruct extends ammer.def.Struct<"struct foobar_s", Foobar> {
  // ...
}
```

In this example, `FoobarStruct` is a struct in the `Foobar` library. The C name for this struct is `struct foobar_s`. Values of `FoobarStruct` in Haxe represent instances of `struct foobar_s*` (a *pointer* to `struct foobar_s`).
</div>

<!--sublabel:pointer-->
### Instances are pointers

Note that on the Haxe side, any struct value will be represented as a pointer to a struct. This is because most `ammer` targets do not support arbitrarily large stack-allocated data. See [passing structs directly](#deref) for declaring APIs which do not use a pointer indirection.

<!--sublabel:variables-->
### Variables

Structs definitions can contain variables, declared as `public var` or `var` fields.

<div class="example">

### Example: struct variables

```haxe
class FoobarStruct extends ammer.def.Struct<"struct foobar_s", Foobar> {
  public var bar:Int;
}
```

In this example `FoobarStruct` has a `bar` variable that can be read or written:

```haxe-expr
var x:FoobarStruct = #dummy expr/*...*/;
x.bar = 3;
var y = x.bar;
```
</div>

Variables map to pointer accesses in C code, so a `bar` variable is read as `(someStruct)->bar` and written as `(someStruct)->bar = value`. Note that any read or write variable access may have a runtime cost of a function call.

<!--sublabel:alloc-->
### Allocation and deallocation

To make it possible to allocate and deallocate a struct, it must be marked with the [`@:ammer.alloc`](ref-annot#alloc) metadata. When annotated, several functions are made available:

- [`alloc`](ref-lib#allocstruct) — a static function which allocates an instance of the given struct type. Initial values for its fields can optionally be passed using an object syntax.
- [`free`](ref-lib#freestruct) — an instance method which deallocates the underlying allocation.
- [`nullPtr`](ref-lib#nullptrstruct) — a static function which returns a null pointer of the given struct type.

The name of the generated functions can be changed to avoid conflicts with other functions. [`@:ammer.alloc`](ref-annot#alloc) is simply a convenience shortcut to the combination [`@:ammer.gen.alloc("alloc")`](ref-annot#gen.alloc), [`@:ammer.gen.free("free")`](ref-annot#gen.free), [`@:ammer.gen.nullPtr("nullPtr")`](ref-annot#gen.nullptr), where the string arguments specify the name of each generated method.

<div class="example">

### Example: allocating and deallocating a struct

Given a struct definition annotated with [`@:ammer.alloc`](ref-annot#alloc):

```haxe
@:ammer.alloc
class FoobarStruct extends ammer.def.Struct<"struct foobar_s", Foobar> {
  public var some_field:Int;
}
```

It can be allocated by calling `alloc`:

```haxe-expr
// with fields zeroed out:
var x = FoobarStruct.alloc();
// or with some initial values:
var x = FoobarStruct.alloc({
  some_field: 42,
});
```

It can then be deallocated:

```haxe-expr
x.free();
```

And a null pointer can be obtained:

```haxe-expr
var x = FoobarStruct.nullPtr();
```
</div>

<!--sublabel:deref-->
### Passing structs directly

Native methods which take a struct directly, as opposed to a pointer to a struct, can be declared by using the special `ammer.ffi.Deref<...>` type. This dereferences the struct pointer just before the native method call.

<div class="example">

### Example: using `ammer.ffi.Deref`

```haxe
class Foobar {
  public static function take_struct_ptr(x:FoobarStruct):Void;
  public static function take_struct_val(x:ammer.ffi.Deref<FoobarStruct>):Void;
}
```

This example demonstrates passing a struct using a pointer and passing it directly. The corresponding C signatures could look like this:

```c
void take_struct_ptr(struct foobar_s* x) { /*...*/ }
void take_struct_val(struct foobar_s x) { /*...*/ }
```

Note that on the Haxe call side, the two methods are called the same way: by passing an instance of the `FoobarStruct` type. The dereferencing, if any, happens transparently.

```haxe-expr
var x:FoobarStruct = #dummy expr/*...*/;
Foobar.take_struct_ptr(x);
Foobar.take_struct_val(x);
```
</div>

A similar situation arises when a native library method returns a struct value. To obtain a pointer to the struct, a heap allocation must take place to store that struct. In `ammer`, return types can be wrapped with the special `ammer.ffi.Alloc<...>` type to achieve this.

<div class="example">

### Example: using `ammer.ffi.Alloc`

```haxe
class Foobar {
  public static function give_struct_ptr():FoobarStruct;
  public static function give_struct_val():ammer.ffi.Alloc<FoobarStruct>;
}
```

This example demonstrates a native method returning a pointer to a struct and one returning a struct directly. The corresponding C signatures could look like this:

```c
struct foobar_s* give_struct_ptr() { /*...*/ }
struct foobar_s give_struct_val() { /*...*/ }
```

Note that on the Haxe call side, the two methods have the same return type: an instance of `FoobarStruct`. The allocation, if any, happens transparently.

```haxe-expr
var x:FoobarStruct = Foobar.give_struct_ptr();
var y:FoobarStruct = Foobar.give_struct_val();
```
</div>

### Linking

Structs should be linked with the parent library using the [`@:ammer.sub(...)`](ref-annot#sub) metadata to avoid compilation errors. See [linking subdefinitions](definition-link).

### Metadata applicable to structs

<!--include:meta-struct-->

<!--label:definition-type-instance-->
### Instance methods

Although C does not have the concept of instance methods (unlike, for example, Java or C++), native libraries often define APIs which simulate such a feature by passing a pointer to a struct or opaque type as the first argument.

In `ammer`, it is possible to use such methods as instance methods rather than static methods, resulting in more readable client code. To achieve this, a function must be declared in an [opaque type definition](definition-type-opaque) or a [struct definition](definition-type-struct) with two requirements:

- It must be declared as a `function` (and not a `static function`); and
- one of its arguments must be of the special `ammer.ffi.This` type.

When calling instance methods declared this way, the `This` argument is omitted, as it is automatically filled in.

<div class="example">

### Example: instance method

```haxe
class FoobarStruct extends ammer.def.Struct<"struct foobar_s", Foobar> {
  public function do_something(_:ammer.ffi.This, a:Int):Int;
}
```

In this example, `do_something` is an instance method. In Haxe code, it could be used like this:

```haxe-expr
var x:FoobarStruct = #dummy expr/*...*/;
x.do_something(42);
```

Note that the first argument for `do_something` is not specified – `x` is used automatically.
</div>

<!--label:definition-type-enum-->
### Enums

Enums are sets of distinct, named values of the same type. In C, this may be an actual [`enum` declaration](https://en.cppreference.com/w/c/language/enum), or even a set of defines. Importantly, the values of an enum should be known at compile time.

To define an enum type, add `@:build(ammer.def.Enum.build(..., ..., ...))` to a Haxe `enum abstract`. The first argument parameter for `ammer.def.Enum.build` should be a string identifying the native C type name. The second argument should be an [FFI type](ref-ffi). The third argument should be the `ammer` library this type belongs to.

Enums should only contain variable declarations, one for each enum variant.

<div class="example">

### Example: enum definition

```haxe
@:build(ammer.def.Enum.build("int", Int32, Foobar))
enum abstract FoobarEnum(Int) from Int to Int {
  @:ammer.native("FOOBAR_VAL1") var Val1;
  @:ammer.native("FOOBAR_VAL2") var Val2;
  // ...
}
```

In this example, `FoobarEnum` is an enum in the `Foobar` library. The C type underlying this enum is a regular `int`. There are two variants: `Val1` and `Val2`, which have the integer values available in the constants `FOOBAR_VAL1` and `FOOBAR_VAL2` at compile time.
</div>

### Compilation

In order for Haxe to be able to use `ammer` enums like regular `enum abstract`s, the value of each variant must be known at compile time. `ammer` will automatically extract the appropriate values by invoking the C compiler.

### Linking

Enums should be linked with the parent library using the [`@:ammer.sub(...)`](ref-annot#sub) metadata to avoid compilation errors. See [linking subdefinitions](definition-link).

<!--label:definition-type-haxe-->
### Haxe types

C libraries often contain struct fields or function arguments of type `void*`, such that client code using the library can provide a pointer to its own datatypes. In `ammer`, such `void*` values can stand for instances of a Haxe type, such as a Haxe `class` instance.

### Garbage collection

All Haxe targets are garbage collected, which means it is the runtime's responsibility to understand which instances are no longer needed and can be re-used to free memory. For Haxe programs which do not interact with native libraries, this is not a problem. However, as soon as a Haxe instance is passed to a native library, a problem may arise: the Haxe runtime could decide that the Haxe instance is no longer usable, so it could be freed, but a reference to it may still be obtainable via the native library.

The solution used in `ammer` is to wrap Haxe instances with a reference counter, such that the programmer can indicate when a Haxe instance is or is not in use. To pass Haxe types to native libraries, use the `ammer.ffi.Haxe<...>` type in `ammer` definitions. When calling such functions, instances of Haxe types must first be wrapped using the `ammer.Lib.createHaxeRef` function. The resulting value has a `value` field to obtain the underlying Haxe instance, as well as an `incref` and `decref` function to increment or decrement the reference counter respectively.

The initial reference count of a Haxe reference is `0`.

<div class="example">

### Example: function accepting a Haxe type

```haxe
class MyHaxeType { /*...*/ }

class Foobar extends ammer.def.Library<"foobar"> {
  public static function hello(a:ammer.ffi.Haxe<MyHaxeType>):Void;
}
```

In this example, `MyHaxeType` is a regular Haxe class. The `hello` function of the `Foobar` library accepts an instance of `MyHaxeType`.

```haxe-expr
var x:MyHaxeType = #dummy expr/*...*/;
var xr = ammer.Lib.createHaxeRef(xr);
xr.incref();
Foobar.hello(xr);
xr.decref();
```
</div>

<!--label:definition-type-callbacks-->
### Callbacks

Callbacks allow native libraries to call Haxe code, for example, to invoke a handler when an event happens. Callbacks in C generally belong to two categories:

- Static callbacks — the native library stores a [function pointer](https://en.cppreference.com/w/c/language/pointer#Pointers_to_functions) directly.
- Callbacks with context — the native library stores a function pointer, as well as an additional `void*` value which is passed back to the function.

<!-- ### Static callbacks
### Callbacks with context (TODO?) -->

In `ammer`, a callback is declared using the `ammer.ffi.Callback<...>` type, which has 5 type parameters:

```haxe-type
ammer.ffi.Callback<
  CallbackType,
  FunctionType,
  CallTarget,
  CallArgs,
  Lib
>
```

The type parameters should be filled in as follows:

- `CallbackType` — The function type as seen by the native library.
- `FunctionType` — The function type as seen by Haxe.
- `CallTarget` — An expression (wrapped in square brackets) to reach the `void*` value representing the callback context, or `"global"`.
- `CallArgs` — An array of expressions representing the arguments to pass to the Haxe function.
- `Lib` — The parent `ammer` library.

It may be convenient to `typedef` callback types when referring to them within `ammer` definitions.

<div class="example">

### Example: declaring and using a callback type

Assuming a C library with the following implementation:

```c
// Type alias for the function type.
// It receives two integer arguments, in addition to the user-defined context.
int32_t (* callback_type)(int32_t, int32_t, void*);

static callback_type *stored_fptr = NULL;
static void *stored_context = NULL;

void store_callback(callback_type *fptr, void *call_context) {
  stored_fptr = fptr;
  stored_context = call_context;
}

int32_t invoke_callback(int32_t a, int32_t b) {
  return stored(a, b, stored_context);
}
```

The callback type can be reflected in `ammer` as follows:

```haxe
typedef CallbackType = ammer.ffi.Callback<
  (ammer.ffi.Int32, ammer.ffi.Int32, Haxe<(Int, Int)->Int>)->ammer.ffi.Int32,
  (Int, Int)->Int,
  [arg2],
  [arg0, arg1],
  Foobar
>;
```

Note that `[arg2]` refers to the third, `void*`-typed argument of `callback_type`, whereas `[arg0, arg1]` refer to the first two, `int`-typed arguments.

The `ammer` definition for the C library above may look like this:

```haxe
class Foobar extends ammer.def.Library<"foobar"> {
  public static function store_callback(_:CallbackType, _:ammer.ffi.Haxe<(Int, Int)->Int>):Void;
  public static function invoke_callback(_:ammer.ffi.Int32, _:ammer.ffi.Int32):ammer.ffi.Int32;
}
```

Finally, an example of using the library to invoke the callback:

```haxe-expr
var func = (a:Int, b:Int) -> { return a + b; };
var funcRef = ammer.Lib.createHaxeRef(func);
funcRef.incref();
Foobar.store_callback(funcRef);

// ...

trace(Foobar.invoke_callback(1, 2)); // 3
```

Note the use of `createHaxeRef`: `func` is an instance of a Haxe type, thus it must be wrapped with a reference counter as explained in the [Haxe types section](definition-type-haxe).
</div>

<!--label:definition-link-->
### Linking subdefinitions

In addition to [libraries](definition-library), `ammer` offers four kinds of "subdefinitions":

- [Sublibraries](definition-sub)
- [Opaque types](definition-type-opaque)
- [Structs](definition-type-struct)
- [Enums](definition-type-enum)

Each declaration declares a link to the parent library (e.g. `... extends ammer.Sublibrary<ParentLibrary>`). However, a corresponding backlink should also be declared on the parent library, using the [`@:ammer.sub`](ref-annot#sub) metadata. Although this declaration is optional (for the time being), it is recommended to avoid certain compilation errors, especially if the subdefinitions are declared in separate files. See [type cycles](advanced-cycles) for a technical explanation.

<div class="example">

### Example: linking a sublibrary

```haxe
// in file Foobar.hx
@:ammer.sub((_ : FoobarSub))
class Foobar extends ammer.def.Library<"foobar"> {}

// in file FoobarSub.hx
class FoobarSub extends ammer.def.Sublibrary<Foobar> {}
```

In this example, `Foobar` links to its sublibrary using the `@:ammer.sub` metadata. `FoobarSub` links to its parent library using the type parameter of `ammer.def.Sublibrary`.
</div>
