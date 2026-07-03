---
name: setup-engram
description: Conecta la máquina de un vibecoder al engram-cloud del equipo (server ya armado por Pablo) para que guarde memoria por proyecto y la sincronice al server compartido. Un solo flujo de zero a "✅ funciona": instala/actualiza el binario, configura el token + autosync, enrolla los repos, migra memorias legacy locales y verifica con un guardado de prueba que sube al server. Usar cuando alguien dice "setup engram", "conectar engram", "engram no sincroniza", "mis memorias quedan locales", "configurar engram-cloud". SOLO lado cliente — NO arma el server ni toca la allowlist (eso ya está resuelto globalmente).
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# Setup engram-cloud (lado cliente)

> **Qué es esto:** el equipo comparte un **engram-cloud** (server en Fly.io, `https://wachines-engram-cloud.fly.dev`) donde se replican las memorias de código de cada proyecto. El **server ya está armado y configurado** (lo hizo Pablo: allowlist de proyectos, token, migración de datos viejos). Esta skill es **solo la parte del cliente**: dejar TU máquina lista para guardar memoria y que suba al server. En una corrida vas de "guardo local / no sincroniza" a **"✅ conectado y sincronizando"**.

## ⚖️ IRON LAW
**ESTO ES SOLO CLIENTE. NUNCA toques el server, sus secrets, ni la allowlist (`ENGRAM_CLOUD_ALLOWED_PROJECTS`).** Eso lo gestiona el dueño del server (Pablo). Si un proyecto tuyo da `403 project is not allowed`, NO intentes arreglarlo vos — **pedile a Pablo que lo agregue a la allowlist**. Todo lo demás de esta skill se corre en la máquina del vibecoder.

## Lo que NO hace esta skill (ya resuelto globalmente, no lo repitas)
- Armar/deployar el server, su Postgres, ni sus env vars.
- Configurar la allowlist de proyectos (server-side).
- Migrar los datos viejos del server.

---

## Fase 0 — Preflight

```bash
engram --version 2>/dev/null || echo "engram NO instalado"
```
- Si **no está instalado** o es **< 1.17.0** → Fase 1.
- Si ya es ≥ 1.17.0 → salteá a Fase 2.

> **Por qué 1.17.0+ importa:** las versiones viejas guardan memorias **sin `title`**, y el sync al server lo **exige** → toda memoria queda bloqueada en local. 1.17.0 lo arregla para las memorias nuevas.

## Fase 1 — Instalar / actualizar el binario (≥ 1.17.0)

```bash
brew install gentleman-programming/tap/engram 2>/dev/null || brew upgrade engram
```

**Gotcha de doble instalación (verificalo siempre):** puede haber dos engram — uno del installer en `~/.local/bin/engram` y otro de brew en el Cellar — y el que usa el MCP (`/opt/homebrew/bin/engram`) puede quedar apuntando al **viejo**. Unificá al binario **firmado** del Cellar (⚠️ NO copies el binario con `cp` — en Apple Silicon rompe el code-signing y macOS lo mata con `exit 137`; usá symlink):

```bash
CELLAR=$(ls -d /opt/homebrew/Cellar/engram/*/bin/engram 2>/dev/null | sort -V | tail -1)
if [ -n "$CELLAR" ] && [ -e ~/.local/bin/engram ]; then
  ln -sf "$CELLAR" ~/.local/bin/engram   # symlink, NO cp
fi
for b in ~/.local/bin/engram /opt/homebrew/bin/engram; do
  echo "$b → $("$b" --version 2>&1 | head -1)"
done   # los dos deben decir 1.17.0+
```

> ⚠️ El MCP en ejecución sigue con el binario viejo hasta **reiniciar Claude Code**. Al final de la skill se lo recordás al usuario.

## Fase 2 — Conectar al server (token + config)

El server usa un **bearer token** compartido (`ENGRAM_CLOUD_TOKEN`). **Nunca lo hardcodees ni lo commitees.** Obtenelo así:

```bash
# Opción A — si el vibecoder tiene acceso al Fly del server, lo saca solo:
TOK=$(fly ssh console -a wachines-engram-cloud -C "printenv ENGRAM_CLOUD_TOKEN" 2>/dev/null | grep -oiE '^[a-f0-9]{64}$' | head -1)
# (fly ssh imprime "No machine specified, using…" ANTES del valor — por eso el grep del patrón 64-hex, no `tail -1`)
```
- **Opción B — si no tiene acceso a Fly:** pedile el token a Pablo por un canal seguro (no Slack/Discord público) y guardalo en `TOK`. Usá `AskUserQuestion` o pedíselo directo; NUNCA lo escribas en un archivo versionado.

Con el token en `TOK`, configurá el cliente (con backup):

