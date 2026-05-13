# Remotia

<p align="center">
  <img src="assets/logo.png" alt="Remotia" width="400"/>
</p>

Intercepts the moments when Claude Code (or other agentic AI tools) pauses waiting for
your approval, and sends a Telegram notification with interactive buttons so you can
approve or reject from your phone — without needing to be at your computer.

**Real-world use case:** You step away from your computer to drop the kids off at school.
Claude Code stops and waits for a "yes". With Remotia you can approve from the car with
a tap in Telegram and the process keeps running on its own.

---

## Prerequisites

- Python 3.10 or higher
- A Telegram account
- A Telegram bot created with [@BotFather](https://t.me/BotFather)
- [Claude Code](https://claude.ai/code) installed

---

## Get your Telegram credentials

### Bot token

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow the instructions
3. Copy the token it gives you (format: `123456789:AAF...`)

### Chat ID

1. Search for `@userinfobot` in Telegram and send any message
2. It replies with your `id` — that's your `TELEGRAM_CHAT_ID`

Alternative: search for `@getidsbot` and send `/start`.

---

## Installation

### Linux

```bash
git clone https://github.com/neuracoder/Remotia.git
cd Remotia
chmod +x install.sh uninstall.sh remotia-cli
./install.sh
```

If `~/.local/bin` is not in your `PATH`, the installer will warn you. To add it permanently:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### macOS

```bash
git clone https://github.com/neuracoder/Remotia.git
cd Remotia
chmod +x install.sh uninstall.sh remotia-cli
./install.sh
```

The installer automatically detects macOS and skips the `--break-system-packages` flag.
If you use Homebrew, make sure `pip3` points to your Homebrew Python.

### Windows

**Prerequisites:**
- [Python 3.10+](https://www.python.org/downloads/) — during installation, check **"Add Python to PATH"**
- [Claude Code](https://claude.ai/code) installed and configured
- Git (or download the ZIP from the repository)

Open **cmd** or **PowerShell** in the project folder and run:

```bat
git clone https://github.com/neuracoder/Remotia.git
cd Remotia
install.bat
```

The installer installs Python dependencies, registers the hook in Claude Code's `settings.json`,
and automatically adds `%USERPROFILE%\bin` to your user PATH.

> **Important:** when the installation finishes, close this terminal and open a new one.
> The `remotia` command won't be available in the same session where you ran `install.bat`.

Verify the installation worked by opening a new terminal and running:

```bat
remotia status
```

It should respond with `[INACTIVO] Remotia esta INACTIVO`.

---

## Configuration

Edit the `.env` file the installer created:

```env
TELEGRAM_BOT_TOKEN=123456789:AAFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=987654321

# Optional
REMOTIA_TIMEOUT_SECONDS=480   # seconds before auto-cancelling (default: 8 min)
# REMOTIA_LOG_FILE=/custom/path/remotia.log
```

---

## Run the integration test

```bash
python3 tests/test_send_notification.py
```

Sends a test message to your Telegram with Approve/Cancel buttons.
If it arrives and the buttons work, Remotia is ready to go.

---

## Activation

Remotia starts **inactive** after installation. Turn it on only when you're stepping away
from your computer; turn it off when you're back to avoid unnecessary interruptions.

### Linux / macOS

```bash
remotia on      # activate — actions will be sent to Telegram
remotia off     # deactivate — Claude Code runs without interception
remotia status  # show current state
```

### Windows

```bat
remotia on
remotia off
remotia status
```

Sample output:

```
$ remotia on
✅ Remotia activado — las acciones de Claude Code llegarán a Telegram.

$ remotia status
🟢 Remotia está ACTIVO

$ remotia off
⏸  Remotia desactivado — Claude Code operará sin interceptación.
```

The state is stored as an empty flag file:
- **Linux/macOS:** `~/.remotia/active`
- **Windows:** `%USERPROFILE%\.remotia\active`

If the file exists → active. If not → inactive.
Remotia checks this at the start of every hook and exits in under 1 ms when inactive.

---

## How it works

Once activated with `remotia on`, whenever Claude Code wants to run a Bash command,
write a file, or take other actions that require permission:

1. A notification arrives in your Telegram with the action details
2. You tap ✅ **Approve** or ❌ **Cancel**
3. Claude Code receives the decision and continues

If you don't respond within the configured timeout (default: 8 minutes), the action is
automatically cancelled and Telegram notifies you.

---

## Decision log

Every decision is logged to `~/.remotia/remotia.log` (Linux/macOS) or
`%USERPROFILE%\.remotia\remotia.log` (Windows):

```
2026-05-13 10:23:41  INFO  PENDIENTE | tool=Bash | acción=git push origin main
2026-05-13 10:23:55  INFO  DECISIÓN  | tool=Bash | acción=git push origin main | decisión=ALLOW | elapsed=14.2s
2026-05-13 10:31:02  INFO  TIMEOUT   | tool=Bash | acción=rm -rf dist/ | elapsed=480.0s
```

To filter only decision entries (skip polling noise):

```bash
grep -E "(PENDIENTE|DECISIÓN|TIMEOUT)" ~/.remotia/remotia.log
```

---

## Uninstall

### Linux / macOS

```bash
./uninstall.sh
```

### Windows

```bat
uninstall.bat
```

The uninstaller only removes the Remotia hook from `settings.json`. Project files and
logs in `~/.remotia/` are left untouched.

---

## Project structure

```
Remotia/
├── remotia.py              # Main hook handler
├── telegram_notifier.py    # Telegram integration (pure requests)
├── decision_store.py       # Thread-safe decision store
├── config.py               # Loads variables from .env
├── remotia-cli             # Bash CLI: remotia on/off/status (Linux/macOS)
├── remotia.bat             # Equivalent batch CLI (Windows)
├── requirements.txt        # requests, python-dotenv
├── .env.example            # Configuration template
├── install.sh              # Linux/macOS installer
├── install.bat             # Windows installer
├── uninstall.sh            # Linux/macOS uninstaller
├── uninstall.bat           # Windows uninstaller
├── CHANGELOG.md            # Version history
└── tests/
    ├── test_hook_input.json        # Sample JSON sent by Claude Code
    └── test_send_notification.py  # Manual Telegram integration test
```

---

## Extending to other AIs

Remotia can be adapted to any system that supports external hooks reading from stdin
and writing to stdout.

`remotia.py` implements the Claude Code protocol, but the core of the system
(`telegram_notifier` + `decision_store`) is agnostic. For another system:

1. **Create a wrapper** that translates the input format into what `_format_message()` expects:

```python
payload = {
    "hook_event_name": "PreToolUse",
    "tool_name": "ToolName",
    "tool_input": { ... }
}
```

2. **Reuse** `telegram_notifier.send_and_wait()` directly from the wrapper.

3. **Translate** the response (`"allow"` / `"deny"`) to the format expected by the target AI.

### Example: Cursor AI / Windsurf

```python
#!/usr/bin/env python3
import sys
sys.path.insert(0, "/path/to/Remotia")
import telegram_notifier, config

config.validate()
message = "..."  # build from the editor's input
decision = telegram_notifier.send_and_wait(message, timeout=480)
# translate decision to the editor's expected format
```

---

*Built as part of the [Neuracoder](https://github.com/neuracoder) ecosystem — tools for remote agentic workflows.*
