@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo Packaging DevSync Studio ^& Generating Inno Setup Installer
echo =======================================================

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=C:\Qt\6.8.3\msvc2022_64\bin;%PATH%"

echo [1/5] Compiling C++ GUI application...
call scripts\build.bat
if errorlevel 1 (
    echo Error: C++ build failed.
    exit /b 1
)

set "DIST_DIR=dist\DevSyncStudio"
if not exist "%DIST_DIR%" (
    mkdir "%DIST_DIR%"
)

echo [2/5] Sanitizing dist directory and copying assets...
rem Remove any legacy unbundled script directories or logs
if exist "%DIST_DIR%\backend" rmdir /s /q "%DIST_DIR%\backend"
if exist "%DIST_DIR%\__pycache__" rmdir /s /q "%DIST_DIR%\__pycache__"
del /f /q "%DIST_DIR%\*.log" 2>nul

copy /Y build\DevSyncStudio.exe "%DIST_DIR%\"
if exist assets (
    xcopy /E /I /Y assets "%DIST_DIR%\assets"
)

echo [3/5] Building native windowless standalone Python backend worker...
pyinstaller --clean --noconfirm --onedir --windowed --name DevSyncBackend --collect-all backend run_backend.py
if errorlevel 1 (
    echo Error: PyInstaller failed to build DevSyncBackend.
    exit /b 1
)

copy /Y "dist\DevSyncBackend\DevSyncBackend.exe" "%DIST_DIR%\"
xcopy /E /I /Y "dist\DevSyncBackend\_internal" "%DIST_DIR%\_internal"

rem Verify again that no loose backend directory was accidentally copied
if exist "%DIST_DIR%\backend" rmdir /s /q "%DIST_DIR%\backend"

echo [4/5] Deploying Qt 6 runtime dependencies...
windeployqt --qmldir ui "%DIST_DIR%\DevSyncStudio.exe"

echo [5/5] Compiling Inno Setup Installer...
set "ISCC_PATH=C:\Users\Administrator\AppData\Local\Programs\Inno Setup 7\ISCC.exe"
if exist "%ISCC_PATH%" (
    "%ISCC_PATH%" "installer\DevSyncStudio.iss"
    if errorlevel 1 (
        echo Error: Inno Setup compilation failed.
        exit /b 1
    )
    
    copy /Y "dist\installer\DevSyncStudio_Setup_v1.0.0.exe" "dist\install.exe"
    copy /Y "dist\installer\DevSyncStudio_Setup_v1.0.0.exe" "dist\installer\install.exe"
    copy /Y "dist\installer\DevSyncStudio_Setup_v1.0.0.exe" "dist\installation.exe"
    copy /Y "dist\installer\DevSyncStudio_Setup_v1.0.0.exe" "dist\installer\installation.exe"
    copy /Y "dist\installer\DevSyncStudio_Setup_v1.0.0.exe" "dist\Setup.exe"
    
    echo.
    echo =======================================================
    echo DevSync Studio Packaging and Installer creation complete!
    echo Setup installer executable:
    echo   - dist\install.exe
    echo   - dist\installation.exe
    echo   - dist\installer\DevSyncStudio_Setup_v1.0.0.exe
    echo Standalone portable distribution:
    echo   - dist\DevSyncStudio\DevSyncStudio.exe
    echo =======================================================
) else (
    echo Warning: Inno Setup compiler ISCC.exe not found at %ISCC_PATH%
)

