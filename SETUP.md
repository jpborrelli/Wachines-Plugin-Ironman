# Setup — toolchain de skills del equipo

> **Para todo el equipo de desarrollo (wachines).** Esto se hace **una vez por máquina**, no
> por proyecto. Las skills viven en repos centralizados, no en cada proyecto. Vos instalás el
> toolchain una vez y queda disponible en todos tus proyectos.

## TL;DR — un comando

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/perennia-regen/wachines-skills/main/bin/setup-dev.sh)
```

Esto instala: **gstack** (browse/QA/plan/review/ship), **wachines-skills** (best-practices,
reviewers, docs), **gokapso/agent-skills** (WhatsApp/Kapso) y registra **Engram** como MCP en
Claude Code y Codex cuando esos CLIs existen. Si sos del equipo comercial, sumá también
**perennia-skills** (ver abajo).

Por defecto instala skills para `claude-code` y `codex`. Para limitarlo:

```bash
WACHINES_AGENTS=codex bash <(curl -fsSL https://raw.githubusercontent.com/perennia-regen/wachines-skills/main/bin/setup-dev.sh)
```

## Engram cloud — memoria colaborativa del equipo tech

Engram es la memoria fina de código de cada repo. Para colaborar entre devs, el modo recomendado
es **cloud-first**:

1. El admin del equipo entrega `ENGRAM_CLOUD_SERVER` y `ENGRAM_CLOUD_TOKEN`.
2. El dev corre el bootstrap con esas variables.
3. El bootstrap registra el MCP `engram`, importa `.engram/` si el repo trae chunks versionados,
   enrola los proyectos y ejecuta `engram sync --cloud --project <project>`.

Ejemplo:

```bash
export ENGRAM_CLOUD_SERVER="https://<engram-cloud-del-equipo>"
export ENGRAM_CLOUD_TOKEN="<token-del-dev>"
bash <(curl -fsSL https://raw.githubusercontent.com/perennia-regen/wachines-skills/main/bin/setup-dev.sh)
```

Proyectos conocidos por el bootstrap:

| Repo | Proyecto Engram |
|------|-----------------|
| `~/Documents/BackOffice` | `backoffice` |
| `~/Documents/reporteGrass` | `reportegrass` |
| `~/Documents/gestionganadera` | `gestionganadera` |

Verificación:

```bash
engram cloud status
engram sync --cloud --project backoffice --status
codex mcp list | grep engram
```

Si no hay token cloud, el bootstrap no falla: deja Engram local + MCP. Eso sirve para una máquina,
pero **no alcanza para colaboración real**.

## Qué se instala y de dónde

| Toolkit | Qué trae | Cómo se instala | Quién lo mantiene |
|---------|----------|-----------------|-------------------|
| **gstack** | browse, qa, plan-*, review, ship, investigate, cso, design-* (~53) | `git clone … ~/.claude/skills/gstack && ./setup` (necesita [Bun](https://bun.sh) v1+) | upstream (garrytan/gstack) |
| **wachines-skills** | db-reviewer, docs-architect, frontend-design, *-best-practices, security-reviewer | `npx skills add perennia-regen/wachines-skills` | equipo wachines |
| **gokapso/agent-skills** | integrate/automate/observe WhatsApp (Kapso) | `npx skills add gokapso/agent-skills` (necesita cuenta Kapso) | upstream (gokapso) |
| **perennia-skills** (privado) | minuta, prep-reunion, coaching-comercial, html-perennia | `npx skills add perennia-regen/perennia-skills` | equipo Perennia (negocio) |
| **Engram** | memoria de código por repo + SDD artifacts | `engram mcp --tools=agent` + `engram sync --cloud` | Gentle AI |

## Manual (si el script falla)

```bash
# 1. gstack (dev daily driver) — necesita Bun
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup

# 2. skills de desarrollo core (wachines) — -g = global (todos los proyectos)
# No instalamos "*" por default: hay nombres compartidos con perennia/upstreams.
npx skills add perennia-regen/wachines-skills -g -a codex \
  --skill db-reviewer docs-architect frontend-design next-best-practices security-reviewer tanstack-query-hooks
npx skills add perennia-regen/wachines-skills -g -a claude-code \
  --skill db-reviewer docs-architect frontend-design next-best-practices security-reviewer tanstack-query-hooks

# 3. WhatsApp/Kapso (si trabajás con BackOffice)
npx skills add gokapso/agent-skills -g -a codex
npx skills add gokapso/agent-skills -g -a claude-code

# 4. skills comerciales (solo equipo de negocio)
npx skills add perennia-regen/perennia-skills -g -a codex
npx skills add perennia-regen/perennia-skills -g -a claude-code

# 5. Engram MCP para Codex
codex mcp add engram -- "$(command -v engram)" mcp --tools=agent

# 6. Engram cloud
engram cloud config --server "$ENGRAM_CLOUD_SERVER"
engram cloud enroll backoffice
engram sync --cloud --project backoffice
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
  (`wachines-skills` para dev, `perennia-skills` para negocio) y mandá un **PR**. No la edites
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
