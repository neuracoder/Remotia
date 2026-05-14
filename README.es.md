# Remotia

<p align="center">
  <img src="assets/logo.png" alt="Remotia" width="400"/>
</p>

> Construí Remotia — aprobá o cancelá acciones de Claude Code desde Telegram aunque no estés en la PC

No soy desarrollador profesional, pero paso mucho tiempo construyendo cosas con Claude Code en VSCode. Se convirtió en una parte central de cómo trabajo.

El problema: tengo dos hijos en edad escolar. La vida no se pausa por inspiración. Estoy constantemente alejándome — llevarlos al colegio, buscarlos, clase de danza, mandados. Y la familia no es algo que se postergue. Todo lo demás puede esperar, incluso el código.

Pero Claude Code no espera. Se detiene y pide aprobación antes de cada acción significativa. Lo cual está bien — no quiero correr con `--auto-approve` y volver a un proyecto roto.

Lo que hacía: conectarme por TeamViewer desde el celular, mirando VSCode en una pantalla chiquita, moviendo el dedo con cuidado para tocar "Approve" en lo que sea que Claude Code estuviese pidiendo. Cada. Vez.

Eso cansó rápido.

Así que construí Remotia.

Es un hook para Claude Code que intercepta las solicitudes de aprobación y las manda a Telegram. Recibís un mensaje con el detalle de lo que Claude quiere hacer, y dos botones: ✅ Aprobar o ❌ Cancelar.

Cuando me voy: `remotia on`  
Cuando vuelvo a la PC: `remotia off`

Eso es todo. Claude Code sigue trabajando mientras estoy en el auto. Apruebo desde el celular. Sin TeamViewer. Sin `--auto-approve`. Sin proyectos rotos.

**Cómo funciona:**

- Registra un hook `PreToolUse` en `~/.claude/settings.json`
- Toggle on/off con un archivo de bandera simple (`remotia on` / `remotia off`)
- Python puro + requests — sin dependencias complejas
- Funciona en Linux, macOS y Windows

GitHub: https://github.com/neuracoder/Remotia

Es gratuito, open source, y tardé una tarde en construirlo. Si alguna vez te encontraste aprobando acciones de Claude Code desde el celular mientras hacías otra cosa — esto puede ayudarte.

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
