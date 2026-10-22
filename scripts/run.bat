@echo off
setlocal

set "PATH=C:\Qt\6.8.3\msvc2022_64\bin;%PATH%"

if exist "dist\DevSyncStudio\DevSyncStudio.exe" (
    echo Launching packaged DevSync Studio...
    start "" "dist\DevSyncStudio\DevSyncStudio.exe"
    exit /b 0
)

if not exist build\DevSyncStudio.exe (
    echo Executable not found. Running build first...
    call scripts\build.bat
    if errorlevel 1 exit /b 1
)

echo Starting DevSync Studio...
start "" build\DevSyncStudio.exe
