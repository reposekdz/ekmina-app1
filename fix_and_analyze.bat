@echo off
echo ========================================
echo E-KIMINA FLUTTER FIX HELPER
echo ========================================
echo.
echo This will:
echo 1. Clean flutter build
echo 2. Get dependencies
echo 3. Show remaining errors
echo.
pause

cd /d "%~dp0"

echo.
echo [1/3] Cleaning flutter...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Analyzing code...
call flutter analyze

echo.
echo ========================================
echo DONE! Check output above for any remaining errors.
echo ========================================
pause