```bash
[ -z "$TOK" ] && { echo "SIN TOKEN — no sigas hasta tenerlo"; exit 1; }
cp ~/.claude.json ~/.claude.json.bak-engram-$(date +%Y%m%d-%H%M%S) 2>/dev/null
mkdir -p ~/.engram
TOK="$TOK" python3 - <<'PY'
import json, os
tok=os.environ['TOK']; srv="https://wachines-engram-cloud.fly.dev"
# ~/.engram/cloud.json
cj=os.path.expanduser('~/.engram/cloud.json')
c=json.load(open(cj)) if os.path.exists(cj) else {}
c['server_url']=srv; c['token']=tok
json.dump(c, open(cj,'w'), indent=2)
# bloque engram del MCP en ~/.claude.json → env autosync + token
cc=os.path.expanduser('~/.claude.json'); d=json.load(open(cc)); n=0
def walk(o):
    global n
    if isinstance(o,dict):
        for k,v in o.items():
            if k in ('mcpServers','servers') and isinstance(v,dict) and 'engram' in v:
                e=v['engram'].setdefault('env',{})
                e['ENGRAM_CLOUD_AUTOSYNC']='1'; e['ENGRAM_CLOUD_SERVER']=srv; e['ENGRAM_CLOUD_TOKEN']=tok; n+=1
            walk(v)
    elif isinstance(o,list): [walk(x) for x in o]
walk(d); json.dump(d, open(cc,'w'), indent=2)
print(f"configurado: cloud.json + {n} bloque(s) engram del MCP (AUTOSYNC=1, token seteado, no impreso)")
PY
```

## Fase 3 — Enrollar los proyectos del vibecoder

Enrollá cada repo en el que trabaja (el nombre del proyecto es como engram lo conoce — corré `engram stats` para verlos). Ejemplo:

```bash
engram stats 2>&1 | grep -i projects   # ver qué proyectos tenés
for p in reporte-grass backoffice gestionganadera plataforma-tecnicos plataforma-productores; do
  engram cloud enroll "$p" 2>&1 | head -1
done   # ajustá la lista a TUS proyectos
```

> **Naming per-repo:** engram deriva el nombre del proyecto del basename del repo, normalizado (`reporteGrass`→`reporte-grass`). Trabajá **desde el repo** (no desde el home) para que las memorias caigan en el proyecto correcto y no en `pablo`/un nombre random. Si un repo tiene un nombre feo auto-generado, fijalo con `ENGRAM_PROJECT` al invocar.

## Fase 4 — Migrar memorias legacy locales (si las hay)

Si en TU máquina hay memorias viejas (guardadas con engram <1.17.0) su cola de sync no tiene `title` y **bloquea el sync del proyecto**. Por cada proyecto que lo necesite:

```bash
# el sync te avisa si hay legacy: "missing required upsert fields: title"
DB=~/.engram/engram.db
PROJ=reporte-grass   # el que corresponda
# 1) backfill de title en observaciones vacías (derivado del content)
sqlite3 "$DB" "UPDATE observations SET title=substr(trim(content),1,70) WHERE project='$PROJ' AND (title IS NULL OR trim(title)='') AND trim(coalesce(content,''))!='';"
# 2) repair determinístico de la cola
engram cloud upgrade repair --project "$PROJ" --apply 2>&1 | grep -iE "applied|class"
```

## Fase 5 — Diagnóstico "✅ funciona"

El cierre: guardá una memoria de prueba **con título** en un proyecto permitido y confirmá que **sube al server**.

```bash
export ENGRAM_CLOUD_TOKEN=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.engram/cloud.json')))['token'])")
export ENGRAM_CLOUD_SERVER="https://wachines-engram-cloud.fly.dev"
PROJ=reporte-grass   # uno que esté en la allowlist
engram save "setup-engram check" "Verificacion de conexion al engram-cloud del equipo." --project "$PROJ" --type reference
engram sync --project "$PROJ" --cloud 2>&1 | tail -5
```

Interpretá el resultado:
- **`Created chunk … / Cloud sync complete`** → 🎉 **✅ HECHO: engram conectado y sincronizando al server del equipo.** Reportá al usuario que reinicie Claude Code para que el MCP tome el binario nuevo + el autosync (de ahí en más sube solo).
- **`403 project is not allowed`** → el proyecto NO está en la allowlist del server. **No lo arregles vos** — decile al usuario: "pedile a Pablo que agregue `<proyecto>` a `ENGRAM_CLOUD_ALLOWED_PROJECTS`". El resto de tu setup está bien.
- **`missing … title`** → quedó legacy sin migrar → volvé a Fase 4 para ese proyecto.
- **`401 unauthorized`** → token mal / ausente → revisá Fase 2.

## Reporte final (formato)

```
✅ engram-cloud — setup de <máquina/usuario>
- Binario: <versión> (unificado: sí/no)
- Token: configurado (server: wachines-engram-cloud.fly.dev)
- Autosync: ON
- Proyectos enrollados: <lista>
- Migración legacy: <n proyectos> / N.A.
- Diagnóstico: guardado de prueba → <Created chunk … | 403 pedir a Pablo>
- ACCIÓN DEL USUARIO: reiniciar Claude Code para activar el MCP nuevo.
```

## Gotchas (los que ya sufrimos — no vuelvas a tropezar)
1. **Doble binario + PATH**: el MCP puede correr el engram viejo aunque brew tenga el nuevo. Unificá al Cellar por **symlink** (nunca `cp` — rompe el code-signing arm64 → `exit 137`).
2. **`fly ssh` imprime ruido antes del valor** (`No machine specified…`): capturá el token con `grep '^[a-f0-9]{64}$'`, no con `tail`.
3. **`/health` da 200 sin token** — no sirve para validar auth; validá con un `engram sync --cloud` real.
4. **Ruteo por cwd**: guardar desde el home (`~`) manda las memorias al proyecto `pablo`, no al repo. Trabajá desde el repo.
5. **Allowlist es server-side** (env var del server): si `403`, es tarea de Pablo, no tuya.
6. **El MCP toma la config nueva al reiniciar Claude**, no en caliente.
