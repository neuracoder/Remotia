@echo off
:: Remotia Uninstaller for Windows
setlocal EnableDelayedExpansion

set "SETTINGS_FILE=%USERPROFILE%\.claude\settings.json"
set "REMOTIA_DIR=%USERPROFILE%\.remotia"
set "CLI_TARGET=%USERPROFILE%\bin\remotia.bat"

echo === Remotia Uninstaller (Windows) ===
echo.

:: [1/3] Eliminar hook de settings.json
echo [1/3] Eliminando hook de Remotia de %SETTINGS_FILE% ...
if not exist "%SETTINGS_FILE%" (
    echo       settings.json no encontrado -- nada que desinstalar.
    goto :step2
)

:: Escribir script Python temporal para eliminar el hook
set "UNINSTALL_SCRIPT=%TEMP%\remotia_uninstall.py"
> "%UNINSTALL_SCRIPT%" echo import json, sys
>> "%UNINSTALL_SCRIPT%" echo from pathlib import Path
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo settings_path = Path(sys.argv[1])
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo if not settings_path.exists():
>> "%UNINSTALL_SCRIPT%" echo     print("  No se encontro settings.json -- nada que desinstalar.")
>> "%UNINSTALL_SCRIPT%" echo     sys.exit(0)
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo with open(settings_path, encoding="utf-8-sig") as f:
>> "%UNINSTALL_SCRIPT%" echo     try:
>> "%UNINSTALL_SCRIPT%" echo         settings = json.load(f)
>> "%UNINSTALL_SCRIPT%" echo     except json.JSONDecodeError:
>> "%UNINSTALL_SCRIPT%" echo         print("  ERROR: settings.json invalido. Revisalo manualmente.")
>> "%UNINSTALL_SCRIPT%" echo         sys.exit(1)
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo hooks = settings.get("hooks", {})
>> "%UNINSTALL_SCRIPT%" echo pre_tool = hooks.get("PreToolUse", [])
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo original_len = len(pre_tool)
>> "%UNINSTALL_SCRIPT%" echo filtered = [
>> "%UNINSTALL_SCRIPT%" echo     entry for entry in pre_tool
>> "%UNINSTALL_SCRIPT%" echo     if not any("remotia.py" in h.get("command", "") for h in entry.get("hooks", []))
>> "%UNINSTALL_SCRIPT%" echo ]
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo if len(filtered) == original_len:
>> "%UNINSTALL_SCRIPT%" echo     print("  No se encontro el hook de Remotia -- nada que eliminar.")
>> "%UNINSTALL_SCRIPT%" echo     sys.exit(0)
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo hooks["PreToolUse"] = filtered
>> "%UNINSTALL_SCRIPT%" echo if not filtered:
>> "%UNINSTALL_SCRIPT%" echo     del hooks["PreToolUse"]
>> "%UNINSTALL_SCRIPT%" echo if not hooks:
>> "%UNINSTALL_SCRIPT%" echo     del settings["hooks"]
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo with open(settings_path, "w", encoding="utf-8") as f:
>> "%UNINSTALL_SCRIPT%" echo     json.dump(settings, f, indent=2, ensure_ascii=False)
>> "%UNINSTALL_SCRIPT%" echo     f.write("\n")
>> "%UNINSTALL_SCRIPT%" echo.
>> "%UNINSTALL_SCRIPT%" echo removed = original_len - len(filtered)
>> "%UNINSTALL_SCRIPT%" echo print(f"  {removed} entrada(s) de Remotia eliminada(s) de settings.json.")

python "%UNINSTALL_SCRIPT%" "%SETTINGS_FILE%"
if errorlevel 1 (
    echo       ERROR: Fallo al modificar settings.json.
    del /f /q "%UNINSTALL_SCRIPT%"
    exit /b 1
)
del /f /q "%UNINSTALL_SCRIPT%"
echo       OK

:step2
:: [2/3] Eliminar comando remotia del PATH
echo [2/3] Eliminando comando 'remotia' de %CLI_TARGET% ...
if exist "%CLI_TARGET%" (
    del /f /q "%CLI_TARGET%"
    echo       OK
) else (
    echo       No encontrado -- sin cambios.
)

:: [3/3] Desactivar si estaba activo
echo [3/3] Desactivando Remotia si estaba activo ...
if exist "%REMOTIA_DIR%\active" (
    del /f /q "%REMOTIA_DIR%\active"
    echo       Remotia desactivado.
) else (
    echo       Ya estaba inactivo.
)

echo.
echo === Desinstalacion completada ===
echo.
echo Remotia desinstalado. Los archivos del proyecto y los logs en
echo %USERPROFILE%\.remotia\ no fueron eliminados.
