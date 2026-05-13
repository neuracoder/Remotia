import os
import sys
from pathlib import Path
from dotenv import load_dotenv

_env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=_env_path)

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
REMOTIA_TIMEOUT_SECONDS = int(os.getenv("REMOTIA_TIMEOUT_SECONDS", "480"))
REMOTIA_LOG_FILE = Path(
    os.getenv("REMOTIA_LOG_FILE", str(Path.home() / ".remotia" / "remotia.log"))
)


def validate() -> bool:
    missing = []
    if not TELEGRAM_BOT_TOKEN:
        missing.append("TELEGRAM_BOT_TOKEN")
    if not TELEGRAM_CHAT_ID:
        missing.append("TELEGRAM_CHAT_ID")
    if missing:
        print(
            f"[Remotia] ERROR: variables de entorno faltantes: {', '.join(missing)}. "
            f"Editá {_env_path} y completá los valores requeridos.",
            file=sys.stderr,
        )
        return False
    return True
