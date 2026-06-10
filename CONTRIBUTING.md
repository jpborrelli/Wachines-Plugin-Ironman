# Contributing

Thanks for proposing a skill! The goal of this repo is a small, high-quality, **project-agnostic**
set of skills anyone can install with `npx skills add perennia-regen/wachines-skills`.

## Propose a skill (PR flow)

1. Fork or branch: `git checkout -b skill/<your-skill-name>`.
2. Create `skills/<your-skill-name>/SKILL.md` (plus any reference `.md` files the skill needs
   in that same folder).
3. Open a PR describing what the skill does and when it should trigger.

## SKILL.md format

Minimal valid skill — a folder with a `SKILL.md` that has YAML frontmatter:

```markdown
---
name: my-skill
description: What this skill does AND when to use it. This is a routing rule, not a title — the agent decides whether to activate the skill almost entirely from this line, so be concrete about triggers.
metadata:
  author: your-handle
  version: "1.0.0"
license: MIT
---

# My Skill

Instructions the agent follows when this skill activates.
```

- `name`: lowercase, hyphens, matches the folder name.
- `description`: the single most important field — write it as a trigger ("Use when…",
  with concrete verbs and nouns), not as a title.
- Keep larger material in sibling `.md` files inside the skill folder and reference them from
  `SKILL.md`, so the main file stays lean.

## The bar for acceptance

- **Project-agnostic.** No company names, private domain/table names, internal URLs, or
  hardcoded absolute paths. If your skill needs project specifics, make them *configurable*
  and show a generic example (see `db-reviewer` for the pattern).
- **Redistributable license.** First-party skills are MIT. If you adapt a third-party skill,
  it must permit redistribution; add it to [ATTRIBUTION.md](ATTRIBUTION.md) with author,
  license, and source, and keep its license fields intact.
- **Not a runtime dependency dump.** If a skill only works with an external binary/daemon
  (the way gstack does), reference it in the README rather than vendoring broken files.
- **Tested.** Confirm it installs cleanly:
  `npx skills add perennia-regen/wachines-skills/<your-skill>` in a scratch directory.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`,
`chore:`, `refactor:`.
