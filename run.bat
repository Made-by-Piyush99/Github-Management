@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   DevSync Studio - Desktop Git ^& GitHub Project Manager
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/3] Checking Python Backend Environment...
python -c "import sys; import backend.server; print('       Python Backend OK (v' + sys.version.split()[0] + ')')"
if errorlevel 1 (
    echo Error: Python environment check failed. Please ensure Python is installed with required packages.
    pause
    exit /b 1
)

echo [2/3] Setting Qt 6 ^& Application Environment...
set "PATH=C:\Qt\6.8.3\msvc2022_64\bin;%PATH%"

echo [3/3] Launching DevSync Studio (Backend running first, then UI)...
if exist "dist\DevSyncStudio\DevSyncStudio.exe" (
    start "" "dist\DevSyncStudio\DevSyncStudio.exe"
    echo App launched successfully from dist package!
    exit /b 0
)

if exist "build\DevSyncStudio.exe" (
    start "" "build\DevSyncStudio.exe"
    echo App launched successfully from build directory!
    exit /b 0
)

echo DevSyncStudio.exe not found! Building first...
call scripts\build.bat
if errorlevel 1 (
    echo Build failed.
    pause
    exit /b 1
)

start "" "build\DevSyncStudio.exe"
echo App launched successfully!
exit /b 0
