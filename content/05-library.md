<!--menu:Native library development-->
<!--label:library-->
# Native library development

<!--sublabel:library-tips-->
### General notes about dynamic libraries

If you are creating a native library from scratch, ensure that it is compiled as a dynamic library. See the sample project makefiles ([Windows](repo:samples/poc/native/Makefile.win), [OS X](repo:samples/poc/native/Makefile.osx), and [Linux](repo:samples/poc/native/Makefile.linux)) for the compiler configuration necessary to correctly produce a dynamic library (`.dll`, `.dylib`, and `.so`, respectively).

To actually use a dynamic library at run-time, it must be present in a place in which the OS will know to look. This differs from platform to platform:

 - Windows - DLLs in the current working directory will be used
 - OS X - the dynamic linker will look in `/usr/lib`, `/usr/local/lib`, paths specified in the environment variables `DYLD_LIBRARY_PATH`, `DYLD_FALLBACK_LIBRARY_PATH`, `DYLD_VERSIONED_LIBRARY_PATH`, the special `@executable_path`, and more (see  <https://www.mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html>)
   - during development, run the executable as `DYLD_LIBRARY_PATH=<path to where the .dylib is> <run project>`
 - Linux - the dynamic linker will look in `/usr/lib`, `/usr/local/lib`, paths specified in the environment variables `LD_LIBRARY_PATH`, and possibly more
   - during development, run the executable as `LD_LIBRARY_PATH=<path to where the .so is> <run project>`