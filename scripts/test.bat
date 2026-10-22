@echo off
setlocal

echo =======================================================
echo Running DevSync Studio Backend Test Suite
echo =======================================================

python -m pytest tests/ -v
if errorlevel 1 (
    echo.
    echo Tests failed!
    exit /b 1
)

echo.
echo All backend tests passed successfully!
