#!/bin/bash

echo "building native library ..."
(cd native; make -f Makefile.osx)

echo "testing hl ..."
haxe build-hl.hxml \
&& (cd bin/hl; DYLD_LIBRARY_PATH=../../native hl test.hl)

echo "testing cpp ..."
haxe build-cpp.hxml \
&& (cd bin/cpp; DYLD_LIBRARY_PATH=../../native ./Main)

echo "testing eval ..."
DYLD_LIBRARY_PATH=native haxe -D "ammer.eval.haxeDir=$TEST_HXDIR" build-eval.hxml
