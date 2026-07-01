# Wachines-Plugin-Ironman

A curated, installable set of [Agent Skills](https://github.com/vercel-labs/skills) for
Claude Code (and any agent that supports the open Skills standard). Hand-picked tools for
shipping quality web apps and databases: Postgres/Supabase best practices, React/Next.js
performance, a SQL-migration reviewer, and a documentation architect.

Formerly `wachines-skills` (renamed to match the `Wachines-Plugin-Ironman` repository).

Project-agnostic by design — no company-, domain-, or schema-specific content. Add the ones
you want, contribute the ones you wish existed.

> **¿Sos del equipo? Empezá por [SETUP.md](SETUP.md)** — instala todo el toolchain dev
> (gstack + Wachines-Plugin-Ironman + gokapso), registra Engram para Claude Code/Codex y deja listo el
> camino de Engram cloud. Las skills se instalan desde repos centralizados, no se editan dentro de
> cada proyecto.

## Install

**Pick by your agent:** Claude Code → the plugin (recommended). Codex and any other agent →
`npx skills` (Claude Code plugins only work in Claude Code).

### Claude Code → the plugin (recommended)

This repo is also a **Claude Code plugin marketplace**. One install wires up every skill **and**
the `db-architect` / `frontend-specialist` / `db-reviewer` / `security-reviewer` subagents — no
`npx`, no per-agent copying:

```bash
# add the marketplace (defined in .claude-plugin/marketplace.json)
claude plugin marketplace add Perennia-Regeneracion/Wachines-Plugin-Ironman

# install the plugin (skills + subagents auto-discovered)
claude plugin install Wachines-Plugin-Ironman@wachines
```

Or interactively inside Claude Code: `/plugin marketplace add Perennia-Regeneracion/Wachines-Plugin-Ironman`
then `/plugin install`.

**Auto-update.** Plugins do **not** update when you run a skill — they update **at session
startup, and only if the marketplace has `autoUpdate` on** (third-party marketplaces default to
off). To get hands-off updates, declare the marketplace with `autoUpdate` in your
`~/.claude/settings.json` (the team `bin/setup-dev.sh` does this for you):

```json
{
  "extraKnownMarketplaces": {
    "wachines": {
      "source": { "source": "github", "repo": "Perennia-Regeneracion/Wachines-Plugin-Ironman" },
      "autoUpdate": true
    }
  }
}
```

Updates follow the plugin's `version` (in `.claude-plugin/plugin.json`). **You don't bump it by
hand** — a GitHub Action ([`.github/workflows/release.yml`](.github/workflows/release.yml)) computes
the bump on every push to `main`, derived from your Conventional Commits (`feat` → minor, `fix` →
patch, `!`/BREAKING → major), updates the `CHANGELOG.md`, and tags the release. Merge a PR as usual
and the team picks up the new version at their next startup.

> **How the bot pushes to a protected `main`.** `main` is protected by an org ruleset that requires
> PRs, and the default `GITHUB_TOKEN` can't bypass it. The Action mints a token for the
> **`perennia-automerge` GitHub App** (already in the ruleset's bypass list) from the org secrets
> `AUTOMERGE_APP_ID` + `AUTOMERGE_APP_PRIVATE_KEY`, and pushes the bump with that. No per-user PAT,
> nothing to configure — it reuses the org's existing automerge app.

Manual update any time:
`claude plugin marketplace update wachines && claude plugin update Wachines-Plugin-Ironman` (restart to apply).

### Codex & other agents → individual skills (`npx skills`)

Requires Node.js. Install all skills, or pick individual ones:

```bash
# everything
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman

# Codex explicit
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman -g -a codex

# or a single skill
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman/db-reviewer
```

The [`skills` CLI](https://github.com/vercel-labs/skills) drops each skill into your agent's
config dir (`.claude/skills/` for Claude Code, `.agents/skills/` for others). List what you
have with `npx skills list`; search with `npx skills find <query>`.

## Skills in this repo

| Skill | What it does | Origin |
|-------|--------------|--------|
| [`supabase-postgres-best-practices`](skills/supabase-postgres-best-practices) | Postgres performance & schema best practices (8 categories of rules) | Supabase · MIT |
| [`vercel-react-best-practices`](skills/vercel-react-best-practices) | React/Next.js performance rules (57 rules, 8 categories) | Vercel · MIT |
| [`next-best-practices`](skills/next-best-practices) | Next.js conventions: RSC boundaries, data patterns, async APIs, metadata, route handlers, image/font | Compiled from Next.js docs · MIT |
| [`web-design-guidelines`](skills/web-design-guidelines) | Reviews UI code for accessibility & Web Interface Guidelines compliance (fetches the live guidelines) | Vercel · MIT |
| [`frontend-design`](skills/frontend-design) | Builds distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics | Anthropic · Apache-2.0 |
| [`html-perennia`](skills/html-perennia) | Prefer HTML over markdown for human-readable artifacts (plans, reviews, wireframes), with a cohesive earth-green palette | Perennia-Regeneracion · MIT |
| [`tanstack-query-hooks`](skills/tanstack-query-hooks) | Generates TanStack Query hooks: query/mutation hooks, automatic cache invalidation, loading/error states | Perennia-Regeneracion · MIT |
| [`db-reviewer`](skills/db-reviewer) | Reviews SQL migrations: naming, soft delete, `COMMENT ON`, `SECURITY DEFINER`, RLS, performance | Perennia-Regeneracion · MIT |
| [`security-reviewer`](skills/security-reviewer) | Reviews code for OWASP Top 10: injection, XSS, broken auth, secrets, insecure data (+ Supabase checks) | Perennia-Regeneracion · MIT |
| [`docs-architect`](skills/docs-architect) | Audits/creates/reorganizes docs; detects drift between docs and code; enforces a Diátaxis+ADR taxonomy and generated-vs-authored anti-drift rules ([doc-conventions](skills/docs-architect/references/doc-conventions.md)); parallel sub-agent audits | Perennia-Regeneracion · MIT |
| [`rpc-api-contract`](skills/rpc-api-contract) | Standard for exposing business logic as a uniform agent-operable API: `api` schema, `{data,effects,warnings}` envelope, RFC 7807 errors, Idempotency-Key, SECURITY DEFINER, preview/confirm | Perennia-Regeneracion · MIT |
| [`eve`](skills/eve) | Build/edit/debug agents on the eve framework — defers to the version-locked bundled docs (`node_modules/eve/docs`) as the source of truth so guidance never drifts from the installed version | Vercel · Apache-2.0 |
| [`wachi-fabrica`](skills/wachi-fabrica) | El orquestador ("el jefe") de la software factory: clasifica un cambio y rutea la ruta mínima de subagentes/skills hasta el PR | Perennia-Regeneracion · MIT |
| [`wachi-qa`](skills/wachi-qa) | QA funcional de front con motor `agent-browser` + arranque local `portless`/`npm run dev`: prueba como usuario real exigente (botones, forms vacío/inválido/edge, estados, consola, responsive), health score 0-100, arregla en source con commits atómicos. Modo `--report-only` | Perennia-Regeneracion · MIT |
| [`ruuts-api`](skills/ruuts-api) | Convenciones + flujo para contribuir MRs al repo ruuts-api (la API que GRASS consume): los 5 patrones que sus reviews marcan siempre (paridad con el endpoint hermano, errores tipados, concurrencia en batch, cleanup de recursos, reglas de su changelog) + self-review con `/code-review` antes de pedir review | Perennia-Regeneracion · MIT |
| [`rumiando`](skills/rumiando) | Operar RumIAndo (producto interno de gestión): tickets WCH-NNN, fichas, ficheros y releases por RPC del schema `api` (MCP `conector-rumiando`) + el modelo fichero/ficha + la frontera de datos RumIAndo/Brain/Engram. Para el equipo de producto | Perennia-Regeneracion · MIT |

`db-reviewer`, `docs-architect` and `security-reviewer` are also provided as **subagents** in
[`agents/`](agents) for users who prefer the Claude Code subagent form — copy them into your
`.claude/agents/` directory. (The `skills` CLI installs skills, not subagents, so the skill
form is the default installable one.)

### Project overlays

`db-reviewer` and `docs-architect` ship a generic skill **plus** a concrete project config
under `references/`. The Perennia BackOffice overlay
([db-reviewer](skills/db-reviewer/references/perennia-backoffice.md),
[docs-architect](skills/docs-architect/references/perennia-backoffice.md)) wires the generic
checklist to that repo's real domains, soft-delete tables, RLS helpers, and docs layout. Add
your own `references/<project>.md` to specialize a skill for another codebase.

## Agentes vs Skills (cuándo cada uno)

La fábrica tiene dos tipos de pieza. La duda recurrente — "¿por qué esto es agente y aquello skill?":

| | **Skill** (`skills/<n>/SKILL.md`) | **Agente** (`agents/<n>.md`) |
|---|---|---|
| Qué es | Una receta / capacidad | Un operario con un rol (system prompt) |
| Dónde corre | **INLINE**, en el contexto del que la invoca | **AISLADO**, en su propia ventana, en paralelo |
| Cómo se usa | Se **invoca** (Skill tool / trigger) | Se **spawnea** (Task tool) |
| Contexto | Consume el del invocador | No quema el tuyo; devuelve un reporte |
| Ejemplos | `wachi-fabrica`, `wachi-qa`, `db-reviewer`, `security-reviewer` | `db-architect`, `frontend-specialist` |

**En una frase:** el humano invoca skills; el orquestador (`wachi-fabrica`) spawnea agentes. Una skill es la receta; un agente es el operario aislado que la puede seguir.

**Cómo un subagente corre una skill:** hereda el **Skill tool** y los MCP tools por defecto. Con el plugin **instalado** (`npx skills add`), el subagente invoca la skill con el Skill tool (no le pasés el `SKILL.md`); o se **preloadea** con `skills: <n>` en `agents/<n>.md`. Pasar el `SKILL.md` como texto es solo fallback cuando la skill no está instalada. Doctrina completa: `productos/fabrica/agentes-vs-skills.md` (brain del hub).

## gstack — referenced, not bundled

The author's daily driver for browsing, QA, planning, review, and shipping is
[**gstack**](https://github.com/garrytan/gstack) (by Garry Tan, MIT).

gstack is **not** vendored here on purpose: its skills are **not standalone** — they depend
on the gstack runtime (its binaries, the browse daemon, its TypeScript sources). Copying only
the `SKILL.md` files would produce broken skills. Install it directly instead — that gives you
**all** of its skills at once:

> `autoplan` · `benchmark` · `benchmark-models` · `browse` · `canary` · `careful` · `codex` ·
> `connect-chrome` · `context-restore` · `context-save` · `cso` · `design-consultation` ·
> `design-html` · `design-review` · `design-shotgun` · `devex-review` · `document-generate` ·
> `document-release` · `freeze` · `gstack-upgrade` · `guard` · `health` · `investigate` ·
> `ios-clean` · `ios-design-review` · `ios-fix` · `ios-qa` · `ios-sync` · `land-and-deploy` ·
> `landing-report` · `learn` · `make-pdf` · `office-hours` · `open-gstack-browser` ·
> `pair-agent` · `plan-ceo-review` · `plan-design-review` · `plan-devex-review` ·
> `plan-eng-review` · `plan-tune` · `qa` · `qa-only` · `retro` · `review` · `scrape` ·
> `setup-browser-cookies` · `setup-deploy` · `setup-gbrain` · `ship` · `skillify` ·
> `sync-gbrain` · `unfreeze`

(53 skills — the full set, kept in sync upstream. That's exactly why this repo references
gstack instead of copying a snapshot that would go stale.)

**Install gstack** (Claude Code, ~30s — needs [Bun](https://bun.sh/) v1.0+):

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup
```

Then run `/gstack-upgrade` any time to update. See the
[gstack README](https://github.com/garrytan/gstack) for team mode and other agents
(Codex, OpenCode, etc.).

## Kapso — WhatsApp, referenced not bundled

For WhatsApp integration, automation, and troubleshooting, Kapso publishes its own official
skills at [**gokapso/agent-skills**](https://github.com/gokapso/agent-skills) — install them
straight from the source (they need a Kapso account + API key, and are maintained upstream, so
this repo doesn't vendor them):

```bash
npx skills add gokapso/agent-skills
```

Three skills: `integrate-whatsapp` (connect WhatsApp, webhooks, send messages/templates,
flows), `automate-whatsapp` (workflows, agents, functions, databases), and `observe-whatsapp`
(debug delivery, inspect webhooks, triage errors, health checks). There's also a CLI —
`kapso login` / `kapso status` — see the [Kapso CLI docs](https://docs.kapso.ai/docs/whatsapp/cli).

## Chat SDK — multi-platform bots, referenced not bundled

Vercel's [Chat SDK](https://chat-sdk.dev) ships a skill for building bots across Slack, Teams,
Discord, Telegram, WhatsApp, and more on top of the AI SDK. Like the Kapso skills, it's a thin
pointer to docs that live inside the `chat` npm package, so it's installed from the source
(MIT, maintained upstream) rather than vendored here:

```bash
npx skills add vercel/chat
```

## Contributing

Open a branch and propose a skill via PR — see [CONTRIBUTING.md](CONTRIBUTING.md). The bar:
project-agnostic, well-described (the `description` is a routing rule, not a title), and
licensed for redistribution.

## Licensing

This repo is MIT (see [LICENSE](LICENSE)). Bundled third-party skills keep their original
authorship and MIT licenses — full details and sources in [ATTRIBUTION.md](ATTRIBUTION.md).
