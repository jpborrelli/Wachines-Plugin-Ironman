# Mapeo del motor: gstack `$B` → `agent-browser`

Esta skill reemplaza el binario `browse` de gstack (`$B`) por **`agent-browser`** (`/usr/local/bin/agent-browser`). Misma idea (browser headless manejable por un agente, con snapshot de árbol accesible y refs `@eN`), CLI distinto.

> Verificá siempre con `agent-browser --help` — el CLI puede ganar/cambiar comandos. Esta tabla es el mapeo a la fecha de escritura.

## Navegación

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Ir a una URL | `$B goto <url>` | `agent-browser open <url>` |
| Recargar | `$B reload` | `agent-browser reload` |
| Atrás / adelante | `$B back` / `$B forward` | `agent-browser back` / `agent-browser forward` |

## Snapshot / inspección (el corazón)

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Árbol accesible con refs `@eN` | `$B snapshot -i` | `agent-browser snapshot -i` |
| Snapshot compacto / acotado | `$B snapshot -C` | `agent-browser snapshot -c` (compacto) · `-d <n>` (profundidad) · `-s <sel>` (scope) |
| Diff de snapshot tras una acción | `$B snapshot -D` | **No hay diff nativo.** Tomá `snapshot -i` antes y después y compará vos; o `agent-browser get text/html <sel>` para confirmar el cambio puntual. |
| Screenshot anotado a archivo | `$B snapshot -i -a -o <path>` | `agent-browser screenshot <path> --full` (sin anotación de refs; las refs salen del `snapshot -i` aparte) |

> **Nota:** `agent-browser snapshot -i` ya da los refs `@e2`, `@e3`… que usás en `click`/`fill`. No hay un `-D` (diff) ni anotación sobre la imagen como en gstack; el diff se hace comparando dos snapshots, y la evidencia visual es el `screenshot`.

## Interacción

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Click | `$B click <sel>` | `agent-browser click <sel\|@ref>` |
| Doble click | — | `agent-browser dblclick <sel>` |
| Escribir (sin limpiar) | `$B type <sel> <text>` | `agent-browser type <sel> <text>` |
| Limpiar y llenar | `$B fill <sel> <text>` | `agent-browser fill <sel> <text>` |
| Tecla | `$B press <key>` | `agent-browser press <key>` (Enter, Tab, Control+a) |
| Hover / focus | `$B hover <sel>` | `agent-browser hover <sel>` / `agent-browser focus <sel>` |
| Check / uncheck | `$B check <sel>` | `agent-browser check <sel>` / `agent-browser uncheck <sel>` |
| Select dropdown | `$B select <sel> <val>` | `agent-browser select <sel> <val...>` |
| Drag & drop | — | `agent-browser drag <src> <dst>` — **⚠️ NO funciona con dnd-kit / react-beautiful-dnd** (ver nota abajo) |
| Upload de archivo | `$B upload <sel> <files>` | `agent-browser upload <sel> <files...>` |
| Scroll | `$B scroll <dir>` | `agent-browser scroll <up\|down\|left\|right> [px]` |
| Esperar elemento / ms | `$B wait <sel>` | `agent-browser wait <sel\|ms>` |

> **⚠️ `drag` reporta `✓ Done` pero NO mueve cards de dnd-kit ni react-beautiful-dnd** (las libs de kanban más comunes). Emula HTML5 drag-and-drop; esas libs usan pointer events. Es un **falso positivo peligroso**: dice que pasó algo y no pasó nada. Para DnD:
> 1. **Verificá el handle en el árbol de a11y.** `snapshot -i` y mirá si la card expone un control de drag. Si las cards solo tienen un botón "Abrir" y no hay handle ni movimiento por teclado → **el DnD no es testeable por tool ni por teclado**: flaggealo como hallazgo de a11y.
> 2. **Si necesitás ejercerlo**, secuencia de pointer events manual por `eval`: `get box` de origen y destino → `dispatchEvent` de `pointerdown` → varios `pointermove` → `pointerup`, con las coordenadas reales.
> 3. **Si nada anda**, documentá "DnD no verificable por la tool" como **PUNTO CIEGO**. NO afirmes que anda ni que está roto.

> **`fill` por `find role` es inconsistente** (`find role <role> fill <texto>` pide `--name` y suele fallar con `Expected string, received null`). Para **llenar** usá `@ref` (de un `snapshot -i` fresco) o `find placeholder|label <valor> fill <texto>`. La forma confiable de `find role` es para **click**: `find role button click --name "X"`.

## Buscar elementos (cuando el ref es ambiguo)

| gstack `$B` | agent-browser |
|---|---|
| — | `agent-browser find role <value> <action> [--name X]` |
| — | `agent-browser find text\|label\|placeholder\|alt\|title\|testid <value> <action>` |

