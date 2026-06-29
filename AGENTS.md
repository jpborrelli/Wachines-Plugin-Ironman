# AGENTS.md — Wachines-Plugin-Ironman

> Agent-facing guide for the `Wachines-Plugin-Ironman` repository (formerly `wachines-skills`). Read this first if you are going to edit, add, or release a skill/agent in this repo.

## Project overview

`Wachines-Plugin-Ironman` is a curated, installable collection of [Agent Skills](https://github.com/vercel-labs/skills) and Claude Code subagents for shipping web apps and databases. It is published as:

- a **Claude Code plugin** (`Wachines-Plugin-Ironman`) via the `.claude-plugin/` marketplace manifest;
- an **`npx skills` installable repo** for Codex and any other agent that supports the open Skills standard.

The content is project-agnostic by design: no private domains, table names, internal URLs, or absolute paths. Skills live under `skills/<name>/SKILL.md`; subagents live under `agents/<name>.md`. Shared behavior for subagents is factored into `_shared/agent-spine.md`.

This repo contains **no compiled runtime** and no traditional package manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, etc.). The deliverables are Markdown instruction files, JSON plugin manifests, and a small set of Node/Bash automation scripts.

## Repository layout

```
.
├── .claude-plugin/          # Claude Code plugin marketplace manifests
│   ├── marketplace.json     # registry entry for the "wachines" marketplace
│   └── plugin.json          # plugin metadata + version (auto-bumped by CI)
├── .github/
│   ├── workflows/           # release + smoke-agent-browser CI
│   └── CODEOWNERS           # requires @Perennia-Regeneracion/maintainers review
├── _shared/
│   └── agent-spine.md       # shared behavior/voice for subagents
├── agents/                  # Claude Code subagent definitions
│   ├── db-architect.md
│   ├── db-reviewer.md
│   ├── frontend-specialist.md
│   └── security-reviewer.md
├── bin/                     # repo automation scripts
│   ├── release-bump.mjs     # Conventional Commit → semver bump + CHANGELOG
│   └── setup-dev.sh         # one-shot dev toolchain installer for the team
├── infra/
│   ├── browser/
│   │   └── agent-browser.json   # pinned browser engine for wachi-qa
│   └── engram-cloud/        # Fly.io deployment files for shared Engram memory
├── skills/                  # all installable skills
│   ├── <name>/
│   │   ├── SKILL.md         # required skill entrypoint
│   │   ├── references/      # optional deep-dive docs
│   │   ├── assets/          # optional templates/scripts
│   │   └── ...
│   └── ...
├── AGENTS.md                # this file
├── ATTRIBUTION.md           # third-party skill authorship & licenses
├── CHANGELOG.md             # auto-generated release notes
├── CONTRIBUTING.md          # contribution bar & SKILL.md format
├── LICENSE                  # MIT (repo); bundled skills keep their own licenses
├── README.md                # user-facing install guide
├── SETUP.md                 # team-internal toolchain setup (Spanish)
└── renovate.json            # dependency automation (only agent-browser pin today)
```

## Technology stack & runtime

