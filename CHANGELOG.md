# Changelog

Releases of the `wachines-skills` Claude Code plugin. Bump `version` in
`.claude-plugin/plugin.json` per release; with `autoUpdate` on, the team picks up the new
version at the next session startup.

## 0.1.0

- **Repo is now a Claude Code plugin + marketplace** (`.claude-plugin/`). One install brings all
  skills **and** the `db-architect` / `frontend-specialist` / `db-reviewer` / `security-reviewer`
  subagents. The `npx skills` path is unchanged for Codex and other agents.
- `bin/setup-dev.sh`: Claude Code now gets wachines-skills via the plugin (marketplace registered
  with `autoUpdate: true`); Codex/others stay on `npx`.
- Fix: `wachi-fabrica` had a broken YAML frontmatter (an embedded `: ` in the description) that
  dropped its metadata at runtime — the skill never auto-invoked. Now quoted.
- `_spine.md` moved out of `agents/` to `_shared/agent-spine.md` so it is no longer loaded as a
  phantom subagent.
