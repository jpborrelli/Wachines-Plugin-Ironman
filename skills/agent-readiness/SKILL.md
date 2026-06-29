---
name: agent-readiness
description: Assess how ready a codebase is for autonomous AI coding agents — by delegating a deep investigation of each of Factory.ai's 9 readiness pillars (~80 criteria) to a dedicated subagent, then cross-referencing their reports into a pass-rate + maturity level with a prioritized, concrete fix list. Use when asked to "check agent readiness", "is this repo agent-ready", "readiness report/score", "/readiness", "how well does this repo support AI agents", or to audit a repo's dev environment for agent autonomy.
metadata:
  author: Perennia-Regeneracion
  version: "3.0.0"
license: MIT
---

# Agent Readiness

> "The agent is not broken. The environment is." — Factory.ai

Measure how well a repository supports autonomous AI coding agents, and report **what to fix first**. Based on Factory.ai's [Agent Readiness](https://factory.ai/news/agent-readiness) framework — **9 pillars, ~80 criteria**, scored as a pass-rate and mapped to 5 gated maturity levels. The criterion catalog in [references/pillar-briefs.md](references/pillar-briefs.md) is reverse-engineered from Factory's public reports (`factory.ai/agent-readiness/fastapi_fastapi`, `cockroachdb_cockroach`, …).

**This is an investigation, not a checklist run.** A score from file-existence alone is shallow — a linter nobody runs, a stale `.env.example`, or snapshot-only tests all "exist" yet leave the environment broken for an agent. So you **delegate a deep, qualitative investigation of each pillar to a dedicated subagent**, then you (the orchestrator) cross-reference their reports into a single, defensible score.

Why fan out: each pillar needs real reading — is the linter wired into CI and pre-commit, or just a dangling config? Are the docs accurate against the code, or stale? Do tests assert behavior, or are they filler? One agent can't hold nine deep investigations at once. Subagents keep each one thorough and independent; you stay the synthesizer.

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
Spawn **9 subagents in parallel** (Task/Agent tool — `Explore` or `general-purpose`), one per Factory pillar:

> Style & Validation · Build System · Testing · Documentation · Dev Environment · Debugging & Observability · Security · Task Discovery · Product & Analytics

Give each subagent **its pillar's criterion table** from [references/pillar-briefs.md](references/pillar-briefs.md) plus the repo path. **If you ran Step 0, hand each subagent its own pillar's presence line framed as "confirm or refute"** — e.g. "a presence-only scan scored this pillar 4/4; verify with quality judgment." This anchors the investigation and surfaces both false positives (scored present but hollow) and false negatives (scored absent but real in another form). Each subagent must:

