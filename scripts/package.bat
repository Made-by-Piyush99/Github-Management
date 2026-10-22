@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo Packaging DevSync Studio for Windows Desktop
echo =======================================================

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=C:\Qt\6.8.3\msvc2022_64\bin;%PATH%"

if not exist build\DevSyncStudio.exe (
    echo Error: build\DevSyncStudio.exe not found. Run scripts\build.bat first.
    exit /b 1
)

set "DIST_DIR=dist\DevSyncStudio"
if exist "%DIST_DIR%" (
    rmdir /s /q "%DIST_DIR%"
)
mkdir "%DIST_DIR%"

echo Copying executable...
copy build\DevSyncStudio.exe "%DIST_DIR%\"

echo Deploying backend files...
xcopy /E /I /Y backend "%DIST_DIR%\backend"

echo Running windeployqt to copy required Qt 6 DLLs and QML plugins...
windeployqt --qmldir ui "%DIST_DIR%\DevSyncStudio.exe"

echo.
echo =======================================================
echo Packaging complete!
echo Standalone distribution package ready at: %DIST_DIR%
echo =======================================================
