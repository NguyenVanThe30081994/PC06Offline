@echo off
title PC06 - Dung Server
color 0C

echo.
echo ==========================================
echo    DUNG SERVER PC06
echo ==========================================
echo.

:: Xoa file lock
del /f /q ".server.lock" >nul 2>&1

:: Tim va dung process tren port 5000
set "FOUND=0"
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5000" ^| findstr "LISTENING"') do (
    echo [!] Dung process PID: %%a
    taskkill /F /T /PID %%a >nul 2>&1
    set "FOUND=1"
)

:: Neu van con, kill theo ten
if "!FOUND!"=="0" (
    taskkill /F /IM PhanMemPC06_Server.exe /T >nul 2>&1
    taskkill /F /IM python.exe /T >nul 2>&1
)

:: Huy dang ky khoi dong cung Windows
set "STARTUP_BAT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\PC06_Server.bat"
if exist "!STARTUP_BAT!" (
    del /f /q "!STARTUP_BAT!" 2>nul
    echo [OK] Huy dang ky khoi dong cung Windows
)

echo.
echo [XONG] Server da dung!
echo.
pause