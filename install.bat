@echo off
:: Remotia Installer for Windows
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SETTINGS_FILE=%USERPROFILE%\.claude\settings.json"
set "REMOTIA_DIR=%USERPROFILE%\.remotia"
set "CLI_TARGET=%USERPROFILE%\bin\remotia.bat"

echo === Remotia Installer (Windows) ===
echo.

:: ── 1. Dependencias ──────────────────────────────────────────────────────────
echo [1/6] Instalando dependencias Python...
pip install -r "%SCRIPT_DIR%\requirements.txt" --quiet
if errorlevel 1 (
    echo       ERROR: pip falló. Asegurate de tener Python 3.10+ instalado.
    exit /b 1
)
echo       OK

:: ── 2. Directorio de runtime ─────────────────────────────────────────────────
echo [2/6] Creando directorio de runtime en %REMOTIA_DIR% ...
if not exist "%REMOTIA_DIR%" mkdir "%REMOTIA_DIR%"
echo       OK

:: ── 3. Comando remotia (on/off/status) ───────────────────────────────────────
echo [3/6] Instalando comando 'remotia' en %CLI_TARGET% ...
if not exist "%USERPROFILE%\bin" mkdir "%USERPROFILE%\bin"
copy /y "%SCRIPT_DIR%\remotia.bat" "%CLI_TARGET%" >nul
echo       OK
:: Agregar %USERPROFILE%\bin al PATH del usuario si aun no esta
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('PATH','User'); if ($p -notlike '*%USERPROFILE%\bin*') { [Environment]::SetEnvironmentVariable('PATH',$p+';%USERPROFILE%\bin','User'); Write-Host '      Agregado %USERPROFILE%\bin al PATH del usuario.' } else { Write-Host '      %USERPROFILE%\bin ya estaba en el PATH.' }"

:: ── 4. Estado inicial: OFF ───────────────────────────────────────────────────
echo [4/6] Arrancando en estado INACTIVO (OFF) ...
if exist "%REMOTIA_DIR%\active" del /f /q "%REMOTIA_DIR%\active"
echo       OK -- usa 'remotia on' para activar cuando lo necesites.

:: ── 5. Archivo .env ──────────────────────────────────────────────────────────
echo [5/6] Configurando .env ...
if not exist "%SCRIPT_DIR%\.env" (
    copy /y "%SCRIPT_DIR%\.env.example" "%SCRIPT_DIR%\.env" >nul
    echo       .env creado desde .env.example ^(completa TOKEN y CHAT_ID^)
) else (
    echo       .env ya existe -- sin cambios
)

:: ── 6. Hook en Claude Code settings.json ─────────────────────────────────────
echo [6/6] Registrando hook en %SETTINGS_FILE% ...

if not exist "%USERPROFILE%\.claude" mkdir "%USERPROFILE%\.claude"
if not exist "%SETTINGS_FILE%" echo {} > "%SETTINGS_FILE%"

:: Escribir el script Python en un archivo temporal y ejecutarlo
:: (heredoc no existe en cmd; usamos un .py temporal con argumentos)
set "SETUP_SCRIPT=%TEMP%\remotia_setup.py"
> "%SETUP_SCRIPT%" echo import json, sys
>> "%SETUP_SCRIPT%" echo from pathlib import Path
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo settings_path = Path(sys.argv[1])
>> "%SETUP_SCRIPT%" echo hook_command = sys.argv[2]
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo with open(settings_path) as f:
>> "%SETUP_SCRIPT%" echo     try:
>> "%SETUP_SCRIPT%" echo         settings = json.load(f)
>> "%SETUP_SCRIPT%" echo     except json.JSONDecodeError:
>> "%SETUP_SCRIPT%" echo         import shutil
>> "%SETUP_SCRIPT%" echo         shutil.copy(settings_path, str(settings_path) + ".bak")
>> "%SETUP_SCRIPT%" echo         settings = {}
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo hooks = settings.setdefault("hooks", {})
>> "%SETUP_SCRIPT%" echo pre_tool = hooks.setdefault("PreToolUse", [])
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo for entry in pre_tool:
>> "%SETUP_SCRIPT%" echo     for h in entry.get("hooks", []):
>> "%SETUP_SCRIPT%" echo         if h.get("command") == hook_command:
>> "%SETUP_SCRIPT%" echo             print("  Hook de Remotia ya estaba registrado -- sin cambios.")
>> "%SETUP_SCRIPT%" echo             sys.exit(0)
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo pre_tool.append({
>> "%SETUP_SCRIPT%" echo     "matcher": "Bash^|Write^|Edit^|MultiEdit",
>> "%SETUP_SCRIPT%" echo     "hooks": [{"type": "command", "command": hook_command, "timeout": 540}]
>> "%SETUP_SCRIPT%" echo })
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo with open(settings_path, "w") as f:
>> "%SETUP_SCRIPT%" echo     json.dump(settings, f, indent=2, ensure_ascii=False)
>> "%SETUP_SCRIPT%" echo     f.write("\n")
>> "%SETUP_SCRIPT%" echo.
>> "%SETUP_SCRIPT%" echo print("  Hook registrado correctamente.")

python "%SETUP_SCRIPT%" "%SETTINGS_FILE%" "python %SCRIPT_DIR%\remotia.py"
if errorlevel 1 (
    echo       ERROR: Fallo al registrar el hook.
    del /f /q "%SETUP_SCRIPT%"
    exit /b 1
)
del /f /q "%SETUP_SCRIPT%"
echo       OK

echo.
echo === Instalacion completada ===
echo.
echo IMPORTANTE: Cerra esta ventana y abri una nueva terminal para que
echo             el comando 'remotia' funcione correctamente.
echo.
echo PROXIMOS PASOS:
echo   1. Edita %SCRIPT_DIR%\.env
echo      - TELEGRAM_BOT_TOKEN=tu_token_de_BotFather
echo      - TELEGRAM_CHAT_ID=tu_chat_id
echo.
echo   2. Abre una terminal NUEVA y verifica que remotia responde:
echo      remotia status
echo.
echo   3. Prueba que el bot funciona:
echo      python %SCRIPT_DIR%\tests\test_send_notification.py
echo.
echo   4. Activa Remotia cuando lo necesites:
echo      remotia on      activa la interceptacion
echo      remotia off     desactiva (default tras instalar)
echo      remotia status  muestra el estado actual
echo.
echo   Listo! Remotia arranca INACTIVO. Activalo con 'remotia on' antes de alejarte.
