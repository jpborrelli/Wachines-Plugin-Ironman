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
| [`db-reviewer`](skills/db-reviewer) | Reviews SQL migrations: naming, soft delete, `COMMENT ON`, `SECURITY DEFINER`, RLS, performance | perennia-regen · MIT |
| [`docs-architect`](skills/docs-architect) | Audits/creates/reorganizes docs; detects drift between docs and code; parallel sub-agent audits | perennia-regen · MIT |

`db-reviewer` and `docs-architect` are also provided as **subagents** in [`agents/`](agents)
for users who prefer the Claude Code subagent form. Copy them into your `.claude/agents/`
directory. (The `skills` CLI installs skills, not subagents, so the skill form is the
default installable one.)

## gstack — referenced, not bundled

The author's daily driver for browsing, QA, planning, review, and shipping is
[**gstack**](https://github.com/garrytan/gstack) (by Garry Tan, MIT) — skills like
`/browse`, `/qa`, `/ship`, `/review`, `/investigate`, `/office-hours`, `/plan-ceo-review`,
`/codex`, and many more.

gstack is **not** vendored here on purpose: its skills are **not standalone** — they depend
on the gstack runtime (its binaries, the browse daemon, its TypeScript sources). Copying only
the `SKILL.md` files would produce broken skills. Install it directly instead.

**Install gstack** (Claude Code, ~30s — needs [Bun](https://bun.sh/) v1.0+):

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup
```

Then run `/gstack-upgrade` any time to update. See the
[gstack README](https://github.com/garrytan/gstack) for team mode and other agents
(Codex, OpenCode, etc.).

## Contributing

Open a branch and propose a skill via PR — see [CONTRIBUTING.md](CONTRIBUTING.md). The bar:
project-agnostic, well-described (the `description` is a routing rule, not a title), and
licensed for redistribution.

## Licensing

This repo is MIT (see [LICENSE](LICENSE)). Bundled third-party skills keep their original
authorship and MIT licenses — full details and sources in [ATTRIBUTION.md](ATTRIBUTION.md).
