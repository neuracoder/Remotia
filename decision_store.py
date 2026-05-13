import threading
from typing import Optional


class DecisionStore:
    """Thread-safe one-shot store for a pending approval decision."""

    def __init__(self) -> None:
        self._event = threading.Event()
        self._decision: Optional[str] = None
        self._lock = threading.Lock()

    def set(self, decision: str) -> None:
        with self._lock:
            if self._decision is None:
                self._decision = decision
                self._event.set()

    def wait(self, timeout: float) -> Optional[str]:
        self._event.wait(timeout=timeout)
        with self._lock:
            return self._decision

    def reset(self) -> None:
        with self._lock:
            self._decision = None
            self._event.clear()


# Module-level singleton used across remotia.py and telegram_notifier.py
store = DecisionStore()
