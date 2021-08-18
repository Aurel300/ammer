@echo off


echo "building native library ..."
cd native
nmake /f Makefile.win
cd ..


echo "testing hl ..."
haxe -D ammer.hl.hlInclude=%HLPATH%/include -D ammer.hl.hlLibrary=%HLPATH% build-hl.hxml
IF %ERRORLEVEL% NEQ 0 ( echo "build of hl tests failed" && goto :cpp)
pushd bin\hl
copy ..\..\native\native.dll .
hl test.hl
popd
IF %ERRORLEVEL% NEQ 0 ( echo "hl tests failed" && goto :cpp)


:cpp

echo "testing cpp ..."
rd /q /s bin\cpp

haxe build-cpp.hxml
IF %ERRORLEVEL% NEQ 0 ( echo "build of cpp tests failed" && goto :eval)

cd bin\cpp
copy ..\..\native\native.dll .
Main.exe
IF %ERRORLEVEL% NEQ 0 ( echo "cpp tests failed" && goto :eval)
cd ../..

:eval

echo "testing eval ..."
copy native\native.dll .
haxe -D ammer.eval.haxeDir=%HAXEPATH% build-eval.hxml
IF %ERRORLEVEL% NEQ 0 ( echo "eval tests failed")
