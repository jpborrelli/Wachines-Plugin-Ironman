# Agent Readiness — framework reference

Background for the `agent-readiness` skill. Source: Factory.ai's [Agent Readiness](https://factory.ai/news/agent-readiness) framework and its **public reports** for open-source repos (`factory.ai/agent-readiness/<owner>_<repo>` — fastapi, cockroachdb, streamlit, temporal, superset, …), from which the criterion catalog in `pillar-briefs.md` is reverse-engineered.

## Core idea

> "AI coding agents are only as effective as the environment in which they operate."

Agent Readiness measures how well a **repository** supports autonomous development — not how good the agent is. The same agent that flails in one repo ships in another; the difference is the environment. Factory evaluates **100+ signals** across 9 pillars; each criterion is `pass` / `fail` / **`skip`** (not applicable to this repo type → excluded from the denominator). The headline is a **pass rate** (passing / applicable) plus a gated **maturity level**.

The dynamic is compounding: *better environments make agents more productive → more productive agents handle more work → that frees time to improve environments further.*

## The 9 pillars (with the failure mode each prevents)

| Pillar | Evaluates | Failure mode when missing |
|---|---|---|
| **Style & Validation** | Linters, formatters, type checkers, pre-commit, complexity/dead-code/duplication, tech-debt tracking | "Agent submits code with formatting issues, waits for CI, fixes blindly, repeats." |
| **Build System** | Build/lock/setup, CI speed, release+rollback automation, feature flags, agentic-development signals | Tribal knowledge to build → the agent can't verify its own work. |
| **Testing** | Unit/integration tests, coverage thresholds, isolation, flaky/perf tracking | No fast signal that a change is correct → the agent ships regressions. |
| **Documentation** | README, AGENTS.md (+validation), skills, API schema, doc generation, freshness, arch flow | The agent can't learn the system → wrong assumptions, wasted loops. |
| **Dev Environment** | `.env.example` completeness, devcontainer, DB schema, local services | "Undocumented environment variables mean the agent guesses, fails, and guesses again." |
| **Debugging & Observability** | Structured logging, metrics, tracing, health checks, alerting, error tracking, runbooks | No feedback on what broke → the agent debugs blind. |
| **Security** | Secrets management, gitignore, secret/SAST scanning, dep automation, branch protection, PII/log-scrubbing | The agent leaks secrets or pulls vulnerable deps; no guardrails. |
| **Task Discovery** | Issue/PR templates, backlog health, label taxonomy | The agent can't find what to do or who owns what. |
| **Product & Analytics** | Product analytics instrumentation, error→insight pipeline | No loop from production signals back into the work queue. |

(Factory's earlier materials listed 8 pillars and sometimes "Code Quality"; the public reports use these 9, folding code-quality checks into Style & Validation. The catalog in `pillar-briefs.md` follows the public reports.)

## The 5 maturity levels (gated)

Criteria are level-tagged. You reach a level when its applicable criteria mostly pass (~75%+) **and** every lower level does too. The level is separate from the overall **pass rate** (passing/applicable) — a repo can post a modest pass rate yet hold a solid level if the *unmet* criteria are advanced (L4–L5), not foundational.

| Level | Name | What it means | Representative criteria |
|---|---|---|---|
| 1 | **Functional** | Basic; agents struggle | `readme`, `lint_config`, `formatter`, `deps_pinned`, `unit_tests_exist`, `secrets_management` |
| 2 | **Documented** | Some docs; agents can navigate | `type_check`, `single_command_setup`, `documentation_freshness`, `issue_templates`, `test_isolation` |
| 3 | **Standardized** | **Production bar.** Consistent, enforced processes | `pre_commit_hooks`, `strict_typing`, `integration_tests_exist`, `test_coverage_thresholds`, `env_template`, `agents_md`, `codeowners`, `dependency_update_automation`, `structured_logging` |
| 4 | **Optimized** | Fast feedback; agents highly effective | coverage/observability/security scanning, `release_automation`, `skills`, `devcontainer`, `branch_protection`, `agents_md_validation` |
| 5 | **Autonomous** | Agents work independently | `agentic_development`, `automated_pr_review`, `distributed_tracing`, `feature_flag_infrastructure`, `progressive_rollout`, `product_analytics_instrumentation` |

**Observed pass-rate bands (public reports):** Level 3 ≈ 53–59%, Level 4 ≈ 65–74%. **Organization metric:** percentage of active repositories at Level 3 or higher.

## Reporting principle

Every finding ships with a **specific fix** ("add `AGENTS.md`", "add a pre-commit hook", "document `STRIPE_KEY` in `.env.example`") — never a vague "improve X". Prioritise gating + cheap wins: two missing files at Level 1 can unlock several levels at once.
