# Changelog

Releases of the `Wachines-Plugin-Ironman` Claude Code plugin (formerly `wachines-skills`). **Entries below `0.2.0` are written
automatically** by the `release` GitHub Action on every push to `main` (version bump derived from
Conventional Commits); with `autoUpdate` on, the team picks up the new version at the next session
startup. No manual bump needed.

## 0.4.3 — 2026-06-30

- chore(deps): update actions/setup-node action to v6 (#33)

## 0.4.2 — 2026-06-30

- chore(deps): update dependency node to v24 (#30)

## 0.4.1 — 2026-06-30

- chore(deps): update actions/setup-node action to v6 (#29)

## 0.4.0 — 2026-06-30

- feat(engram): use current repo names as Engram project keys (#32)

## 0.3.3 — 2026-06-29

- chore(rename): align references with Wachines-Plugin-Ironman repo (#31)

## 0.3.2 — 2026-06-29

- chore(deps): update actions/checkout action to v7 (#26)

## 0.3.1 — 2026-06-27

- chore(renovate): mode full — salir de Silent y crear PRs (#25)

## 0.3.0 — 2026-06-27

- feat(fabrica): pinear agent-browser (vendor vercel-labs) con auto-update (#24)

## 0.2.0 — 2026-06-27

- feat(ci): pushear el bump de release con la GitHub App perennia-automerge (#23)
- fix(ci): gate del push de release tras RELEASE_TOKEN (main protegida por ruleset org) (#22)
- fix(ci): filtro del bump por prefijo exacto, no por mención del marcador (#21)
- fix(ci): quitar [skip release] redundante del commit del bot (#20)

## 0.1.0

- **Repo is now a Claude Code plugin + marketplace** (`.claude-plugin/`). One install brings all
  skills **and** the `db-architect` / `frontend-specialist` / `db-reviewer` / `security-reviewer`
  subagents. The `npx skills` path is unchanged for Codex and other agents.
- `bin/setup-dev.sh`: Claude Code now gets Wachines-Plugin-Ironman via the plugin (marketplace registered
  with `autoUpdate: true`); Codex/others stay on `npx`.
- Fix: `wachi-fabrica` had a broken YAML frontmatter (an embedded `: ` in the description) that
  dropped its metadata at runtime — the skill never auto-invoked. Now quoted.
- `_spine.md` moved out of `agents/` to `_shared/agent-spine.md` so it is no longer loaded as a
  phantom subagent.
