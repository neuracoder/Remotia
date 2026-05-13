#!/usr/bin/env python3
"""
Remotia — hook handler for Claude Code.

Reads a JSON action from stdin, sends it to Telegram for remote approval,
waits for the user's decision, and writes the Claude Code decision JSON to stdout.
"""

import json
import logging
import sys
import time
from pathlib import Path

# Ensure the project root is on sys.path regardless of CWD
sys.path.insert(0, str(Path(__file__).parent))

import config

if not config.validate():
    # Missing env vars — let Claude Code handle it normally
    sys.exit(0)

import telegram_notifier
from config import REMOTIA_LOG_FILE, REMOTIA_TIMEOUT_SECONDS

# ── Logging setup ─────────────────────────────────────────────────────────────

REMOTIA_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=str(REMOTIA_LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s  %(levelname)s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ── Helpers ───────────────────────────────────────────────────────────────────

MAX_PREVIEW_LINES = 20
MAX_PREVIEW_CHARS = 800


def _truncate(text: str, max_chars: int = MAX_PREVIEW_CHARS) -> str:
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + "\n…(truncado)"


def _format_message(tool_name: str, tool_input: dict) -> str:
    header = f"🤖 <b>Remotia — acción pendiente</b>\n\n<b>Tool:</b> <code>{tool_name}</code>\n"

    if tool_name == "Bash":
        command = tool_input.get("command", "(sin comando)")
        description = tool_input.get("description", "")
        body = f"<b>Comando:</b>\n<pre>{_truncate(command)}</pre>"
        if description:
            body += f"\n<b>Descripción:</b> {description}"

    elif tool_name in ("Write", "Edit", "MultiEdit"):
        path = tool_input.get("file_path", tool_input.get("path", "(desconocido)"))
        body = f"<b>Archivo:</b> <code>{path}</code>"

        if tool_name == "Write":
            content = tool_input.get("content", "")
            lines = content.splitlines()[:MAX_PREVIEW_LINES]
            preview = "\n".join(lines)
            body += f"\n<b>Contenido (primeras líneas):</b>\n<pre>{_truncate(preview)}</pre>"

        elif tool_name == "Edit":
            old = _truncate(tool_input.get("old_string", ""), 300)
            new = _truncate(tool_input.get("new_string", ""), 300)
            body += f"\n<b>Reemplazar:</b>\n<pre>{old}</pre>\n<b>Con:</b>\n<pre>{new}</pre>"

        elif tool_name == "MultiEdit":
            edits = tool_input.get("edits", [])
            body += f"\n<b>Cantidad de ediciones:</b> {len(edits)}"
            if edits:
                first = edits[0]
                body += (
                    f"\n<b>Primera edición — reemplazar:</b>\n"
                    f"<pre>{_truncate(first.get('old_string', ''), 200)}</pre>"
                )
    else:
        summary = json.dumps(tool_input, ensure_ascii=False, indent=2)
        body = f"<b>Input:</b>\n<pre>{_truncate(summary)}</pre>"

    return header + body


def _write_decision(hook_event: str, decision: str) -> None:
    reason = (
        "Rechazado remotamente por el usuario via Remotia"
        if decision == "deny"
        else None
    )
    output: dict = {
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "permissionDecision": decision,
        }
    }
    if reason:
        output["hookSpecificOutput"]["permissionDecisionReason"] = reason
    print(json.dumps(output), flush=True)


# ── Main ──────────────────────────────────────────────────────────────────────

ACTIVE_FILE = Path.home() / ".remotia" / "active"


def main() -> None:
    if not ACTIVE_FILE.exists():
        sys.exit(0)

    raw = sys.stdin.read()
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        logger.error("JSON inválido recibido de Claude Code: %s", exc)
        sys.exit(0)

    tool_name: str = payload.get("tool_name", "Unknown")
    tool_input: dict = payload.get("tool_input", {})
    hook_event: str = payload.get("hook_event_name", "PreToolUse")

    action_summary = (
        tool_input.get("command")
        or tool_input.get("file_path")
        or tool_input.get("path")
        or json.dumps(tool_input)[:120]
    )

    logger.info("PENDIENTE | tool=%s | acción=%s", tool_name, action_summary[:200])

    message = _format_message(tool_name, tool_input)

    start = time.monotonic()
    try:
        decision = telegram_notifier.send_and_wait(message, timeout=REMOTIA_TIMEOUT_SECONDS)
    except Exception as exc:
        logger.error("Error en telegram_notifier: %s", exc)
        # Fail open — let Claude Code ask the user directly
        sys.exit(0)

    elapsed = round(time.monotonic() - start, 1)

    if decision is None:
        decision = "deny"
        logger.info(
            "TIMEOUT   | tool=%s | acción=%s | elapsed=%.1fs",
            tool_name, action_summary[:200], elapsed,
        )
        telegram_notifier.notify_plain(
            "⏱ Remotia: tiempo agotado — acción cancelada automáticamente"
        )
    else:
        logger.info(
            "DECISIÓN  | tool=%s | acción=%s | decisión=%s | elapsed=%.1fs",
            tool_name, action_summary[:200], decision.upper(), elapsed,
        )

    _write_decision(hook_event, decision)


if __name__ == "__main__":
    main()