Ejemplos:
```bash
agent-browser find role button click --name "Guardar"
agent-browser find placeholder "Buscar" fill "vaca 123"
agent-browser find testid submit-btn click
```

## Leer info / estado

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Leer texto/html/valor/attr/título/url/count | varía | `agent-browser get text\|html\|value\|attr <name>\|title\|url\|count\|box\|styles [sel]` |
| ¿Visible / habilitado / checked? | — | `agent-browser is visible\|enabled\|checked <sel>` |

## Evidencia visual

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Screenshot | `$B screenshot <path>` | `agent-browser screenshot <path>` — **pasá SIEMPRE ruta absoluta** (ver nota) |
| Screenshot full-page | `$B screenshot --full` | `agent-browser screenshot <path> --full` |

> **Pasá SIEMPRE ruta absoluta a `screenshot`.** Las rutas relativas se resuelven contra el **cwd del daemon** (no el tuyo) y el archivo se pierde en silencio — `screenshot` reporta `✓` igual. Usá `$(pwd)/.wachi-qa/reports/screenshots/...` o la ruta completa.
| Responsive (3 viewports) | `$B responsive` | No hay comando único: cambiá viewport y screencap 3 veces (ver abajo). |

## Viewport / device / media

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Viewport WxH | `$B viewport 375x812` | `agent-browser set viewport 375 812` |
| Device preset | — | `agent-browser set device <name>` |
| Dark mode / reduced motion | — | `agent-browser set media dark` · `set media light reduced-motion` |

Responsive a mano:
```bash
for vp in "375 812" "768 1024" "1280 720"; do
  agent-browser set viewport $vp
  agent-browser screenshot "$(pwd)/.wachi-qa/reports/screenshots/page-${vp// /x}.png" --full   # ruta ABSOLUTA
done
```

## Consola y red (clave para QA — "mirá la consola tras cada interacción")

| Intención | gstack `$B` | agent-browser |
|---|---|---|
| Errores de consola | `$B console --errors` | `agent-browser console` (logs) · `agent-browser errors` (page errors / excepciones) |
| Limpiar consola | `$B console --clear` | `agent-browser console --clear` / `agent-browser errors --clear` |
| Requests de red (solo URLs, **sin status**) | — | `agent-browser network requests [--filter <patrón>] [--clear]` |

> **Capturar errores de consola:** `agent-browser console` lista los console logs; `agent-browser errors` lista los page errors (excepciones JS no atrapadas). Usá **ambos** tras cada interacción importante. Si necesitás algo que el comando no expone (ej. contar warnings), caé a `agent-browser eval "<js>"` para leer estado del `window` o instrumentar `console`.

> **⚠️ `network requests` NO da status codes.** Lista solo `METHOD URL (type)`, sin status; `--filter` matchea la **URL string** (no el status); y solo captura durante navegación fresca (hay que `--clear` + `reload`). **No sirve para cazar 4xx/5xx.** Para detectar requests fallidos:
> - (a) mirá `agent-browser console` — los 4xx/5xx de recursos salen como `Failed to load resource: the server responded with a status of N`;
> - (b) `agent-browser eval "await fetch('<url>').then(r=>r.status)"` para un endpoint puntual.

## Eval (escape hatch)

| Intención | agent-browser |
|---|---|
| Correr JS arbitrario (leer estado, fetch a una API, contar nodos) | `agent-browser eval "<js>"` |

Ejemplos:
```bash
agent-browser eval "await fetch('/api/health').then(r=>r.status)"
agent-browser eval "document.querySelectorAll('[role=alert]').length"
```

## Cierre

| gstack `$B` | agent-browser |
|---|---|
| `$B close` | `agent-browser close` |

## Opciones útiles

- `--json` en muchos comandos → salida parseable.
- `--session <name>` / `AGENT_BROWSER_SESSION` → sesión aislada (útil con varios worktrees).
- `--headers <json>` / `--state <path>` → auth (headers scopeados al origin, storage state desde JSON).
- `--profile <path>` → perfil persistente (cookies entre corridas).

## Diferencias a tener presentes vs gstack `$B`

1. **No hay `snapshot -D` (diff).** Comparás dos `snapshot -i` o verificás con `get`.
2. **Screenshots no llevan anotación de refs sobre la imagen** (`-a` de gstack). Las refs vienen del `snapshot -i` textual; el screenshot es la foto.
3. **Consola y errores son dos comandos** (`console` y `errors`), no un flag.
4. **`network requests` NO da status codes** — lista solo `METHOD URL (type)`. Para 4xx/5xx mirá `console` (`Failed to load resource: ... status N`) o `eval` con `fetch`. No confíes en `network requests` para detectar requests fallidos.
5. **No hay `status`/CDP-mode detection de gstack.** Para auth usás `--headers` / `--state` / `--profile`, o el demo-login del repo.
