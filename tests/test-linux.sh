#!/bin/bash

echo "building native library ..."
(cd native; make -f Makefile.linux)

echo "testing hl ..."
haxe build-hl.hxml \
&& (cd bin/hl; LD_LIBRARY_PATH=../../native hl test.hl)

echo "testing cpp ..."
haxe build-cpp.hxml \
&& (cd bin/cpp; LD_LIBRARY_PATH=../../native ./Main)

echo "testing eval ..."
LD_LIBRARY_PATH=native haxe -D "ammer.eval.hxDir=$TEST_HXDIR" build-eval.hxml
