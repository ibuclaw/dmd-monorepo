@echo off
set OLDHOME=%HOME%
set HOME=%CD%
make clean -fdmd-win32.mak
make release install -fdmd-win32.mak
make clean -fdmd-win32.mak
make debug install -fdmd-win32.mak
make clean -fdmd-win32.mak
set HOME=%OLDHOME%