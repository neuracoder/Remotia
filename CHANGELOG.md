# Changelog

All notable changes to Remotia are documented here.

---

## [1.0.0] — 2026-05-13

### Added
- `remotia.py` — Claude Code hook handler: reads tool actions from stdin, sends them to Telegram with Approve/Cancel buttons, writes the decision to stdout.
- `telegram_notifier.py` — Pure-`requests` Telegram integration: sends formatted messages with inline keyboards and polls for callback responses.
- `decision_store.py` — Thread-safe one-shot store bridging the callback poll loop and the main decision flow.
- `config.py` — Loads and validates environment variables from `.env` via `python-dotenv`.
- `remotia-cli` — Bash CLI (`remotia on | off | status`) for Linux and macOS.
- `remotia.bat` — Batch CLI equivalent for Windows.
- `install.sh` — Installer for Linux and macOS: installs Python deps, creates `~/.remotia/`, copies `.env.example`, installs the CLI command, and registers the hook in `~/.claude/settings.json`.
- `install.bat` — Installer for Windows: same steps adapted for `%USERPROFILE%` paths and Windows conventions.
- `uninstall.sh` — Removes the Remotia hook from `~/.claude/settings.json` without touching other config or logs.
- Manual activation system: Remotia only intercepts when `~/.remotia/active` (Linux/macOS) or `%USERPROFILE%\.remotia\active` (Windows) exists. Default state after install is **inactive**.
- `tests/test_send_notification.py` — Integration test that sends a real Telegram message and waits for a button press.
- `tests/test_hook_input.json` — Sample JSON payload that Claude Code sends to the hook.
