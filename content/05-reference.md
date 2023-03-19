<!--menu:Reference-->
<!--label:ref-->
# Reference

### FFI types

Haxe types do not map one-to-one to C types. Types in the `ammer.ffi` package are used to provide additional context.

**Read on: [FFI types](ref-ffi)**

### `ammer.def.*` types

`ammer` definitions, such as [library definitions](definition), are declared as Haxe classes which extend one of the marker types in the `ammer.def` package.

**Read on: [`ammer.def.*` types](ref-def)**

### `ammer.Lib`

Client code using `ammer` libraries might need to perform operations which do not correspond to native library methods, but rather utility calls such as allocation.

**Read on: [`ammer.Lib`](ref-lib)**

### List of configuration flags

**Read on: [List of configuration flags](ref-flags)**

### List of annotations

**Read on: [List of annotations](ref-annot)**

<!--redirect:definition-ffi-->
<!--label:ref-ffi-->
## FFI types

This section summarises the types that can be used in [definitions](definition) for function signatures and field types. The types are split into multiple categories:

- [Primitive types](#primitive)
- [Library datatypes](#library)
- [Composed types](#composed)
- [Special types](#special)
- [Standard library types](#stdlib)

In each category, the table shows the following information:

- Description — What the type represents.
- Ammer type — How to write the type in definitions.
- Haxe call type — What the type will look like from a Haxe client of the `ammer` library.
- Haxe shortcut — Convenience alias for the type using an existing Haxe type, if any.
- C type — What the type maps to in a native library/in C language.

With a small number of exceptions, the `ammer.ffi.*` types exist solely for defining the types of a native library's functions or fields. When an `ammer` library is used from regular Haxe code, these types turn into a standard Haxe type, the conversion happens automatically. The exceptions are:

- `ammer.ffi.Array`
- `ammer.ffi.Box`
- `ammer.ffi.Bytes`
- `ammer.ffi.Haxe`

<!--sublabel:primitive-->
### Primitive types

| Description                      | Ammer type             | Haxe call type  | Haxe shortcut          | C type        |
| -------------------------------- | ---------------------- | --------------- | ---------------------- | ------------- |
| Void                             | `ammer.ffi.Void`       | `Void`          | `Void`                 | `void`        |
| Boolean                          | `ammer.ffi.Bool`       | `Bool`          | `Bool`                 | `bool`        |
| Unsigned 8-bit integer           | `ammer.ffi.UInt8`      | `UInt`          | -                      | `uint8_t`     |
| Unsigned 16-bit integer          | `ammer.ffi.UInt16`     | `UInt`          | -                      | `uint16_t`    |
| Unsigned 32-bit integer          | `ammer.ffi.UInt32`     | `UInt`          | `UInt`                 | `uint32_t`    |
| Unsigned 64-bit integer          | `ammer.ffi.UInt64`     | `UInt`          | -                      | `uint64_t`    |
| Signed 8-bit integer             | `ammer.ffi.Int8`       | `Int`           | -                      | `int8_t`      |
| Signed 16-bit integer            | `ammer.ffi.Int16`      | `Int`           | -                      | `int16_t`     |
| Signed 32-bit integer            | `ammer.ffi.Int32`      | `Int`           | `Int`                  | `int32_t`     |
| Signed 64-bit integer            | `ammer.ffi.Int64`      | `Int`           | `haxe.Int64`           | `int64_t`     |
| Single-precision IEEE 754 number | `ammer.ffi.Float32`    | `Single` [<sup>1</sup>](#fn-single) | `Single` [<sup>1</sup>](#fn-single) | `float`       |
| Double-precision IEEE 754 number | `ammer.ffi.Float64`    | `Float`         | `Float`                | `double`      |
| String                           | `ammer.ffi.String`     | `String`        | `String`               | `const char*` |

<!--sublabel:fn-single-->
<!--titleplain:Footnote 1: Single-->
#### <sup>1</sup>: `Single`

`Single` is only available on some Haxe targets. When a `Float32` is used on a target that does not natively support single-precision floating-points, a lossy conversion is used from 64 bits.

<!--sublabel:library-->
### Library datatypes

| Description                    | Ammer type             | Haxe shortcut          | C type        |
| ------------------------------ | ---------------------- | ---------------------- | ------------- |
| Opaque pointer, struct pointer | -                      | `T extends Struct ...` | `(type)*`     |
| Opaque data, struct            | [`ammer.ffi.Deref<T>`](definition-type-struct#deref) | `T extends Struct ...` | `(type)`      |
| Opaque data, struct            | [`ammer.ffi.Alloc<T>`](definition-type-struct#deref) | `T extends Struct ...` | `(type)`      |
| Haxe object                    | [`ammer.ffi.Haxe<T>`](definition-type-haxe) | `T`                    | `void*`       |

<!--sublabel:composed-->
### Composed types

| Description        | Ammer type                | Haxe shortcut       | C type        |
| ------------------ | ------------------------- | ------------------- | ------------- |
| A contiguous array | `ammer.ffi.Array<T>`      | -                   | `(type)*`     |
| Box                | `ammer.ffi.Box<T>`        | -                   | `(type)*`     |
| Callback           | [`ammer.ffi.Callback<...>`](definition-type-callbacks) | -                   | -             |

<!--sublabel:special-->
### Special/marker types

| Ammer type                   | Meaning |
| ---------------------------- | ------- |
| `ammer.ffi.This`             | Stands for the current struct instance, see [instance methods](definition-type-instance) |
| `ammer.ffi.Unsupported<...>` | An unsupported type: the type parameter (a string constant) will be passed to native calls. |

<!--sublabel:stdlib-->
### Standard library types

| Description  | Ammer type          | C type  |
| ------------ | ------------------- | ------- |
| File pointer | `ammer.ffi.FilePtr` | `FILE*` |

<!--menu:<code>ammer.def.*</code> types-->
<!--titleplain:ammer.def.* types-->
<!--label:ref-def-->
## `ammer.def.*` types

The types in the `ammer.def` package are all "marker" types: the types themselves have no meaning and should not be used directly, but they are used as super types for `ammer` definitions. Any Haxe class that extends one of the types below will be processed by `ammer`.

<!--sublabel:parent-->
<!--titleplain:About the parent:Lib type parameter-->
### About the `parent:Lib` type parameter

The types listed below are written with `parent:Lib` as a type parameter. This indicates that the type parameter should be filled in with the type name of a type that itself extends `ammer.def.Library`. This indicates that the given type is the "parent" of the one being declared. See [linking subdefinitions](definition-link).

---

<!--sublabel:library-->
<!--titleplain:ammer.def.Library-->
### `ammer.def.Library<id:String>`

Library definition. See [library definition](definition-library) for examples.

#### Type parameters

- `id:String` — The identifier used for this library. This identifier is used in the [library configuration](configuration-library), so it must only consist of letters and underscores. It must be unique.

#### Allowed fields

- [Static methods](definition-library-functions)
- [Static variables](definition-library-variables)
- [Static constants](definition-library-variables#constants)

#### Applicable metadata

<!--include:meta-library-->

---

<!--sublabel:opaque-->
<!--titleplain:ammer.def.Opaque-->
### `ammer.def.Opaque<type:String, parent:Lib>`

Opaque type definition. See [opaque type definition](definition-type-opaque) for examples.

#### Type parameters

- `type:String` — The C name of this opaque type. This can be any valid C type declaration, which may contain spaces or asterisks.
- `parent:Lib` — [parent library](ref-def#parent).

#### Allowed fields

- [Instance methods](definition-type-instance)

#### Applicable metadata

<!--include:meta-opaque-->

---

<!--sublabel:struct-->
<!--titleplain:ammer.def.Struct-->
### `ammer.def.Struct<type:String, parent:Lib>`

Struct definition. See [struct definition](definition-type-struct) for examples.

#### Type parameters

- `type:String` — The C name of this struct. This can be any valid C type declaration, which may contain spaces or asterisks. Note that although the type that extends `ammer.def.Struct` [represents a pointer to the struct](definition-type-struct#pointer), the final asterisk should not be written in this type parameter.
- `parent:Lib` — [parent library](ref-def#parent).

#### Allowed fields

- [Instance methods](definition-type-instance)
- [Variables](definition-type-struct#variables)

#### Applicable metadata

<!--include:meta-struct-->

---

<!--sublabel:sublibrary-->
<!--titleplain:ammer.def.Sublibrary-->
### `ammer.def.Sublibrary<parent:Lib>`

Sublibrary definition. See [sublibrary definition](definition-sub) for examples.

#### Type parameters

- `parent:Lib` — [parent library](ref-def#parent).

#### Allowed fields

- [Static methods](definition-library-functions)
- [Static variables](definition-library-variables)
- [Static constants](definition-library-variables#constants)

#### Applicable metadata

<!--include:meta-sublibrary-->

<!--menu:<code>ammer.Lib</code>-->
<!--titleplain:ammer.Lib-->
<!--label:ref-lib-->
## `ammer.Lib`

The `ammer.Lib` type provides a number of methods for client interaction with `ammer` libraries. These methods are (by necessity) `macro` methods. As a result, their signatures displayed below are only approximations.

---

<!--sublabel:allocstruct-->
<!--titleplain:ammer.Lib.allocStruct method-->
### `ammer.Lib.allocStruct(type:Class<Struct>, ?initialValues:{ ... }):Struct`

Allocates a struct of the given type, optionally assigning the given initial values to its fields. The type must be [annotated](definition-type-struct#alloc) with the [`@:ammer.alloc`](ref-annot#alloc) metadata.

#### Arguments

- `type` — The name (or full path) of the type to allocate.
- `initialValues` — An [object literal](https://haxe.org/manual/expression-object-declaration.html) where the keys and values correspond to fields and their initial values, respectively.

---

<!--sublabel:createhaxeref-->
<!--titleplain:ammer.Lib.createHaxeRef method-->
### `ammer.Lib.createHaxeRef(type:Class<T>, value:T):ammer.ffi.Haxe<T>`

Creates a reference to the given Haxe value. See [Haxe types](definition-type-haxe).

#### Arguments

- `type` — The name (or full path) of the Haxe type. This is required to make sure there are no unexpected type mismatch problems e.g. when passing references to [anonymous structures](https://haxe.org/manual/types-anonymous-structure.html).
- `value` — The Haxe value to create a reference to.

---

<!--sublabel:freestruct-->
<!--titleplain:ammer.Lib.freeStruct method-->
### `ammer.Lib.freeStruct(instance:Struct):Void`

Deallocates the given pointer. The type must be [annotated](definition-type-struct#alloc) with the [`@:ammer.alloc`](ref-annot#alloc) metadata.

#### Arguments

- `instance` — The value to deallocate.

---

<!--sublabel:nullptrstruct-->
<!--titleplain:ammer.Lib.nullPtrStruct method-->
### `ammer.Lib.nullPtrStruct(type:Class<Struct>):Struct`

Returns a null pointer of the given type.

#### Arguments

- `type` — The name (or full path) of the type.

<!-- TODO: rest of functions -->

<!--redirect:definition-metadata-->
<!--label:ref-flags-->
## List of configuration flags

Note that the `_` after `lib.` in all the names below should be replaced by the [identifier](definition-library) of the library.

- [`ammer.buildPath`](#buildpath)
- [`ammer.debug`](#debug)
- [`ammer.outputPath`](#outputpath)
- [`ammer.lib._.defines`](#lib.defines)
- [`ammer.lib._.frameworks`](#lib.frameworks)
- [`ammer.lib._.headers.includes`](#lib.headers)
- [`ammer.lib._.includePaths`](#lib.includepaths)
- [`ammer.lib._.language`](#lib.language)
- [`ammer.lib._.libraryPaths`](#lib.librarypaths)
- [`ammer.lib._.linkNames`](#lib.linknames)

---

<!--sublabel:buildpath-->
<!--titleplain:ammer.buildPath-->
### `ammer.buildPath:String`

Path used for intermediate build artefacts. These include the C glue code generated by `ammer`, as well as compiled binary objects, before they are packaged into dynamic libraries. See [paths](configuration-project#paths).

#### Compile-time defines

- `-D ammer.buildPath=(string)` — sets the build path.

---

<!--sublabel:debug-->
<!--titleplain:ammer.debug-->
### `ammer.debug:String`

Sets the [debug mode](configuration-project#debug) for `ammer`. The value is a comma-separated list of categories of debug messages to show. The available categories are:

- `stage`
- `stage-ffi`

The flag can be set to the string `all` to enable all of the above.

#### Compile-time defines

- `-D ammer.debug=(comma-separated list)` — sets the debug mode.

---

<!--sublabel:outputpath-->
<!--titleplain:ammer.outputPath-->
### `ammer.outputPath:String`

Path used for final build products. These are dynamic libraries compiled by `ammer` that would typically be deployed with the program using them. See [paths](configuration-project#paths).

#### Compile-time defines

- `-D ammer.outputPath=(string)` — sets the output path.

---

<!--sublabel:lib.defines-->
<!--titleplain:ammer.lib._.defines-->
### `ammer.lib._.defines:Array<String>`

List of C preprocessor directives to set when compiling the library.

#### Compile-time defines

- `-D ammer.lib._.define=(string)` — adds one entry to the list.
- `-D ammer.lib._.defines=(comma-separated list)` — adds multiple entries to the list.

#### Metadata (on a library definition)

- `@:ammer.lib.define(define:String)` — adds one entry to the list.
- `@:ammer.lib.defines(defines:Array<String>)` — adds multiple entries to the list.

---

<!--sublabel:lib.frameworks-->
<!--titleplain:ammer.lib._.frameworks-->
### `ammer.lib._.frameworks:Array<String>`

List of [frameworks](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/WhatAreFrameworks.html) to use when compiling the library. Only has an effect on macOS.

#### Compile-time defines

- `-D ammer.lib._.framework=(string)` — adds one entry to the list.
- `-D ammer.lib._.frameworks=(comma-separated list)` — adds multiple entries to the list.

#### Metadata (on a library definition)

- `@:ammer.lib.framework(framework:String)` — adds one entry to the list.
- `@:ammer.lib.frameworks(frameworks:Array<String>)` — adds multiple entries to the list.

---

<!--sublabel:lib.headers-->
<!--titleplain:ammer.lib._.headers.includes-->
### `ammer.lib._.headers.includes:Array<SourceInclude>`

List of headers to include when compiling the library. There are four different include styles:

- `IncludeLocal` — `#include "header.h"`
- `IncludeGlobal` — `#include <header.h>`
- `ImportLocal` — `#import "header.h"`
- `ImportGlobal` — `#import <header.h>`

### Compile-time defines

- `-D ammer.lib._.headers=(comma-separated list)` — adds multiple entries to the list, as `IncludeLocal`s.
- `-D ammer.lib._.headers.includeLocal=(string)` — adds one entry to the list, as `IncludeLocal`.
- `-D ammer.lib._.headers.includeGlobal=(string)` — adds one entry to the list, as `IncludeGlobal`.
- `-D ammer.lib._.headers.importLocal=(string)` — adds one entry to the list, as `ImportLocal`.
- `-D ammer.lib._.headers.importGlobal=(string)` — adds one entry to the list, as `ImportGlobal`.

### Metadata (on a library definition)

- `@:ammer.lib.headers.include(header:String)` — adds one entry to the list, as `IncludeLocal`.
- `@:ammer.lib.headers.import(header:String)` — adds one entry to the list, as `ImportLocal`.
- `@:ammer.lib.headers.includeLocal(header:String)` — adds one entry to the list, as `IncludeLocal`.
- `@:ammer.lib.headers.includeGlobal(header:String)` — adds one entry to the list, as `IncludeGlobal`.
- `@:ammer.lib.headers.importLocal(header:String)` — adds one entry to the list, as `ImportLocal`.
- `@:ammer.lib.headers.importGlobal(header:String)` — adds one entry to the list, as `ImportGlobal`.

---

<!--sublabel:lib.includepaths-->
<!--titleplain:ammer.lib._.includePaths-->
### `ammer.lib._.includePaths:Array<String>`

Paths to provide to the C compiler as "include paths", which are used when searching for header files.

### Compile-time defines

- `-D ammer.lib._.includePaths=(comma-separated list)` — adds multiple entries to the list.

### Metadata (on a library definition)

- `@:ammer.lib.includePath(path:String)` — adds one entry to the list.
- `@:ammer.lib.includePaths(paths:Array<String>)` — adds multiple entries to the list.

---

<!--sublabel:lib.language-->
<!--titleplain:ammer.lib._.language-->
### `ammer.lib._.language:LibraryLanguage`

Specifies the language of the native library. This language is also used for generating the glue code. Possible values:

- `C` - C
- `Cpp` - C++
- `ObjC` - Objective-C
- `ObjCpp` - Objective-C++

### Compile-time defines

- `-D ammer.lib._.language=(string)` — sets the language.

### Metadata (on a library definition)

- `@:ammer.lib.language(language:LibraryLanguage)` — sets the language.

---

<!--sublabel:lib.librarypaths-->
<!--titleplain:ammer.lib._.libraryPaths-->
### `ammer.lib._.libraryPaths:Array<String>`

Paths to provide to the C compiler (more accurately, the linker) as "library paths", which are used when searching for library files (`.dll`, `.dylib`, `.so` files).

### Compile-time defines

- `-D ammer.lib._.libraryPaths=(comma-separated list)` — adds multiple entries to the list.

### Metadata (on a library definition)

- `@:ammer.lib.libraryPath(path:String)` — adds one entry to the list.
- `@:ammer.lib.libraryPaths(paths:Array<String>)` — adds multiple entries to the list.

---

<!--sublabel:lib.linknames-->
<!--titleplain:ammer.lib._.linkNames-->
### `ammer.lib._.linkNames:Array<String>`

Names of libraries to link against when compiling this native library. Should not include prefixes such as `-l` or `lib`.

### Compile-time defines

- `-D ammer.lib._.linkNames=(comma-separated list)` — adds multiple entries to the list.

### Metadata (on a library definition)

- `@:ammer.lib.linkName(path:String)` — adds one entry to the list.
- `@:ammer.lib.linkNames(paths:Array<String>)` — adds multiple entries to the list.

<!--label:ref-annot-->
## List of annotations

Metadata which do not correspond to a [configuration flag](ref-flags) are listed here.

- [`@:ammer.alloc`](#alloc)
- [`@:ammer.c.cast`](#c.cast)
- [`@:ammer.c.macroCall`](#c.macrocall)
- [`@:ammer.c.prereturn`](#c.prereturn)
- [`@:ammer.c.return`](#c.return)
- [`@:ammer.derive`](#derive)
- [`@:ammer.gen.alloc`](#gen.alloc)
- [`@:ammer.gen.free`](#gen.free)
- [`@:ammer.gen.nullPtr`](#gen.nullptr)
- [`@:ammer.haxe`](#haxe)
- [`@:ammer.native`](#native)
- [`@:ammer.nativePrefix`](#nativeprefix)
- [`@:ammer.ret.derive`](#ret.derive)
- [`@:ammer.skip`](#skip)
- [`@:ammer.sub`](#sub)

---

<!--sublabel:alloc-->
<!--titleplain:@:ammer.alloc-->
### `@:ammer.alloc`

Allows allocation and deallocation of the annotated [struct type](definition-type-struct) using [`ammer.Lib.allocStruct`](ref-lib#allocstruct) and [`ammer.Lib.freeStruct`](ref-lib#freestruct), respectively. See [allocation and deallocation](definition-type-struct#alloc).

---

<!--sublabel:c.cast-->
<!--titleplain:@:ammer.c.cast-->
### `@:ammer.c.cast(type:String)`

Marks that the annotated argument should be cast to the given C type before being passed to the native call.

---

<!--sublabel:c.macrocall-->
<!--titleplain:@:ammer.c.macroCall-->
### `@:ammer.c.macroCall`

(Alias: `@:ammer.macroCall`)

Marks the annotated function as a macro call. See [macro calls](definition-library-functions#macros).

---

<!--sublabel:c.prereturn-->
<!--titleplain:@:ammer.c.prereturn-->
### `@:ammer.c.prereturn(code:String)`

Adds the given C code into the native function, before the return expression. The arguments to the native call are available in the `_arg0`, ..., `_argN` local variables. See [customising the C code](definition-library-functions#custom-c).

---

<!--sublabel:c.return-->
<!--titleplain:@:ammer.c.return-->
### `@:ammer.c.return(code:String)`

Uses the given C expression instead of the return expression. The arguments to the native call are available in the `_arg0`, ..., `_argN` local variables. The string `%CALL%`, if used in `code`, will be replaced with the original return expression. See [customising the C code](definition-library-functions#custom-c).

---

<!--sublabel:derive-->
<!--titleplain:@:ammer.derive-->
### `@:ammer.derive(e:Expr)`

---

<!--sublabel:gen.alloc-->
<!--titleplain:@:ammer.gen.alloc-->
### `@:ammer.gen.alloc(name:String)`

Specifies the name for the generated static allocation function. See [allocation and deallocation](definition-type-struct#alloc).

---

<!--sublabel:gen.free-->
<!--titleplain:@:ammer.gen.free-->
### `@:ammer.gen.free(name:String)`

Specifies the name for the generated instance deallocation function. See [allocation and deallocation](definition-type-struct#alloc).

---

<!--sublabel:gen.nullptr-->
<!--titleplain:@:ammer.gen.nullPtr-->
### `@:ammer.gen.nullPtr(name:String)`

Specifies the name for the generated static null pointer function. See [allocation and deallocation](definition-type-struct#alloc).

---

<!--sublabel:haxe-->
<!--titleplain:@:ammer.haxe-->
### `@:ammer.haxe`

Allows the annotated function to have a Haxe body, skipping `ammer` processing. See [pure Haxe functions](definition-library-functions#pure-haxe).

---

<!--sublabel:native-->
<!--titleplain:@:ammer.native-->
### `@:ammer.native(name:String)`

Specifies the native name of the annotated function or field.

---

<!--sublabel:nativeprefix-->
<!--titleplain:@:ammer.nativePrefix-->
### `@:ammer.nativePrefix(prefix:String)`

Specifies the prefix for native names. The native name will be derived as "prefix" + "the field name", unless overridden on the field itself with [`@:ammer.native`](#native).

---

<!--sublabel:ret.derive-->
<!--titleplain:@:ammer.ret.derive-->
### `@:ammer.ret.derive(e:Expr, ct:Type)`

---

<!--sublabel:skip-->
<!--titleplain:@:ammer.skip-->
### `@:ammer.skip`

Marks the given function argument to be skipped for the underlying native call.

---

<!--sublabel:sub-->
<!--titleplain:@:ammer.sub-->
### `@:ammer.sub(sub:Type)`

Marks the given type `sub` as a "subdefinition" of the annotated library. See [linking subdefinitions](definition-link).