- **Primary format:** Markdown with YAML frontmatter (skills and agents).
- **Automation:** Node.js ≥20 (`.mjs` scripts), Bash (`setup-dev.sh`), GitHub Actions.
- **Plugin ecosystem:** Claude Code plugin API, `npx skills` CLI from Vercel Labs.
- **External tooling referenced but not bundled:**
  - [gstack](https://github.com/garrytan/gstack) — browse, QA, ship, review, planning skills.
  - [gokapso/agent-skills](https://github.com/gokapso/agent-skills) — WhatsApp integration/automation/observe skills.
  - [vercel/chat](https://github.com/vercel/chat) — Chat SDK skill.
  - `agent-browser` (vercel-labs) — browser engine pinned in `infra/browser/agent-browser.json`.
- **Shared memory:** Engram (cloud server at `wachines-engram-cloud.fly.dev`).

## Build / test / validate commands

There is no compile step. Use these commands to validate the repo before pushing:

```bash
# Validate all JSON manifests
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'))"
node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8'))"
node -e "JSON.parse(require('fs').readFileSync('infra/browser/agent-browser.json','utf8'))"

# Dry-run the release bump logic
node bin/release-bump.mjs --dry-run

# Install a single skill in a scratch directory to confirm it is clean
npx skills add Perennia-Regeneracion/Wachines-Plugin-Ironman/<skill-name>
```

No unit-test suite exists because the deliverables are agent instructions. The real test is the **CI smoke test** for the browser engine and the **manual install check** described in `CONTRIBUTING.md`.

## How to add or edit a skill

1. Branch from `main`: `git checkout -b skill/<your-skill-name>`.
2. Create or edit `skills/<name>/SKILL.md`.
3. Keep deep material in sibling files under the same skill folder (`references/`, `assets/`, `templates/`, etc.).
4. Follow the frontmatter contract (see below).
5. Update `ATTRIBUTION.md` if the skill is adapted from a third party.
6. Open a PR. `CODEOWNERS` requires approval from `@Perennia-Regeneracion/maintainers`.

### Skill frontmatter contract

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: my-skill-name              # lowercase, hyphens, matches folder name
description: >-                  # routing rule — the agent decides to invoke from this line
  What this skill does AND when to use it.
  Use concrete triggers ("Use when…"), not titles.
license: MIT                     # or the actual license for third-party skills
metadata:
  author: your-handle
  version: "1.0.0"
---
```

Important notes:

- `description` is the most important field. It is a trigger, not a marketing title. If it contains `:` inside a value, quote or fold the string to keep YAML valid (see `wachi-fabrica` for the quoted example).
- `name` must match the directory name.
- Third-party skills must preserve their original license and authorship; add them to `ATTRIBUTION.md`.

## Code style & conventions

- **Language of docs:** user-facing docs (`README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`) are in English; team-internal setup docs (`SETUP.md`, workflow comments, scripts) are in Spanish. Match the file you are editing.
- **Skill voice:** most skills are imperative, direct, and avoid AI-slop vocabulary (`delve`, `robust`, `comprehensive`, etc.). The subagent spine in `_shared/agent-spine.md` formalizes this voice.
- **Project-agnostic rule:** no company names, private table names, internal URLs, or hardcoded absolute paths in generic skills. Project-specific overlays go under `skills/<name>/references/<project>.md` (e.g., `references/perennia-backoffice.md`).
- **File naming:** skill folders are `kebab-case`; subagent files are `kebab-case.md`; reference files are `kebab-case.md`.
- **No vendored runtimes:** skills that need an external binary/daemon (gstack, agent-browser if pinned elsewhere, Kapso, Chat SDK) are referenced, not copied.
- **Frontmatter style:** use `>-` or quoted scalars for long descriptions to avoid colon-in-value YAML breakage.

## Release & deployment

The repo is released as a Claude Code plugin and as a tag.

- **Version source of truth:** `.claude-plugin/plugin.json` → `version`.
- **Auto-bump:** on every push to `main`, `.github/workflows/release.yml` runs `node bin/release-bump.mjs`.
  - Derives bump from Conventional Commits since the last tag: `feat` → minor, `fix` → patch, `!`/`BREAKING` → major.
  - Updates `plugin.json` and prepends to `CHANGELOG.md`.
  - Tags `Wachines-Plugin-Ironman--vX.Y.Z` (legacy `wachines-skills--vX.Y.Z` tags remain reachable).
  - Pushes using a token minted for the `perennia-automerge` GitHub App to bypass the protected-branch ruleset.
  - Bot commits use prefix `chore(release):`; the workflow skips them to avoid loops.
- **Manual plugin update:** `claude plugin marketplace update wachines && claude plugin update Wachines-Plugin-Ironman` (restart Claude Code to apply).
- **Engram cloud deployment:** `cd infra/engram-cloud && fly deploy`.

## Testing & CI

Two GitHub Actions workflows run in this repo:

1. **release** — auto-bumps plugin version on every push to `main`.
2. **smoke-agent-browser** — safety net for the pinned `agent-browser` engine.
   - Triggered on PRs touching `infra/browser/agent-browser.json`, `skills/wachi-qa/**`, or the workflow itself; also on pushes to `main` that change the pin.
   - Installs the pinned `agent-browser` version + Chromium.
   - Exercises the command mapping that `wachi-qa` relies on (`open`, `snapshot -i`, `get`, `find role click`, `fill`, `console`, `screenshot`).
   - If Renovate auto-merges a broken bump, this smoke fails and blocks the merge.

## Security considerations

- **No secrets in the repo.** `.gitignore` excludes `.env`, `.env.*`, `*.log`, and `node_modules/`.
- **Token handling:** CI uses org-level secrets `AUTOMERGE_APP_ID` and `AUTOMERGE_APP_PRIVATE_KEY`. Never commit token values.
- **Skill content:** skills that review security (`security-reviewer`, `db-reviewer`) include guidance on OWASP Top 10, RLS, `SECURITY DEFINER` + `SET search_path`, and secret scanning. They are instructions, not enforcement code.
- **Third-party redistribution:** only skills with redistribution-friendly licenses are bundled. Authorship and original licenses are preserved in `ATTRIBUTION.md` and each skill's frontmatter.

## Useful references

| What | Where |
|---|---|
| Skill format & bar | `CONTRIBUTING.md` |
| Plugin manifest schema | `.claude-plugin/plugin.json` |
| Marketplace registry | `.claude-plugin/marketplace.json` |
| Release automation | `.github/workflows/release.yml`, `bin/release-bump.mjs` |
| Browser engine pin | `infra/browser/agent-browser.json` |
| Subagent shared voice | `_shared/agent-spine.md` |
| Attribution & licenses | `ATTRIBUTION.md` |
| Team setup (Spanish) | `SETUP.md` |
| User install guide | `README.md` |

## Gotchas for agents

- **No `package.json`.** Do not assume npm/pnpm/bun install is needed for this repo itself. Scripts are zero-dependency Node/Bash.
- **Skills are not edited inside consuming projects.** Shared skills live here and are installed via `npx skills add` or the Claude Code plugin. Project-specific skills belong in the project repo.
- **Do not manually bump `plugin.json` version.** The release bot does it from Conventional Commits.
- **`CHANGELOG.md` below `0.2.0` is auto-generated.** Do not hand-edit entries above the `0.1.0` baseline unless the bot has not run yet and you need a manual note.
- **`agents/*.md` are subagents, not skills.** They run isolated (Task tool); skills run inline (Skill tool). The `wachi-fabrica` skill documents the orchestration pattern.
