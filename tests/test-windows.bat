rem @echo off

echo "building native library ..."
cd native
nmake /f Makefile.win
cd ..

echo "testing hl ..."
haxe build-hl.hxml
if errorrlevel 0 (
    cd bin/hl
    copy ../../native/native.dll .
    hl test.hl
    cd ../..
)

echo "testing cpp ..."
haxe build-cpp.hxml
if errorrlevel 0 (
    cd bin/cpp
    copy ../../native/native.dll .
    ./Main
    cd ../..
)

echo "testing eval ..."
copy native/native.dll .
haxe -D ammer.eval.hxDir=%TEST_HXDIR% build-cpp.hxml
