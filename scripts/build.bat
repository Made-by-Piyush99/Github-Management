@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo Building DevSync Studio (C++ / Qt 6 + Python Backend)
echo =======================================================

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 (
    echo Error: Failed to initialize MSVC 64-bit environment.
    exit /b 1
)

set "CMAKE_PREFIX_PATH=C:\Qt\6.8.3\msvc2022_64"
set "PATH=C:\Qt\6.8.3\msvc2022_64\bin;%PATH%"

if not exist build (
    mkdir build
)

cd build

echo Configuring CMake with Ninja generator...
cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release ..
if errorlevel 1 (
    echo Error: CMake configuration failed.
    exit /b 1
)

echo Building executable...
ninja
if errorlevel 1 (
    echo Error: Ninja build failed.
    exit /b 1
)

echo.
echo =======================================================
echo Build successful! Binary located at build\DevSyncStudio.exe
echo =======================================================
cd ..
