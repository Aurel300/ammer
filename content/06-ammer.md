<!--menu:Implementation details-->
<!--label:ammer-->
# Implementation details

<!--label:ammer-testing-->
## Testing

A suite of unit tests is provided in the [`tests`](repo:tests/) directory. There is a script provided for each OS ([`test-windows.bat`](repo:tests/test-windows.bat), [`test-osx.sh`](repo:tests/test-osx.sh), [`test-linux.sh`](repo:tests/test-linux.sh)), which:

 - compiles a native library
 - compiles Haxe with HashLink
   - if successful, runs the tests
 - compiles Haxe with hxcpp
   - if successful, runs the tests

<!--label:ammer-stages-->
## Compilation stages

External libraries are built in up to four separate stages:

 - FFI type processing - common to all targets, runs once per library. In this stage, the special [FFI types](definition-ffi) are checked. See [`ammer.Ammer.createFFIMethod`](repo:src/ammer/Ammer.hx).
 - Stub creation - target-specifc, runs once per library. In this stage, files containing the FFI stubs are created for the library if they are needed. See [`ammer.stub`](repo:src/ammer/stub/).
 - Type patching - target-specific, runs once per library. In this stage, an `extern class` containing the native or FFI-linked methods is defined, and the methods of the original class are rewritten to map Haxe types to the target-specific ones and vice versa. See [`ammer.patch`](repo:src/ammer/patch/).
 - Build - target-specific, runs once per project. In this stage, the stubs for all the libraries are compiled if needed. See [`ammer.build`](repo:src/ammer/build/).
