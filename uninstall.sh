#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="python3 $SCRIPT_DIR/remotia.py"

echo "=== Remotia Uninstaller ==="
echo ""

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "No se encontró $SETTINGS_FILE — nada que desinstalar."
    exit 0
fi

python3 - <<PYEOF
import json, sys
from pathlib import Path

settings_path = Path("$SETTINGS_FILE")
hook_command = "$HOOK_COMMAND"

with open(settings_path) as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        print("  ERROR: settings.json inválido. Revisalo manualmente.")
        sys.exit(1)

hooks = settings.get("hooks", {})
pre_tool = hooks.get("PreToolUse", [])

original_len = len(pre_tool)
filtered = [
    entry for entry in pre_tool
    if not any(h.get("command") == hook_command for h in entry.get("hooks", []))
]

if len(filtered) == original_len:
    print("  No se encontró el hook de Remotia en settings.json — nada que eliminar.")
    sys.exit(0)

hooks["PreToolUse"] = filtered
if not filtered:
    del hooks["PreToolUse"]
if not hooks:
    del settings["hooks"]

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

removed = original_len - len(filtered)
print(f"  {removed} entrada(s) de Remotia eliminada(s) de settings.json.")
PYEOF

echo ""
echo "Remotia desinstalado. Los archivos del proyecto y los logs en ~/.remotia/ no fueron eliminados."