1. **Investigate deeply** — read the actual configs, sample real source/test/doc files, inspect CI workflows and hooks. Not file-existence; *behavior*.
2. **Verdict every criterion `pass` / `fail` / `skip`** — `skip` only when the criterion genuinely doesn't apply to this repo type (library has no DB → skip `database_schema`; say why). `skip` is excluded from the score, not a penalty. **Do the bold cross-checks in the brief** (diff `env_template` against env reads; open ≥3 test files; verify `agents_md` claims resolve; grep for committed secrets) — that's where the real findings come from.
3. **Return a structured report** (schema below) with per-criterion verdicts and **one-line evidence (file path)**. (Verdict your own criteria; don't compute the overall score — that's the orchestrator's job.)

### Step 2 — cross-reference + score (you, the orchestrator)
Collect the 9 reports. Then synthesize — **your judgment overrides any single subagent**:

1. **Reconcile** overlaps and contradictions. Examples: the Docs agent found an `AGENTS.md` the Style agent didn't see; the CI agent counted a "test" the Testing agent judged meaningless. Resolve to one truth; don't double-count. Also sanity-check `skip`s: a criterion one agent skipped may actually apply.
2. **Pass rate = passing / applicable** (applicable = pass + fail; **skips are excluded from the denominator**). Compute it per pillar (e.g. "Testing 5/7 = 71%") and overall (e.g. "31/59 = 53%"). This is the headline metric, Factory-style.
3. **Level (1–5), gated.** Criteria are level-tagged in the catalog. Regroup *all* applicable criteria by level tag and find the highest level where its criteria mostly pass (~75%+) **and** every lower level does too. Observed bands as a sanity check: **Level 3 ≈ 53–59% overall, Level 4 ≈ 65–74%**. The pass rate and the level are different lenses — report both.

> **Worked example (FastAPI, from Factory's public report).** 31/59 applicable criteria pass = **53%**. L1–L2 criteria nearly all pass, L3 clears its bar but L4 criteria (coverage automation, observability, security scanning) mostly fail → **Level 3**. Several criteria are `skip` (no database → `database_schema`, `n_plus_one_detection`; library → `dast_scanning`, `health_checks`) and don't count against it. A repo can post a "low" pass rate yet still be Level 3 because the *unmet* criteria are advanced (L4–L5), not foundational.

### Step 3 — report
The report is about **what was investigated and what was found** — a readiness assessment of the repo, not a story about your method. Don't frame it as "investigation vs. a script" or dwell on how the score was computed; just report the findings. Structure:

1. **Result + scorecard** — the level reached, the **overall pass rate** (passing/applicable), and a per-pillar table (pass rate + one-line status).
2. **Per-area detail** (the body) — one section per pillar. For each: its failure mode in one line, and a table of `criterion · verdict (✓/✗/—) · evidence (file path)` — every criterion, with the `—` skips marked "N/A: <why>" — plus a one-line finding. This is the detail a reader wants: which specific things were checked in each area and what came back.
3. **Level + what blocks the next** — the failing criteria of the lowest incomplete level.
4. **What to fix first** — those failing criteria, **each with a specific, concrete fix** ("add `playwright.config.ts` + one smoke E2E", not "improve testing"). Order by leverage: gating + cheap wins first (a missing `LICENSE` can hold a rich repo at Level 0).

Keep it honest: note where a verdict was *inferred* vs *verified*, and where subagents disagreed and how you resolved it — but inline, not as a meta-section.

### Step 4 — persist the report (dated)
Readiness is a trend, not a one-off — Factory's whole point is the compounding loop (better env → more productive agents → time to improve env). So **save the report with the date** so progress is trackable:

- Prefer the team's **knowledge base** if one is configured (a gbrain / wiki / notes MCP) — write a dated page (e.g. slug `…/readiness/<repo>-<YYYY-MM-DD>`).
- Otherwise (or additionally) write a versioned file in the repo: `docs/agent-readiness/<YYYY-MM-DD>.md`.

Save the full report from Step 3 — the per-area detail (what was evaluated + what was found, with evidence), the scorecard, the level + blocker, and the fix-first list. On re-runs, link back to the previous dated report so the trend is visible.

## Subagent report schema

Ask each pillar subagent to return exactly this (use the Task tool's structured-output / schema option if available):

```yaml
pillar: <name>
criteria:
  - id: <criterion snake_case, e.g. "pre_commit_hooks">
    verdict: pass | fail | skip
    evidence: <one line: file path + why; for skip, "N/A: <reason>">
  # ... one per criterion in this pillar's table
quality_note: <1-2 sentences: genuinely solid, or present-but-hollow? the real failure mode here?>
top_fixes:
  - <concrete, specific fix>
```

## Notes

- **Scale to the repo.** A tiny repo can group several pillars into fewer subagents; a monorepo may need each subagent to cover every app, or one subagent per app per pillar — decide and say so.
- **The script is a convenience, never the authority.** The score is your synthesis of the investigations.
- Stay honest: presence ≠ quality, and "Level N" is a claim you should be able to defend from the evidence.

## Credits

Framework © [Factory.ai](https://factory.ai/news/agent-readiness) (Agent Readiness). The 9-pillar / ~80-criterion catalog is reverse-engineered from Factory's **public** Agent Readiness reports (e.g. `factory.ai/agent-readiness/fastapi_fastapi`, `cockroachdb_cockroach`, `streamlit_streamlit`); the orchestration and the subagent investigation are original work. MIT.
