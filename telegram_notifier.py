"""
Remotia — Telegram notifier (requests puro, sin async).
BASE_URL se evalua en cada llamada para garantizar que el token este cargado.
"""

import time
import logging
import requests

import config

logger = logging.getLogger(__name__)


def _base_url() -> str:
    return f"https://api.telegram.org/bot{config.TELEGRAM_BOT_TOKEN}"


def _send_message(text: str) -> int:
    payload = {
        "chat_id": config.TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "HTML",
        "reply_markup": {
            "inline_keyboard": [[
                {"text": "✅ Aprobar", "callback_data": "remotia_allow"},
                {"text": "❌ Cancelar", "callback_data": "remotia_deny"},
            ]]
        }
    }
    resp = requests.post(f"{_base_url()}/sendMessage", json=payload, timeout=10)
    resp.raise_for_status()
    return resp.json()["result"]["message_id"]


def _edit_message(message_id: int, original_text: str, label: str) -> None:
    try:
        requests.post(f"{_base_url()}/editMessageText", json={
            "chat_id": config.TELEGRAM_CHAT_ID,
            "message_id": message_id,
            "text": f"{original_text}\n\n<b>{label}</b>",
            "parse_mode": "HTML",
        }, timeout=10)
    except Exception:
        pass


def _get_updates(offset: int, timeout_sec: int) -> list:
    try:
        resp = requests.get(f"{_base_url()}/getUpdates", params={
            "offset": offset,
            "timeout": timeout_sec,
            "allowed_updates": ["callback_query"],
        }, timeout=timeout_sec + 5)
        resp.raise_for_status()
        return resp.json().get("result", [])
    except requests.exceptions.Timeout:
        return []
    except Exception as exc:
        logger.warning("Error en getUpdates: %s", exc)
        return []


def _clear_pending_updates() -> int:
    try:
        resp = requests.get(f"{_base_url()}/getUpdates", params={
            "offset": -1,
            "timeout": 0,
        }, timeout=5)
        results = resp.json().get("result", [])
        if results:
            return results[-1]["update_id"] + 1
    except Exception:
        pass
    return 0


def send_and_wait(message: str, timeout: int) -> str:
    offset = _clear_pending_updates()
    message_id = _send_message(message)

    deadline = time.monotonic() + timeout
    poll_timeout = 30

    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break

        current_poll = min(poll_timeout, int(remaining))
        updates = _get_updates(offset, current_poll)

        for update in updates:
            offset = update["update_id"] + 1

            cb = update.get("callback_query")
            if cb is None:
                continue

            data = cb.get("data", "")

            try:
                requests.post(f"{_base_url()}/answerCallbackQuery", json={
                    "callback_query_id": cb["id"]
                }, timeout=5)
            except Exception:
                pass

            if data == "remotia_allow":
                _edit_message(message_id, message, "✅ Aprobado")
                return "allow"
            elif data == "remotia_deny":
                _edit_message(message_id, message, "❌ Cancelado")
                return "deny"

    notify_plain("⏱ Remotia: tiempo agotado — acción cancelada automáticamente")
    return "deny"


def notify_plain(text: str) -> None:
    try:
        requests.post(f"{_base_url()}/sendMessage", json={
            "chat_id": config.TELEGRAM_CHAT_ID,
            "text": text,
            "parse_mode": "HTML",
        }, timeout=10)
    except Exception as exc:
        logger.warning("No se pudo enviar notificación plain: %s", exc)
