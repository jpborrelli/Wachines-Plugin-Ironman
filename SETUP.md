# Setup — toolchain de skills del equipo

> **Para todo el equipo de desarrollo (wachines).** Esto se hace **una vez por máquina**, no
> por proyecto. Las skills viven en repos centralizados, no en cada proyecto. Vos instalás el
> toolchain una vez y queda disponible en todos tus proyectos.

## TL;DR — un comando

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Perennia-Regeneracion/Wachines-Plugin-Ironman/main/bin/setup-dev.sh)
```

Esto instala: **gstack** (browse/QA/plan/review/ship), **Wachines-Plugin-Ironman** (best-practices,
reviewers, docs), **gokapso/agent-skills** (WhatsApp/Kapso) y registra **Engram** como MCP en
Claude Code y Codex cuando esos CLIs existen. Si sos del equipo comercial, sumá también
**perennIAR** (ver abajo).

> **Wachines-Plugin-Ironman se instala distinto según el agente:**
> - **Claude Code → como plugin.** El script registra el marketplace `wachines` con
>   `autoUpdate: true` en tu `~/.claude/settings.json` e instala el plugin `Wachines-Plugin-Ironman`
>   (todas las skills **+ los subagentes** `db-architect`/`frontend-specialist`/`db-reviewer`/`security-reviewer`).
>   Se **auto-actualiza solo al iniciar sesión** — no corras nada (es el equivalente nativo del
>   `auto_upgrade` de gstack; no se dispara "al usar una skill", sino en cada startup).
> - **Codex / otros agentes → vía `npx skills`** (no soportan plugins de Claude Code).
>
> Update manual cuando quieras: `claude plugin marketplace update wachines && claude plugin update Wachines-Plugin-Ironman`
> (aplica al reiniciar). Para apagar el auto-update, poné `"autoUpdate": false` en esa entrada.

Por defecto instala skills para `claude-code` y `codex`. Para limitarlo:

```bash
WACHINES_AGENTS=codex bash <(curl -fsSL https://raw.githubusercontent.com/Perennia-Regeneracion/Wachines-Plugin-Ironman/main/bin/setup-dev.sh)
```

## Engram — instalar el CLI

Engram es un binario de Gentleman Programming. En macOS lo más fácil es Homebrew:

```bash
brew install gentleman-programming/tap/engram
engram version
```

Sin Homebrew se puede bajar el binario desde [Gentleman-Programming/engram](https://github.com/Gentleman-Programming/engram/releases).

## Engram cloud — memoria colaborativa del equipo tech

Engram es la memoria fina de código de cada repo. Para colaborar entre devs, el modo recomendado
es **cloud-first**:

1. El admin del equipo entrega `ENGRAM_CLOUD_TOKEN` (un bearer token compartido, uno solo para todo el equipo).
2. El dev corre el bootstrap con ese token y `ENGRAM_CLOUD_SERVER`.
3. El bootstrap registra el MCP `engram`, enrola los proyectos y ejecuta `engram sync --cloud --project <project>`.
   Eso trae las memorias que ya existen en el server al disco local (`~/.engram/`) y deja `engram serve`
   corriendo por launchd en macOS. El token se pasa al entorno de usuario con `launchctl setenv`;
   **no se guarda en el repo**.

Ejemplo:

```bash
export ENGRAM_CLOUD_TOKEN="<token-del-dev>"
bash <(curl -fsSL https://raw.githubusercontent.com/Perennia-Regeneracion/Wachines-Plugin-Ironman/main/bin/setup-dev.sh)
```

El server compartido por default es `https://wachines-engram-cloud.fly.dev`. Si necesitás apuntar
a otro server, seteá también `ENGRAM_CLOUD_SERVER`.

Proyectos conocidos por el bootstrap (el project key usa el **nombre actual del repo**, no el de la carpeta local):

| Repo actual | Project key Engram | Carpeta local (vieja o nueva) |
|---|---|---|
| `Perennia-Regeneracion/Plataforma-Tecnicos` | `plataforma-tecnicos` | `~/Documents/Plataforma-Tecnicos` o `~/Documents/BackOffice` |
| `Perennia-Regeneracion/Reporte-Grass` | `reporte-grass` | `~/Documents/Reporte-Grass` o `~/Documents/reporteGrass` |
| `Perennia-Regeneracion/Plataforma-Productores` | `plataforma-productores` | `~/Documents/Plataforma-Productores` o `~/Documents/gestionganadera` |
| `Perennia-Regeneracion/Wachines-Brain` | `wachines-brain` | `~/Documents/Wachines-Brain` o `~/Documents/los-wachines-sa` |
| `Perennia-Regeneracion/RumIAndo` | `rumiando` | `~/Documents/RumIAndo` |

Si tus carpetas locales tienen otros nombres, seteá `WACHINES_DEV_REPOS` antes de correr el script:

```bash
export WACHINES_DEV_REPOS="$HOME/Documents/mi-carpeta-tecnicos $HOME/Documents/mi-carpeta-grass"
bash <(curl -fsSL https://raw.githubusercontent.com/Perennia-Regeneracion/Wachines-Plugin-Ironman/main/bin/setup-dev.sh)
```

Verificación:

```bash
engram cloud status
engram sync --cloud --project plataforma-tecnicos --status
codex mcp list | grep engram
launchctl print "gui/$(id -u)/dev.engram.serve" | head
```

Si no hay token cloud, el bootstrap no falla: deja Engram local + MCP. Eso sirve para una máquina,
pero **no alcanza para colaboración real**.

### Cómo unirse a las memorias que ya están en el server

Si vos ya subiste memorias al cloud, un nuevo dev solo necesita:

```bash
export ENGRAM_CLOUD_SERVER="https://wachines-engram-cloud.fly.dev"
export ENGRAM_CLOUD_TOKEN="<token-que-te-pasa-el-admin>"
bash <(curl -fsSL https://raw.githubusercontent.com/Perennia-Regeneracion/Wachines-Plugin-Ironman/main/bin/setup-dev.sh)
```

El script va a detectar los repos en `~/Documents/BackOffice`, `~/Documents/reporteGrass` y
`~/Documents/gestionganadera`, hacer `engram cloud enroll <project>` y `engram sync --cloud --project <project>`
para bajar lo que haya en el server. Si un repo no existe localmente, simplemente lo saltea.

Para forzar un proyecto que no está en la lista conocida:

```bash
engram cloud config --server "https://wachines-engram-cloud.fly.dev"
export ENGRAM_CLOUD_TOKEN="<token>"
engram cloud enroll nombre-del-proyecto
engram sync --cloud --project nombre-del-proyecto
```

## Qué se instala y de dónde

| Toolkit | Qué trae | Cómo se instala | Quién lo mantiene |
|---------|----------|-----------------|-------------------|
| **gstack** | browse, qa, plan-*, review, ship, investigate, cso, design-* (~53) | `git clone … ~/.claude/skills/gstack && ./setup` (necesita [Bun](https://bun.sh) v1+) | upstream (garrytan/gstack) |
| **Wachines-Plugin-Ironman** | db-reviewer, docs-architect, frontend-design, *-best-practices, security-reviewer | `npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman` | equipo wachines |
| **gokapso/agent-skills** | integrate/automate/observe WhatsApp (Kapso) | `npx skills add gokapso/agent-skills` (necesita cuenta Kapso) | upstream (gokapso) |
| **vercel/chat** | Chat SDK: bots multi-plataforma (Slack/WhatsApp/Discord/…) sobre AI SDK | `npx skills add vercel/chat` | upstream (Vercel) |
| **perennIAR** (privado) | minuta, prep-reunion, coaching-comercial, html-perennia | `npx skills add Perennia-Regeneracion/perennIAR` | equipo Perennia (negocio) |
| **Engram** | memoria de código por repo + SDD artifacts | `engram mcp --tools=agent` + `engram sync --cloud` | Gentle AI |

## Manual (si el script falla)

```bash
# 1. gstack (dev daily driver) — necesita Bun
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup

# 2. skills de desarrollo core (wachines) — -g = global (todos los proyectos)
# No instalamos "*" por default: hay nombres compartidos con perennia/upstreams.
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman -g -a codex \
  --skill db-reviewer docs-architect frontend-design next-best-practices security-reviewer tanstack-query-hooks
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman -g -a claude-code \
  --skill db-reviewer docs-architect frontend-design next-best-practices security-reviewer tanstack-query-hooks

# 3. WhatsApp/Kapso (si trabajás con BackOffice)
npx skills add gokapso/agent-skills -g -a codex
npx skills add gokapso/agent-skills -g -a claude-code

# 3b. Chat SDK (bots multi-plataforma sobre AI SDK — referencia para el agente de WhatsApp)
npx skills add vercel/chat -g -a codex
npx skills add vercel/chat -g -a claude-code

# 4. skills comerciales (solo equipo de negocio)
npx skills add Perennia-Regeneracion/perennIAR -g -a codex
npx skills add Perennia-Regeneracion/perennIAR -g -a claude-code

# 5. Engram MCP para Codex
codex mcp add engram -- "$(command -v engram)" mcp --tools=agent

# 6. Engram cloud
engram cloud config --server "$ENGRAM_CLOUD_SERVER"
engram cloud enroll plataforma-tecnicos
engram sync --cloud --project plataforma-tecnicos
```

## Scope: global vs proyecto (importante)

`npx skills` instala en uno de dos lugares:

| Scope | Comando | Cae en | Aplica a |
|-------|---------|--------|----------|
| **Global** ✅ | `npx skills add <repo> -g` | `~/.claude/skills/` | **todos** los proyectos |
| Proyecto | `npx skills add <repo>` (parado dentro del repo) | `.claude/skills/` | solo ese proyecto |

- **Usá `-g` siempre** para el toolchain compartido. Como usamos el mismo stack en todos lados,
  global = instalás una vez por máquina y lo tenés en todo.
- ⚠️ Sin `-g`, el CLI **auto-detecta**: si lo corrés dentro de un proyecto, instala a scope
  proyecto sin avisar. Por eso el bootstrap fuerza `-g`.
- **El CLI NO toca `.gitignore`.** Una instalación a scope proyecto se commitearía al repo si no
  la gitignoreás vos. En estos repos las skills compartidas ya están gitignoreadas — no las
  re-instales a scope proyecto. Si un proyecto necesita un set propio, usá `skills-lock.json` +
  `npx skills experimental_install` (patrón node_modules: commiteás el lock, gitignoreás los archivos).

## Mantener al día

```bash
/gstack-upgrade        # actualiza gstack
npx skills update      # actualiza wachines + perennia + gokapso (todo lo de npx skills)
```

O usá la skill **`perennia-upgrade`** que hace ambos en un paso.

## 📜 Política de skills (leer esto)

**Las skills compartidas NO se editan ni se commitean dentro del proyecto.** Viven en sus repos
centralizados y se instalan con `npx skills add`. En los proyectos están **gitignoradas** (igual
que `node_modules`).

- ✅ **Usar una skill** → ya la tenés instalada del toolchain. Nada que hacer.
- ✅ **Mejorar o agregar una skill** → abrí una **branch** en el repo de skills que corresponda
  (`Wachines-Plugin-Ironman` para dev, `perennIAR` para negocio) y mandá un **PR**. No la edites
  en el `.claude/skills/` de un proyecto: ese cambio no se comparte y se pierde al actualizar.
- ✅ **Skill específica de un proyecto** (acoplada a su app/datos) → esa sí vive en el proyecto
  (`reunion-usuario` en gestión ganadera, pipeline de presupuestos en BackOffice). Está tracked
  en el proyecto, no en los repos compartidos.
- ❌ **Nunca** copiar una skill compartida a mano dentro de un proyecto. Drift garantizado.

**Regla mental:** ¿la skill sirve en más de un proyecto? → repo central + `npx skills add`.
¿Solo tiene sentido en este proyecto? → vive en este proyecto.

## 🩺 Troubleshooting (baches reales de instalación)

### `claude` no arranca, o `claude plugin` / `claude mcp` fallan
Síntoma: `claude` tira `node_modules/.bin/claude: No such file or directory`. Pasa cuando el
install local (`claude migrate-installer`, en `~/.claude/local/`) quedó con `node_modules` a medias
y el alias `claude` apunta a ese launcher roto. Rompe el sistema de plugins/MCP desde la shell
(y puede bloquear que otros instaladores registren sus MCP). Fix:
```bash
rm -rf ~/.claude/local/node_modules
npm install --prefix ~/.claude/local
~/.claude/local/claude --version   # debe responder
```

### Un MCP que instalaste no aparece en el agente
**Verificá SIEMPRE con `claude mcp list`** — no asumas que quedó registrado. Claude Code lee MCP de
`.mcp.json` (proyecto), `~/.claude.json` (user) y plugins. Si un instalador lo escribió en otra
ubicación (ej. `~/.claude/mcp/*.json`), **Claude Code no lo lee** y el MCP queda "caído". Registralo:
```bash
claude mcp add <nombre> --scope user -- <comando del server>
claude mcp list   # confirmá ✓ Connected ; reiniciá la sesión (los MCP cargan al inicio)
```

### Gentle AI / Engram
- `gentle-ai install --scope=workspace` deja SDD (comandos/agentes/skills) en `.claude/` del
  proyecto. Eso es repo-local y compatible con que las skills compartidas vivan afuera.
- Engram se registra como MCP user-level con `engram mcp --tools=agent`. En Codex:
  `codex mcp add engram -- "$(command -v engram)" mcp --tools=agent`.
- Para colaboración entre devs, configurar cloud (`ENGRAM_CLOUD_SERVER` + `ENGRAM_CLOUD_TOKEN`) y
  correr `engram sync --cloud --project <project>`. El git-sync de `.engram/` queda como respaldo,
  no como canal principal.
- Gotcha: `engram setup claude-code --help` **ejecuta** el setup igual (no muestra ayuda).
- Reversible: `gentle-ai uninstall` para SDD; `codex mcp remove engram` para Codex.
