<!--menu:Advanced topics-->
<!--label:advanced-->
# Advanced topics

<!--label:advanced-cycles-->
## Type cycles

In [linking subdefinitions](definition-link), it is recommended to link any library to all of its subdefinitions using the [`@:ammer.sub`](ref-annot#sub) metadata. Why is this necessary?

Consider the following types:

```haxe
// in file Foobar.hx
@:ammer.sub((_ : FoobarStruct))
@:ammer.sub((_ : FoobarSub))
class Foobar extends ammer.def.Library<"foobar"> {
  public static function some_function():FoobarStruct;
}

// in file FoobarStruct.hx
class FoobarStruct extends ammer.def.Struct<"foobar_t", Foobar> {
  // ...
}

// in file FoobarSub.hx
class FoobarSub extends ammer.def.Sublibrary<Foobar> {
  public static function another_function():Void;
}
```

Between `Foobar` and `FoobarSub`, there is a two-way link:

- `@:ammer.sub((_ : FoobarSub))` — Links the library to the subdefinition.
- `... extends ammer.def.Sublibrary<Foobar>` — Links the subdefinition to the library.

If the `@:ammer.sub((_ : FoobarSub))` annotation was omitted, then the following client code could cause a compilation failure:

```haxe-expr
Foobar.some_function();
FoobarSub.another_function();
```

This is because Haxe performs typing on demand: the `Foobar` module (in the file `Foobar.hx`) is not discovered and typed until the first time it is needed. This can happen if a type (and its static method) declared in that module is used, as in the first line.

However, `Foobar` is not a regular Haxe type: it is an `ammer`-annotated library definition. When an `ammer` library is typed, the following steps take place (simplified):

- A library context is established, containing the library configuration etc.
- All fields of the library are eagerly typed. This may trigger transitive typing. In the example above, this leads Haxe to discover the `FoobarStruct` type, because it is used as the return type of one of the methods of `Foobar`.
- The library is finalised by writing the required glue code into a file, which will later be compiled by a C compiler.

Without the `@:ammer.sub((_ : FoobarSub))` annotation on `Foobar`, the first line of the client only causes the Haxe compiler to discover `Foobar` and `FoobarStruct`. When typing the second line (the call to `FoobarSub.another_function`), `FoobarSub` is discovered, but it cannot be added to `Foobar` anymore: the library was finalised and the glue code was already generated.

The safe recommendation is therefore to always use [`@:ammer.sub`](ref-annot#sub), even when other fields would cause the Haxe compiler to discover the subdefinitions.
