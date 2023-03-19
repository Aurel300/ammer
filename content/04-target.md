<!--menu:Target details-->
<!--label:target-->
# Target details

`ammer` aims to support all Haxe [`sys` targets](https://haxe.org/manual/std-sys.html), including Javascript compiled with [`hxnodejs`](https://github.com/HaxeFoundation/hxnodejs), but excluding PHP. 

## Feature parity

Each `ammer` target supports the same set of features, unless otherwise noted.

**Read on: [Feature parity](target-feature-parity)**

## Target-specific information

The rest of this chapter contains information on how each target should be used, its configuration flags, etc.

**Read on:**

- [C++](target-hxcpp)
- [C#](target-cs)
- [Eval](target-eval)
- [HashLink](target-hashlink) (both JIT and HL/C)
- [Java](target-java) (both Java and JVM)
- [Lua](target-lua)
- [Neko](target-neko)
- [Node.js](target-nodejs)
- [Python](target-python)

<!--label:target-feature-parity-->
## Feature parity

<!--sublabel:shared-buffers-->
### Shared buffers

Since each `ammer` target has a different runtime with different internal representations of core types such as `haxe.io.Bytes`, some targets do not support directly sharing memory between Haxe code and native code.

In the target summaries in the remaining sections, "Shared buffers" is one of the following:

- Yes - `haxe.io.Bytes` can be passed directly (without copying) to the native library as a byte pointer and vice versa.
- From Haxe to native only - `haxe.io.Bytes` can be passed directly (without copying) to the native library as a byte pointer but a native byte pointer cannot be used as a `haxe.io.Bytes` value.
- No - `haxe.io.Bytes` must always be copied to get a byte pointer.

<!-- TODO: examples (Bytes, Vector) -->

<!--sublabel:shared-vectors-->
### Shared vectors

In the target summaries in the remaining sections, "Shared vectors" is one of the following:

- Yes - `haxe.ds.Vector` can be passed directly (without copying) to the native library as a pointer and vice versa.
- From Haxe to native only - `haxe.ds.Vector` can be passed directly (without copying) to the native library as a pointer but a native pointer cannot be used as a `haxe.ds.Vector` value.
- No - `haxe.ds.Vector` must always be copied to get a pointer.

<!-- TODO: entrypoints -->

<!--label:target-hxcpp-->
## C++

### Target summary

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | Yes |
| [Shared vectors](target-feature-parity#shared-vectors) | Yes |

### Configuration flags

- [`ammer.cpp.staticLink`](#flag-staticlink)

---

<!--sublabel:flag-staticlink-->
<!--titleplain:ammer.cpp.staticLink-->
### `ammer.cpp.staticLink:Bool`

Defaults to `true`. Note that dynamic linking on C++ is planned, but not yet implemented.

<!--label:target-cs-->
## C#

### Target summary

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | From Haxe to native only |
| [Shared vectors](target-feature-parity#shared-vectors) | From Haxe to native only |

### Configuration flags

(no additional flags)

<!--label:target-eval-->
## Eval

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | No |
| [Shared vectors](target-feature-parity#shared-vectors) | No |

### Configuration flags

(no additional flags)
<!-- TODO: haxe repo path flag -->

<!--label:target-hashlink-->
## HashLink

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | Yes |
| [Shared vectors](target-feature-parity#shared-vectors) | Yes |

### Configuration flags

- [`ammer.hl.includePaths`](#flag-includepaths)
- [`ammer.hl.libraryPaths`](#flag-librarypaths)

---

<!--sublabel:flag-includepaths-->
<!--titleplain:ammer.hl.includePaths-->
### `ammer.hl.includePaths:Array<String>`

---

<!--sublabel:flag-librarypaths-->
<!--titleplain:ammer.hl.libraryPaths-->
### `ammer.hl.libraryPaths:Array<String>`

<!--label:target-java-->
## Java

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | From Haxe to native only |
| [Shared vectors](target-feature-parity#shared-vectors) | From Haxe to native only |

### Configuration flags

- [`ammer.java.includePaths`](#flag-includepaths)
- [`ammer.java.libraryPaths`](#flag-librarypaths)

---

<!--sublabel:flag-includepaths-->
<!--titleplain:ammer.java.includePaths-->
### `ammer.java.includePaths:Array<String>`

---

<!--sublabel:flag-librarypaths-->
<!--titleplain:ammer.java.libraryPaths-->
### `ammer.java.libraryPaths:Array<String>`

<!--label:target-lua-->
## Lua

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | No |
| [Shared vectors](target-feature-parity#shared-vectors) | No |

### Configuration flags

- [`ammer.lua.includePaths`](#flag-includepaths)
- [`ammer.lua.libraryPaths`](#flag-librarypaths)

---

<!--sublabel:flag-includepaths-->
<!--titleplain:ammer.lua.includePaths-->
### `ammer.lua.includePaths:Array<String>`

---

<!--sublabel:flag-librarypaths-->
<!--titleplain:ammer.lua.libraryPaths-->
### `ammer.lua.libraryPaths:Array<String>`

<!--label:target-neko-->
## Neko

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | From Haxe to native only |
| [Shared vectors](target-feature-parity#shared-vectors) | No |

### Configuration flags

- [`ammer.neko.includePaths`](#flag-includepaths)
- [`ammer.neko.libraryPaths`](#flag-librarypaths)

---

<!--sublabel:flag-includepaths-->
<!--titleplain:ammer.neko.includePaths-->
### `ammer.neko.includePaths:Array<String>`

---

<!--sublabel:flag-librarypaths-->
<!--titleplain:ammer.neko.libraryPaths-->
### `ammer.neko.libraryPaths:Array<String>`

<!--label:target-nodejs-->
## Node.js

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | Yes |
| [Shared vectors](target-feature-parity#shared-vectors) | No |

### Configuration flags

- [`ammer.js.nodeGypBinary`](#flag-nodegypbinary)

---

<!--sublabel:flag-nodegypbinary-->
<!--titleplain:ammer.js.nodeGypBinary-->
### `ammer.js.nodeGypBinary:String`

<!--label:target-python-->
## Python

| Feature | Status |
| ------- | ------ |
| [Shared buffers](target-feature-parity#shared-buffers) | From Haxe to native only |
| [Shared vectors](target-feature-parity#shared-vectors) | No |

### Configuration flags

- [`ammer.python.version`](#flag-version)
- [`ammer.python.includePaths`](#flag-includepaths)
- [`ammer.python.libraryPaths`](#flag-librarypaths)

---

<!--sublabel:flag-version-->
<!--titleplain:ammer.python.version-->
### `ammer.python.version:Int`

---

<!--sublabel:flag-includepaths-->
<!--titleplain:ammer.python.includePaths-->
### `ammer.python.includePaths:Array<String>`

---

<!--sublabel:flag-librarypaths-->
<!--titleplain:ammer.python.libraryPaths-->
### `ammer.python.libraryPaths:Array<String>`
