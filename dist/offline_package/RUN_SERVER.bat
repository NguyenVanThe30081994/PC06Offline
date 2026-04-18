@echo off
chcp 65001 >nul
title PhanMemPC06 Server

cls
echo.
echo  _   _  _____  _____  _____  _____  _____ 
echo ^| \ ^| ^|/ ____^|^|_   _^|^|_   _^|^|_   _^|/ ____^|
echo ^|  \^| ^| (___    ^| ^|    ^| ^|    ^| ^|  ^| ^|     (^)
echo ^|     \ \___ \   ^| ^|    ^| ^|    ^| ^|  ^| ^|    (_)
echo ^| |\  |____) ^| _^|_|_  _^|_|_  _^|_|_ ^| ^|____^|
echo ^|_^| \_^|_____/ ^|____^||____^||_____^| \_____/
echo.
echo    PHIEN BAN OFFLINE - Version 3.5.0
echo.

:: Mac dinh hien console
set "HIDE_CONSOLE=0"
set "AUTO_RESTART=0"
set "SERVER_PORT=5000"
set "AUTO_START=0"

:: Xu ly tham so
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--hidden" set "HIDE_CONSOLE=1" & shift & goto :parse_args
if /i "%~1"=="--auto" set "AUTO_RESTART=1" & shift & goto :parse_args
if /i "%~1"=="--port" (
    set "SERVER_PORT=%~2"
    shift & shift & goto :parse_args
)
if /i "%~1"=="--autostart" goto :register_autostart
if /i "%~1"=="--uninstall" goto :unregister_autostart
if /i "%~1"=="--help" goto :show_help
shift
goto :parse_args

:show_help
echo.
echo  SU DUNG:
echo  ========
echo  RUN_SERVER.bat              - Chay binh thuong (co console)
echo  RUN_SERVER.bat --hidden   - Chay an (khong hien console)
echo  RUN_SERVER.bat --auto    - Chay voi tu dong khoi dong lai
echo  RUN_SERVER.bat --port=8080 - Chay tren port khac
echo.
echo  QUAN LY KHOI DONG CUNG WINDOWS:
echo  RUN_SERVER.bat --autostart  - Dang ky khoi dong cung Windows
echo  RUN_SERVER.bat --uninstall - Huy dang ky
echo.
echo  Vi du:
echo    RUN_SERVER.bat --hidden --auto --port=5000
echo.
pause
exit /b 0

:register_autostart
echo.
echo [INFO] Dang ky khoi dong cung Windows...

set "STARTUP_BAT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\PC06_AutoStart.bat"

:: Tao file khoi dong voi tham so --hidden --auto
(
echo @echo off
echo "%~dp0PhanMemPC06_Server.exe" --hidden --auto --port=5000
) > "%STARTUP_BAT%"

if exist "%STARTUP_BAT%" (
    echo [OK] Da dang ky khoi dong cung Windows
    echo    File: %STARTUP_BAT%
    echo [INFO] Server se khoi dong an sau khi Windows khoi dong
) else (
    echo [LOI] Khong the dang ky!
)
echo.
pause
exit /b 0

:unregister_autostart
echo.
echo [INFO] Huy dang ky khoi dong cung Windows...

set "STARTUP_BAT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\PC06_AutoStart.bat"

if exist "%STARTUP_BAT%" (
    del /f /q "%STARTUP_BAT%"
    echo [OK] Huy dang ky thanh cong
) else (
    echo [THONG BAO] Chua dang ky!
)
echo.
pause
exit /b 0

:args_done

:: Kiem tra xem co dang chay tu thu muc package khong
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

:: Tao thu muc can thiet neu chua co
if not exist "uploads" mkdir uploads
if not exist "backups" mkdir backups
if not exist "logs" mkdir logs
if not exist "task_files" mkdir task_files
if not exist "library_files" mkdir library_files
if not exist "tmp" mkdir tmp

echo [INFO] Khoi tao du lieu...
echo.

:: Kiem tra database
if not exist "pc06_system.db" (
    echo [INFO] Phat hien lan chay dau tien!
    echo [INFO] He thong se tu dong tao database.
    echo.
)

echo [INFO] Khoi dong Server...
echo.
echo    Cau hinh:
echo    - Port: %SERVER_PORT%
if "%HIDE_CONSOLE%"=="1" echo    - Che do: CHAY AN
if "%AUTO_RESTART%"=="1" echo    - Che do: TU DONG KHOI DONG LAI
echo.
echo    Dia chi truy cap:
echo    - Local:   http://localhost:%SERVER_PORT%
echo    - Network: http://%COMPUTERNAME%:%SERVER_PORT%
echo.
echo    Nhan Ctrl+C de dung server
echo.
echo ============================================================
echo.

:: Tao file tham so cho exe
set "EXE_ARGS="

:: Chuan bi chuoi arguments
set "EXE_ARGS=--port=%SERVER_PORT%"
if "%AUTO_RESTART%"=="1" set "EXE_ARGS=%EXE_ARGS% --auto"
if "%HIDE_CONSOLE%"=="1" set "EXE_ARGS=%EXE_ARGS% --hidden"

:: Mo trinh duyet tu dong (chi khi khong an)
if "%HIDE_CONSOLE%"=="0" start "" "http://localhost:%SERVER_PORT%"

:: Chay server
set "EXE_PATH=%~dp0PhanMemPC06_Server.exe"

if "%HIDE_CONSOLE%"=="1" (
    :: Chay an - su dung VBScript de an console
    echo [INFO] Dang chay che do an...
    wscript.exe //Nologo "%~dp0run_hidden.vbs" "%EXE_PATH%" %EXE_ARGS%
) else (
    %EXE_PATH% %EXE_ARGS%
)

:: Neu chuong trinh ket thuc (loi), cho nguoi dung
echo.
echo Server da dung!
echo.
pause
