@echo off
:: Remotia control: on | off | status
setlocal

set "REMOTIA_DIR=%USERPROFILE%\.remotia"
set "ACTIVE_FILE=%REMOTIA_DIR%\active"

if not exist "%REMOTIA_DIR%" mkdir "%REMOTIA_DIR%"

if "%~1"=="on"     goto :on
if "%~1"=="off"    goto :off
if "%~1"=="status" goto :status

echo Uso: remotia ^<on^|off^|status^>
exit /b 1

:on
echo. > "%ACTIVE_FILE%"
echo [ON]  Remotia activado - las acciones de Claude Code llegaran a Telegram.
exit /b 0

:off
if exist "%ACTIVE_FILE%" del /f /q "%ACTIVE_FILE%"
echo [OFF] Remotia desactivado - Claude Code operara sin interceptacion.
exit /b 0

:status
if exist "%ACTIVE_FILE%" (
    echo [ACTIVO]   Remotia esta ACTIVO
) else (
    echo [INACTIVO] Remotia esta INACTIVO
)
exit /b 0
