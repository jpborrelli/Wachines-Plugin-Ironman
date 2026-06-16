---
name: agent-readiness
description: Assess how ready a codebase is for autonomous AI coding agents — by delegating a deep investigation of each of Factory.ai's 8 readiness pillars to a dedicated subagent, then cross-referencing their reports into a score across 5 maturity levels with a prioritized, concrete fix list. Use when asked to "check agent readiness", "is this repo agent-ready", "readiness report/score", "/readiness", "how well does this repo support AI agents", or to audit a repo's dev environment for agent autonomy.
metadata:
  author: perennia-regen
  version: "2.0.0"
license: MIT
---

# Agent Readiness

> "The agent is not broken. The environment is." — Factory.ai

Measure how well a repository supports autonomous AI coding agents, and report **what to fix first**. Based on Factory.ai's [Agent Readiness](https://factory.ai/news/agent-readiness) framework: 8 pillars, 5 gated maturity levels.

**This is an investigation, not a checklist run.** A score from file-existence alone is shallow — a linter nobody runs, a stale `.env.example`, or snapshot-only tests all "exist" yet leave the environment broken for an agent. So you **delegate a deep, qualitative investigation of each pillar to a dedicated subagent**, then you (the orchestrator) cross-reference their reports into a single, defensible score.

Why fan out: each pillar needs real reading — is the linter wired into CI and pre-commit, or just a dangling config? Are the docs accurate against the code, or stale? Do tests assert behavior, or are they filler? One agent can't hold eight deep investigations at once. Subagents keep each one thorough and independent; you stay the synthesizer.

- Framework background (pillars, failure modes, levels): [references/factory-framework.md](references/factory-framework.md)
- Per-pillar investigation briefs (what each subagent must dig into): [references/pillar-briefs.md](references/pillar-briefs.md)

## Workflow

### Step 0 — (optional) fast inventory
Run the bundled helper for a quick map of which configs/files exist:

```bash
bash scripts/readiness.sh <repo-path>
```

This is a **starting signal only, not the score** — a convenience to hand the subagents so they don't start blind. Skip it if you prefer; the verdict comes from the investigation, not this script.

### Step 1 — fan out: one subagent per pillar
Spawn **8 subagents in parallel** (Task/Agent tool — `Explore` or `general-purpose`), one per Factory pillar:

> Style & Validation · Build System · Testing · Documentation · Dev Environment · Observability · Security & Governance · Task Discovery

Give each subagent its brief from [references/pillar-briefs.md](references/pillar-briefs.md) plus the repo path (and the Step 0 inventory if you ran it). Each subagent must:

1. **Investigate deeply** — read the actual configs, sample real source/test/doc files, inspect CI workflows and hooks. Not file-existence; *behavior*.
2. **Judge quality, not just presence** — does the signal actually work for an agent? (config wired in? docs accurate? tests meaningful? every env var documented?)
3. **Return a structured report** (schema below) with per-criterion verdicts, **evidence (file paths)**, a quality note, and concrete fixes.

### Step 2 — cross-reference + score (you, the orchestrator)
Collect the 8 reports. Then synthesize — **your judgment overrides any single subagent**:

- **Reconcile** overlaps and contradictions. Examples: the Docs agent found an `AGENTS.md` the Style agent didn't see; the CI agent counted a "test" run that the Testing agent judged meaningless; two agents both claim the pre-commit hook. Resolve to one truth; don't double-count.
- For each pillar, settle a `pass / partial / fail` per criterion → a **pillar %** (count `partial` as 0.5).
- Apply the **5 gated levels** (Functional → Documented → Standardized → Optimized → Autonomous): a level is reached at **≥80%** of its criteria **and** all lower levels'. The criteria→level map is in [references/pillar-briefs.md](references/pillar-briefs.md).

### Step 3 — report
1. **Scorecard** — a table: per-pillar % and the level reached.
2. **Level + gap** — what blocks the next level.
3. **What to fix first** — the failing criteria of the lowest incomplete level, **each with a specific, concrete fix** ("add `playwright.config.ts` + one smoke E2E", not "improve testing"). Order by leverage: gating + cheap wins first (a missing `LICENSE` can hold a rich repo at Level 0).
4. **Confidence** — flag what a subagent *inferred* vs *verified*; note any pillar where the subagents disagreed and how you resolved it.

## Subagent report schema

Ask each pillar subagent to return exactly this (use the Task tool's structured-output / schema option if available):

```yaml
pillar: <name>
criteria:
  - id: <criterion, e.g. "L3 pre-commit hooks">
    verdict: pass | partial | fail
    evidence: <file path(s), config snippet, or why it fails>
  # ... one per criterion in this pillar's brief
quality_note: <1-2 sentences: genuinely solid, or present-but-hollow? what's the real failure mode here?>
top_fixes:
  - <concrete, specific fix>
```

## Notes

- **Scale to the repo.** A tiny repo can group several pillars into fewer subagents; a monorepo may need each subagent to cover every app, or one subagent per app per pillar — decide and say so.
- **The script is a convenience, never the authority.** The score is your synthesis of the investigations.
- Stay honest: presence ≠ quality, and "Level N" is a claim you should be able to defend from the evidence.

## Credits

Framework © [Factory.ai](https://factory.ai/news/agent-readiness) (Agent Readiness). Pillar/level taxonomy also informed by the open-source `@kodus/agent-readiness` and `jpequegn/agent-readiness-score`. Original work, MIT.
