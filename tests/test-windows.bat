@echo off

echo "building native library ..."
cd native
nmake /f Makefile.win
cd ..

echo "testing hl ..."
haxe build-hl.hxml
if errorrlevel 0 (
    cd bin/hl
    cp ../../native/native.dll .
    hl test.hl
    cd ../..
)

echo "testing cpp ..."
haxe build-cpp.hxml
if errorrlevel 0 (
    cd bin/cpp
    cp ../../native/native.dll .
    ./Main
    cd ../..
)
