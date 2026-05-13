# Remotia

Intercepta los momentos en que Claude Code (u otras IAs agénticas) se detiene esperando
aprobación del usuario y envía una notificación a Telegram con botones interactivos para
aprobar o rechazar desde el celular — sin necesidad de estar frente a la PC.

**Caso de uso real:** Te alejás de la PC para llevar a tus hijos al colegio. Claude Code
se detiene esperando un "yes". Con Remotia podés aprobar desde el auto con un tap en
Telegram y el proceso continúa solo.

---

## Prerequisitos

- Python 3.10 o superior
- Cuenta de Telegram
- Un bot de Telegram creado con [@BotFather](https://t.me/BotFather)
- [Claude Code](https://claude.ai/code) instalado

---

## Obtener credenciales de Telegram

### Token del bot

1. Abrí Telegram y buscá `@BotFather`
2. Enviá `/newbot` y seguí las instrucciones
3. Copiá el token que te da (formato: `123456789:AAF...`)

### Chat ID

1. Buscá `@userinfobot` en Telegram y enviá cualquier mensaje
2. Te responde con tu `id` — ese es tu `TELEGRAM_CHAT_ID`

Alternativa: buscá `@getidsbot` y usá `/start`.

---

## Instalación

### Linux

```bash
git clone https://github.com/neuracoder/Remotia.git
cd Remotia
chmod +x install.sh uninstall.sh remotia-cli
./install.sh
```

Si `~/.local/bin` no está en tu `PATH`, el instalador te avisa. Para agregarlo permanentemente:

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

El instalador detecta macOS automáticamente y omite el flag `--break-system-packages`.
Si usás Homebrew, asegurate de que `pip3` apunte a tu Python de Homebrew.

### Windows

**Prerequisitos:**
- [Python 3.10+](https://www.python.org/downloads/) — durante la instalación marcá la opción **"Add Python to PATH"**
- [Claude Code](https://claude.ai/code) instalado y configurado
- Git (o descargá el ZIP del repositorio)

Abrí **cmd** o **PowerShell** en la carpeta del proyecto y ejecutá:

```bat
git clone https://github.com/neuracoder/Remotia.git
cd Remotia
install.bat
```

El instalador instala las dependencias Python, registra el hook en `settings.json` de Claude Code y agrega `%USERPROFILE%\bin` al PATH del usuario automáticamente.

> **Importante:** al terminar la instalación, cerrá esta terminal y abrí una nueva. El comando `remotia` no estará disponible en la misma sesión donde se ejecutó `install.bat`.

Verificá que la instalación funcionó abriendo una terminal nueva y ejecutando:

```bat
remotia status
```

Debería responder `[INACTIVO] Remotia esta INACTIVO`.

---

## Configuración

Editá el archivo `.env` que el instalador creó:

```env
TELEGRAM_BOT_TOKEN=123456789:AAFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TELEGRAM_CHAT_ID=987654321

# Opcionales
REMOTIA_TIMEOUT_SECONDS=480   # segundos antes de cancelar automáticamente (default: 8 min)
# REMOTIA_LOG_FILE=/ruta/personalizada/remotia.log
```

---

## Probar antes de usar en producción

```bash
python3 tests/test_send_notification.py
```

Enviará un mensaje de prueba a tu Telegram con los botones Aprobar/Cancelar.
Si llegó y los botones funcionan, Remotia está listo.

---

## Activación manual

Remotia arranca **inactivo** tras la instalación. Activalo solo cuando te alejás de la
PC; cuando estés frente a ella, desactivalo para evitar interrupciones innecesarias.

### Linux / macOS

```bash
remotia on      # activa la interceptación → las acciones llegan a Telegram
remotia off     # desactiva → Claude Code opera sin interceptación
remotia status  # muestra el estado actual
```

### Windows

```bat
remotia on
remotia off
remotia status
```

Ejemplos de salida:

```
$ remotia on
✅ Remotia activado — las acciones de Claude Code llegarán a Telegram.

$ remotia status
🟢 Remotia está ACTIVO

$ remotia off
⏸  Remotia desactivado — Claude Code operará sin interceptación.
```

El estado se guarda como archivo vacío:
- **Linux/macOS:** `~/.remotia/active`
- **Windows:** `%USERPROFILE%\.remotia\active`

Si el archivo existe → activo. Si no existe → inactivo.
Remotia verifica esto al inicio de cada hook y sale en menos de 1 ms si está inactivo.

---

## Uso normal

Una vez activado con `remotia on`, cuando Claude Code quiere ejecutar un comando Bash,
escribir un archivo u otras acciones que requieren permiso:

1. Llega una notificación a tu Telegram con los detalles de la acción
2. Tocás ✅ **Aprobar** o ❌ **Cancelar**
3. Claude Code recibe la decisión y continúa

Si no respondés en el tiempo configurado (default: 8 minutos), la acción se cancela
automáticamente y Telegram te notifica.

---

## Historial de decisiones

Cada decisión queda registrada en `~/.remotia/remotia.log` (Linux/macOS) o
`%USERPROFILE%\.remotia\remotia.log` (Windows):

```
2026-05-13 10:23:41  INFO  PENDIENTE | tool=Bash | acción=git push origin main
2026-05-13 10:23:55  INFO  DECISIÓN  | tool=Bash | acción=git push origin main | decisión=ALLOW | elapsed=14.2s
2026-05-13 10:31:02  INFO  TIMEOUT   | tool=Bash | acción=rm -rf dist/ | elapsed=480.0s
```

Para ver solo el historial de decisiones (sin ruido de polling):

```bash
grep -E "(PENDIENTE|DECISIÓN|TIMEOUT)" ~/.remotia/remotia.log
```

---

## Desinstalar

### Linux / macOS

```bash
./uninstall.sh
```

### Windows

Eliminá manualmente la entrada de Remotia de `%USERPROFILE%\.claude\settings.json`.

El desinstalador elimina solo la entrada de Remotia de `settings.json`. Los archivos
del proyecto y los logs en `~/.remotia/` no se tocan.

---

## Estructura del proyecto

```
Remotia/
├── remotia.py              # Hook handler principal
├── telegram_notifier.py    # Integración Telegram (requests puro)
├── decision_store.py       # Store thread-safe para la decisión
├── config.py               # Carga variables desde .env
├── remotia-cli             # CLI bash: remotia on/off/status (Linux/macOS)
├── remotia.bat             # CLI batch equivalente (Windows)
├── requirements.txt        # requests, python-dotenv
├── .env.example            # Plantilla de configuración
├── install.sh              # Instalador Linux/macOS
├── install.bat             # Instalador Windows
├── uninstall.sh            # Desinstalador Linux/macOS
├── CHANGELOG.md            # Historial de versiones
└── tests/
    ├── test_hook_input.json        # JSON de ejemplo que envía Claude Code
    └── test_send_notification.py  # Test de integración manual con Telegram
```

---

## Extender a otras IAs

Remotia puede adaptarse a cualquier sistema que permita hooks externos que lean stdin
y escriban stdout.

`remotia.py` implementa el protocolo de Claude Code, pero el núcleo del sistema
(`telegram_notifier` + `decision_store`) es agnóstico. Para otro sistema:

1. **Crear un wrapper** que traduzca el formato de entrada al que espera `_format_message()`:

```python
payload = {
    "hook_event_name": "PreToolUse",
    "tool_name": "NombreTool",
    "tool_input": { ... }
}
```

2. **Reutilizar** `telegram_notifier.send_and_wait()` directamente desde el wrapper.

3. **Traducir** la respuesta (`"allow"` / `"deny"`) al formato que espera la IA target.

### Ejemplo: Cursor AI / Windsurf

```python
#!/usr/bin/env python3
import sys
sys.path.insert(0, "/ruta/a/Remotia")
import telegram_notifier, config

config.validate()
message = "..."  # construir desde el input del editor
decision = telegram_notifier.send_and_wait(message, timeout=480)
# convertir decision al formato del editor
```

---

*Desarrollado como parte del ecosistema [Neuracoder](https://github.com/neuracoder) — herramientas para flujo de trabajo agéntico remoto.*
