#!/usr/bin/env python3
"""
Test manual de integración con Telegram.

Uso:
    python3 tests/test_send_notification.py

Envía un mensaje de prueba con botones Aprobar/Cancelar y muestra
en consola la decisión recibida. Requiere .env configurado.
"""

import sys
import time
from pathlib import Path

# Asegurar que el root del proyecto esté en el path
sys.path.insert(0, str(Path(__file__).parent.parent))

import config

if not config.validate():
    sys.exit(1)

import telegram_notifier

TEST_MESSAGE = (
    "🧪 <b>Remotia — Test de integración</b>\n\n"
    "<b>Tool:</b> <code>Bash</code>\n"
    "<b>Comando:</b>\n<pre>git push origin main</pre>\n"
    "<b>Descripción:</b> Push changes to remote\n\n"
    "<i>Este es un mensaje de prueba. No corresponde a una acción real de Claude Code.</i>"
)

print(f"Enviando mensaje de prueba a chat_id={config.TELEGRAM_CHAT_ID} ...")
print(f"Timeout: {config.REMOTIA_TIMEOUT_SECONDS}s")
print("Esperando que presiones un botón en Telegram...\n")

start = time.monotonic()

try:
    decision = telegram_notifier.send_and_wait(TEST_MESSAGE, timeout=config.REMOTIA_TIMEOUT_SECONDS)
    elapsed = round(time.monotonic() - start, 1)
    print(f"✅ Decisión recibida: {decision.upper()}  (en {elapsed}s)")
except KeyboardInterrupt:
    print("\nTest cancelado por el usuario.")
    sys.exit(0)
except Exception as exc:
    print(f"❌ Error: {exc}")
    sys.exit(1)
