---
name: agent-readiness
description: Assess how ready a codebase is for autonomous AI coding agents — score it across 8 pillars and 5 maturity levels (Factory.ai's Agent Readiness framework) and report what to fix first, each with a concrete fix. Use when asked to "check agent readiness", "is this repo agent-ready", "readiness report/score", "/readiness", "how well does this repo support AI agents", or to audit a repo's dev environment for agent autonomy.
metadata:
  author: perennia-regen
  version: "1.0.0"
license: MIT
---

# Agent Readiness

> "The agent is not broken. The environment is." — Factory.ai

Measure how well a repository supports autonomous AI coding agents, and tell the user **what to fix first**. Based on Factory.ai's [Agent Readiness](https://factory.ai/news/agent-readiness) framework: 8 pillars, 5 gated maturity levels. This skill combines a deterministic scan with the qualitative judgment a script can't do.

Full framework background (pillars, failure modes, levels): [references/factory-framework.md](references/factory-framework.md).

## When this runs

The user wants to evaluate a repo's readiness for agents, run a readiness report/score, or audit dev-environment quality for autonomy. Target = the current repo unless a path is given.

## The two layers — do both

A real readiness assessment combines **objective signals** with **judgment**. A score from file-existence alone is shallow; judgment alone is unrepeatable. Layer them.

### 1. Deterministic scan (objective baseline)

Run the bundled scanner for the binary file/config signals (linters, formatters, type-checking, CI, tests, lock files, AI-context files, env docs, security tooling, templates, agent memory):

```bash
bash scripts/readiness.sh <path-to-repo>     # defaults to "."
```

It prints a per-pillar score, the maturity level reached (80%-gated), and the failing checks of the lowest incomplete level. The scanner is multi-language and project-agnostic. Read its output as the objective baseline.

### 2. Qualitative review (judgment — what the script can't see)

**Presence ≠ quality.** A linter config that nobody runs, a stale `.env.example`, or snapshot-only tests all *pass* the file check but leave the environment broken for an agent. After the scan, open the key files and judge:

- **Documentation effectiveness** — does `README` / `AGENTS.md` / `CLAUDE.md` actually let a cold agent get productive, or is it stale vs the code? Is setup reproducible from it alone?
- **Test meaningfulness** — do tests assert real behavior, or are they smoke/snapshot filler? Is the critical business logic covered?
- **Naming & structure consistency** — can an agent predict where things live?
- **Env-var completeness** — is *every* required variable documented, not just a subset?
- **Feedback-loop friction** — fast local checks (pre-commit) or a 10-minute CI round-trip? Are errors/logs legible to an agent?

These mirror Factory's "[AI]" checks. Weight them into the pillar verdicts: a pillar that passes the file check but fails judgment is **not** really ready — say so.

## Scoring model

- **8 pillars:** Style & Validation · Build System · Testing · Documentation · Dev Environment · Observability · Security & Governance · Task Discovery.
- **5 levels (gated):** Functional → Documented → **Standardized (target)** → Optimized → Autonomous. You reach a level only by passing **≥80%** of its checks **and** all lower levels'. Level 3 is the minimum bar for production-grade autonomous work.
- Cheap gating gaps matter: a missing `.editorconfig` or `LICENSE` can hold a rich repo at Level 0. Surface those first — they're the highest-leverage fixes.

## Output

Report, concisely:

1. **Scorecard** — per-pillar % and the level reached (a table).
2. **Level + gap** — what's blocking the next level.
3. **What to fix first** — the failing checks of the lowest incomplete level, **each with a specific, concrete fix** — not "improve testing" but "add a `playwright.config.ts` + one smoke E2E", not "add security" but "add a `.github/dependabot.yml`". Order by leverage (gating + cheap first).

Stay honest: the scan detects *presence*, not *quality* — state what you verified deterministically vs. judged. Don't inflate a level the qualitative review contradicts.

## Credits

Framework © Factory.ai (Agent Readiness). Detection design also informed by the open-source `@kodus/agent-readiness` and `jpequegn/agent-readiness-score`. The bundled scanner is original work, MIT.
