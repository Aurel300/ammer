<!--menu:<code>ammer-core</code>-->
<!--titleplain:ammer-core-->
<!--label:core-->
# `ammer-core`


(TODO: expand, rewrite, etc)

## When implementing a new platform

- decide on the full name and an identifier, e.g.
  - `Neko`, `neko`
  - `Hashlink`, `hl`
  - `Cpp`, `cpp-static` - there can be subplatforms
- copy `ammer/core/plat/None.hx` to `ammer/core/plat/<Name>.hx`
- edit `ammer/core/plat/<Name>.hx`, see below
- edit `core/*.hx` where there are platform-based switches

### Implementing the platform file

- start with outputting any glue code (C)
- implement `addNamedFunction` with dummy arguments
- implement types in `Marshal`, enabling tests one at a time:
  - booleans, `TestBools.hx`
- finish the build program to link
  - integers, `TestIntegers.hx`
  - floats, `TestFloats.hx`
  - opaques, part of `TestStructs.hx`
  - structs, rest of `TestStructs.hx`
  - bytes, `TestBytes.hx`
  - arrays, Haxe values, callbacks ...
- configuration

