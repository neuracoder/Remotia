@echo off
:: Remotia Installer for Windows
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "SETTINGS_FILE=%USERPROFILE%\.claude\settings.json"
set "REMOTIA_DIR=%USERPROFILE%\.remotia"
set "HOOK_COMMAND=python %SCRIPT_DIR%\remotia.py"
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
echo.
echo       AVISO: Asegurate de que %USERPROFILE%\bin este en tu PATH.
echo       Para agregarlo permanentemente, ejecuta en PowerShell (como administrador):
echo         [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";%USERPROFILE%\bin", "User")
echo.

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

python - <<PYEOF
import json, sys
from pathlib import Path

settings_path = Path(r"%SETTINGS_FILE%")
hook_command = r"%HOOK_COMMAND%"

with open(settings_path) as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        import shutil
        shutil.copy(settings_path, str(settings_path) + ".bak")
        settings = {}

hooks = settings.setdefault("hooks", {})
pre_tool = hooks.setdefault("PreToolUse", [])

for entry in pre_tool:
    for h in entry.get("hooks", []):
        if h.get("command") == hook_command:
            print("  Hook de Remotia ya estaba registrado -- sin cambios.")
            sys.exit(0)

pre_tool.append({
    "matcher": "Bash|Write|Edit|MultiEdit",
    "hooks": [{"type": "command", "command": hook_command, "timeout": 540}]
})

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("  Hook registrado correctamente.")
PYEOF

echo.
echo === Instalacion completada ===
echo.
echo PROXIMOS PASOS:
echo   1. Edita %SCRIPT_DIR%\.env
echo      - TELEGRAM_BOT_TOKEN=tu_token_de_BotFather
echo      - TELEGRAM_CHAT_ID=tu_chat_id
echo.
echo   2. Prueba que el bot funciona:
echo      python %SCRIPT_DIR%\tests\test_send_notification.py
echo.
echo   3. Activa Remotia cuando lo necesites:
echo      remotia on      activa la interceptacion
echo      remotia off     desactiva (default tras instalar)
echo      remotia status  muestra el estado actual
echo.
echo   Listo! Remotia arranca INACTIVO. Activalo con 'remotia on' antes de alejarte.
