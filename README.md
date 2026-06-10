# wachines-skills

A curated, installable set of [Agent Skills](https://github.com/vercel-labs/skills) for
Claude Code (and any agent that supports the open Skills standard). Hand-picked tools for
shipping quality web apps and databases: Postgres/Supabase best practices, React/Next.js
performance, a SQL-migration reviewer, and a documentation architect.

Project-agnostic by design — no company-, domain-, or schema-specific content. Add the ones
you want, contribute the ones you wish existed.

## Install

Requires Node.js. Install all skills, or pick individual ones:

```bash
# everything
npx skills add perennia-regen/wachines-skills

# or a single skill
npx skills add perennia-regen/wachines-skills/db-reviewer
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
| [`html-perennia`](skills/html-perennia) | Prefer HTML over markdown for human-readable artifacts (plans, reviews, wireframes), with a cohesive earth-green palette | perennia-regen · MIT |
| [`tanstack-query-hooks`](skills/tanstack-query-hooks) | Generates TanStack Query hooks: query/mutation hooks, automatic cache invalidation, loading/error states | perennia-regen · MIT |
| [`db-reviewer`](skills/db-reviewer) | Reviews SQL migrations: naming, soft delete, `COMMENT ON`, `SECURITY DEFINER`, RLS, performance | perennia-regen · MIT |
| [`security-reviewer`](skills/security-reviewer) | Reviews code for OWASP Top 10: injection, XSS, broken auth, secrets, insecure data (+ Supabase checks) | perennia-regen · MIT |
| [`docs-architect`](skills/docs-architect) | Audits/creates/reorganizes docs; detects drift between docs and code; parallel sub-agent audits | perennia-regen · MIT |

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

## Contributing

Open a branch and propose a skill via PR — see [CONTRIBUTING.md](CONTRIBUTING.md). The bar:
project-agnostic, well-described (the `description` is a routing rule, not a title), and
licensed for redistribution.

## Licensing

This repo is MIT (see [LICENSE](LICENSE)). Bundled third-party skills keep their original
authorship and MIT licenses — full details and sources in [ATTRIBUTION.md](ATTRIBUTION.md).
