# Agent Readiness — framework reference

Background for the `agent-readiness` skill. Source: Factory.ai's [Agent Readiness](https://factory.ai/news/agent-readiness) framework, plus the open-source `@kodus/agent-readiness` and `jpequegn/agent-readiness-score` implementations.

## Core idea

> "AI coding agents are only as effective as the environment in which they operate."

Agent Readiness measures how well a **repository** supports autonomous development — not how good the agent is. The same agent that flails in one repo ships in another; the difference is the environment. Most criteria are **binary** (pass/fail) and are file-existence checks or config parsing, with a layer of qualitative ("AI") checks for things presence can't capture.

The dynamic is compounding: *better environments make agents more productive → more productive agents handle more work → that frees time to improve environments further.*

## The 8 pillars (with the failure mode each prevents)

| Pillar | Evaluates | Failure mode when missing |
|---|---|---|
| **Style & Validation** | Linters, formatters, type checkers, pre-commit hooks | "Agent submits code with formatting issues, waits for CI, fixes blindly, repeats." |
| **Build System** | Reproducible build, dependency/lock management | Tribal knowledge to build → the agent can't verify its own work. |
| **Testing** | Test presence, breadth, E2E, coverage, runs in CI | No fast signal that a change is correct → the agent ships regressions. |
| **Documentation** | README, AI-context files (AGENTS.md/CLAUDE.md), ADRs, API docs | The agent can't learn the system → wrong assumptions, wasted loops. |
| **Dev Environment** | Reproducible setup, `.env.example`, version pinning, containers | "Undocumented environment variables mean the agent guesses, fails, and guesses again." |
| **Observability** | Logging, error messages, monitoring, healthchecks | No feedback on what broke → the agent debugs blind. (Also: "missing pre-commit hooks mean the agent waits ten minutes for CI feedback instead of five seconds.") |
| **Security & Governance** | Secret scanning, dependency auditing, security scanning, LICENSE/SECURITY | The agent leaks secrets or pulls vulnerable deps; no governance guardrails. |
| **Task Discovery** | Issue/PR templates, CODEOWNERS, contribution guides, agent memory | The agent can't find what to do or who owns what. |

(Factory's product page lists "Task Discovery"; some materials list "Code Quality / Code Health" instead — both are reasonable 8th axes. The bundled scanner uses the pillar set above.)

## The 5 maturity levels (80%-gated)

To reach a level you must pass **≥80%** of its criteria **and** all lower levels'.

| Level | Name | What it means | Representative criteria |
|---|---|---|---|
| 1 | **Functional** | Basic; agents struggle | README, LICENSE, lock file, `.editorconfig`, a setup script |
| 2 | **Documented** | Some docs; agents can navigate | Linters, formatters, test framework, basic CI |
| 3 | **Standardized** | **Production bar.** Consistent, enforced processes; agents productive | Type checking, pre-commit hooks, `.env.example`, AI-context file, secret scanning, SECURITY.md |
| 4 | **Optimized** | Fast feedback; agents highly effective | E2E tests, coverage, CI runs tests, deploy pipeline, security scanning, dependency automation, issue/PR templates |
| 5 | **Autonomous** | Agents work independently | AGENTS.md **and** CLAUDE.md, architecture docs/ADRs, structured logging, version pinning, CODEOWNERS, agent memory |

**Organization metric:** percentage of active repositories at Level 3 or higher.

## Reporting principle

Every finding ships with a **specific fix** ("add `AGENTS.md`", "add a pre-commit hook", "document `STRIPE_KEY` in `.env.example`") — never a vague "improve X". Prioritise gating + cheap wins: two missing files at Level 1 can unlock several levels at once.
