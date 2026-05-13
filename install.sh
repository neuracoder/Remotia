#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
REMOTIA_DIR="$HOME/.remotia"
HOOK_COMMAND="python3 $SCRIPT_DIR/remotia.py"
CLI_TARGET="$HOME/.local/bin/remotia"

# ── Detección de SO ────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin) OS_NAME="macOS" ;;
    Linux)  OS_NAME="Linux" ;;
    *)      OS_NAME="$OS"   ;;
esac

echo "=== Remotia Installer ($OS_NAME) ==="
echo ""

# ── 1. Dependencias ────────────────────────────────────────────────────────────
echo "[1/6] Instalando dependencias Python..."
if [ "$OS" = "Linux" ]; then
    pip3 install -r "$SCRIPT_DIR/requirements.txt" --break-system-packages --quiet
else
    pip3 install -r "$SCRIPT_DIR/requirements.txt" --quiet
fi
echo "      OK"

# ── 2. Directorio de runtime ───────────────────────────────────────────────────
echo "[2/6] Creando directorio de runtime en $REMOTIA_DIR ..."
mkdir -p "$REMOTIA_DIR"
echo "      OK"

# ── 3. Comando remotia (on/off/status) ────────────────────────────────────────
echo "[3/6] Instalando comando 'remotia' en $CLI_TARGET ..."
mkdir -p "$(dirname "$CLI_TARGET")"
cp "$SCRIPT_DIR/remotia-cli" "$CLI_TARGET"
chmod +x "$CLI_TARGET"
echo "      OK"
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "      AVISO: $HOME/.local/bin no está en tu PATH."
    echo "      Agregá esta línea a tu ~/.bashrc o ~/.zshrc:"
    echo "        export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "      Luego ejecutá: source ~/.bashrc  (o reiniciá la terminal)"
    echo ""
fi

# ── 4. Estado inicial: OFF ─────────────────────────────────────────────────────
echo "[4/6] Arrancando en estado INACTIVO (OFF) ..."
rm -f "$REMOTIA_DIR/active"
echo "      OK — usá 'remotia on' para activar cuando lo necesites."

# ── 5. Archivo .env ────────────────────────────────────────────────────────────
echo "[5/6] Configurando .env ..."
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    echo "      .env creado desde .env.example (completá TOKEN y CHAT_ID)"
else
    echo "      .env ya existe — sin cambios"
fi

# ── 6. Hook en Claude Code settings.json ──────────────────────────────────────
echo "[6/6] Registrando hook en $SETTINGS_FILE ..."

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
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
        print("  ADVERTENCIA: settings.json inválido, creando copia de respaldo...")
        import shutil
        shutil.copy(settings_path, str(settings_path) + ".bak")
        settings = {}

hooks = settings.setdefault("hooks", {})
pre_tool = hooks.setdefault("PreToolUse", [])

for entry in pre_tool:
    for h in entry.get("hooks", []):
        if h.get("command") == hook_command:
            print("  Hook de Remotia ya estaba registrado — sin cambios.")
            sys.exit(0)

pre_tool.append({
    "matcher": "Bash|Write|Edit|MultiEdit",
    "hooks": [
        {
            "type": "command",
            "command": hook_command,
            "timeout": 540
        }
    ]
})

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("  Hook registrado correctamente.")
PYEOF

echo ""
echo "=== Instalación completada ==="
echo ""
echo "PRÓXIMOS PASOS:"
echo "  1. Editá $SCRIPT_DIR/.env"
echo "     - TELEGRAM_BOT_TOKEN=tu_token_de_BotFather"
echo "     - TELEGRAM_CHAT_ID=tu_chat_id"
echo ""
echo "  2. Probá que el bot funciona:"
echo "     python3 $SCRIPT_DIR/tests/test_send_notification.py"
echo ""
echo "  3. Activá Remotia cuando lo necesites:"
echo "     remotia on     # activa la interceptación"
echo "     remotia off    # desactiva (default tras instalar)"
echo "     remotia status # muestra el estado actual"
echo ""
echo "  ¡Listo! Remotia arranca INACTIVO. Activalo con 'remotia on' antes de alejarte."
