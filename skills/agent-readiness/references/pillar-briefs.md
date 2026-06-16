# Pillar criterion catalog

The criterion set the `agent-readiness` skill investigates, reverse-engineered from Factory.ai's public Agent Readiness reports (e.g. `factory.ai/agent-readiness/fastapi_fastapi`, `cockroachdb_cockroach`, `streamlit_streamlit`). **9 pillars, ~80 criteria** with fixed `snake_case` names. The orchestrator hands each pillar subagent its slice; the subagent investigates the repo and returns a verdict per criterion.

## Verdicts: pass / fail / skip

Every criterion gets one of three verdicts — **this is the most important mechanic**:

- **`pass`** (✓) — the signal is present *and real* (configured and wired in, not just a dangling file).
- **`fail`** (✗) — applicable to this repo but absent or hollow.
- **`skip`** (—) — **not applicable to this repo type**, so it is **excluded from the denominator** (doesn't count against the score). A library has no database → skip `database_schema`, `n_plus_one_detection`, `local_services_setup`. A non-web service → skip `dast_scanning`, `health_checks`. Skipping is not a penalty; it's what makes the score fair across project types. Be honest: skip only when genuinely N/A, and say *why*.
- **Prerequisites:** some criteria depend on another passing first. If the prerequisite fails, the dependent is `skip` ("prerequisite failed"). E.g. `agents_md_validation` requires `agents_md`; `devcontainer_runnable` requires `devcontainer`.

**Score = passing / applicable** (applicable = pass + fail; skips excluded). Report per-pillar (e.g. "Testing 5/7 = 71%") and overall (e.g. "31/59 = 53%"). Each verdict carries a **one-line evidence string** ("Mypy strict mode enabled in pyproject.toml", "30 releases in ~45 days").

**Level** (1–5) is gated: criteria are level-tagged below; you reach a level when its applicable criteria mostly pass (~75%+) **and** every lower level does. Observed bands: Level 3 ≈ 53–59% overall, Level 4 ≈ 65–74%. The level and the per-pillar table can diverge — report both.

---

## 1. Style & Validation

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `lint_config` | L1 | Linter configured with a real ruleset (ESLint/Biome/Ruff/golangci-lint, `select` rules) | — |
| `formatter` | L1 | Formatter configured (Prettier/Biome/Ruff format/Black/gofmt) | — |
| `type_check` | L2 | Type checker present & runnable (tsc, mypy, built-in) | dynamically-typed with no type tooling intent |
| `strict_typing` | L3 | Strict mode on (`tsconfig strict:true`, `mypy strict=true`) | `type_check` fails |
| `naming_consistency` | L2 | Naming rules enforced (lint naming rules) | — |
| `pre_commit_hooks` | L3 | Pre-commit framework wired (Husky/Lefthook/pre-commit) running lint/format/type | — |
| `large_file_detection` | L2 | Guard against huge files (`check-added-large-files`, maxkb threshold) | — |
| `cyclomatic_complexity` | L4 | Complexity analysis tool (radon, gocyclo, eslint complexity) | — |
| `dead_code_detection` | L4 | Dead-code tool (vulture, knip, ts-prune, staticcheck) | — |
| `duplicate_code_detection` | L4 | Duplication tool (jscpd, pmd-cpd) | — |
| `code_modularization` | L4 | Files/modules cohesive & reasonably sized | very small projects |
| `tech_debt_tracking` | L3 | TODO/FIXME scanner or debt-tracking tool | — |
| `n_plus_one_detection` | L5 | N+1 query detection tooling | no database usage |

## 2. Build System

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `build_cmd_doc` | L1 | Build command documented (README / build system file) | — |
| `deps_pinned` | L1 | Dependencies pinned (lockfile: package-lock/uv.lock/go.sum/Cargo.lock) | — |
| `vcs_cli_tools` | L1 | VCS CLI available/authenticated (gh) | — |
| `single_command_setup` | L2 | One documented command to set up the repo | — |
| `fast_ci_feedback` | L2 | CI completes in reasonable time | no CI |
| `deployment_frequency` | L4 | Frequent releases/deploys (cadence in git/releases) | — |
| `release_automation` | L4 | Automated release pipeline (publish workflow) | — |
| `release_notes_automation` | L4 | Automated changelog/release notes | — |
| `build_performance_tracking` | L4 | Build caching / build metrics | no build step |
| `unused_dependencies_detection` | L4 | Unused-dependency detection (depcheck, knip) | — |
| `agentic_development` | L5 | Git history shows agent/droid co-authorship (Cursor/Droid/Copilot commits or AI-PR-review workflow) | — |
| `automated_pr_review` | L5 | Automated PR review (bot/workflow generates reviews) | — |
| `feature_flag_infrastructure` | L5 | Feature-flag system present | — |
| `dead_feature_flag_detection` | L5 | Detect stale feature flags | `feature_flag_infrastructure` fails |
| `progressive_rollout` | L5 | Canary / progressive deploy | not a deployed service |
| `rollback_automation` | L5 | Automated rollback mechanism | not a deployed service |
| `monorepo_tooling` | L5 | Monorepo tooling (Nx/Turbo/Bazel) | single-app repo |
| `version_drift_detection` | L5 | Version drift across packages | single-app repo |
| `heavy_dependency_detection` | L5 | Bundle/heavy-dep analysis | not a bundled app |

## 3. Testing

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `unit_tests_exist` | L1 | Unit tests present (real `*test*` files). **Open ≥3 — do they assert behavior or are they filler?** | — |
| `unit_tests_runnable` | L1 | Tests collectable/runnable (runner configured) | — |
| `test_naming_conventions` | L2 | Test naming configured/consistent | — |
| `test_isolation` | L2 | Tests isolated / parallelizable | — |
| `integration_tests_exist` | L3 | Integration/e2e tests exist | — |
| `test_coverage_thresholds` | L3 | Coverage threshold enforced (a real % gate) | — |
| `flaky_test_detection` | L4 | Flaky-test detection/retry mechanism | — |
| `test_performance_tracking` | L4 | Test timing/analytics tracked | — |

## 4. Documentation

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `readme` | L1 | README comprehensive (what/why/how) | — |
| `documentation_freshness` | L2 | Key docs modified recently (~last 180 days) | — |
| `agents_md` | L3 | `AGENTS.md` at repo root | — |
| `agents_md_validation` | L4 | AGENTS.md/CLAUDE.md accurate vs the code (**verify a few referenced paths/claims resolve**) | `agents_md` fails |
| `skills` | L4 | Agent skills directory (`.claude/skills/`, `skills/`) | — |
| `api_schema_docs` | L3 | API schema docs (OpenAPI/Swagger) | no API surface |
| `automated_doc_generation` | L3 | Doc generation (Sphinx/JSDoc/docs workflow) | — |
| `service_flow_documented` | L4 | Architecture diagrams / service-flow docs | — |

## 5. Dev Environment

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `env_template` | L3 | `.env.example`/template, **complete vs the vars the code actually reads (diff against `process.env.*`/`os.environ`)** | no env vars used |
| `devcontainer` | L4 | `.devcontainer/devcontainer.json` present | — |
| `devcontainer_runnable` | L4 | Devcontainer actually builds | `devcontainer` fails |
| `database_schema` | L4 | DB schema documented / migrations present | no database |
| `local_services_setup` | L4 | Local services bring-up (docker-compose, named URLs) | no external services |

## 6. Debugging & Observability

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `structured_logging` | L3 | Structured logger (pino/winston/structlog/zerolog), not bare prints | — |
| `code_quality_metrics` | L4 | Quality/coverage metrics tracked | — |
| `health_checks` | L4 | Health endpoints | not a deployed service |
| `alerting_configured` | L4 | Alerting path **in any form** (PagerDuty, or CI/runtime → Slack/Discord) | — |
| `error_tracking_contextualized` | L4 | Error tracking (Sentry/etc.) with context | — |
| `metrics_collection` | L4 | Metrics instrumentation (Prometheus/OTel) | not a service |
| `deployment_observability` | L4 | Deploy monitoring dashboards/links | not deployed |
| `runbooks_documented` | L4 | Runbooks for incidents | — |
| `distributed_tracing` | L5 | Trace/request-ID propagation | single-process library |
| `circuit_breakers` | L5 | Circuit breakers for deps | library / no service deps |
| `profiling_instrumentation` | L5 | Profiling instrumentation | profiling not meaningful |

## 7. Security

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `secrets_management` | L1 | No hardcoded secrets; uses a secret store / CI secrets (**grep for committed secrets — flag loudly if found**) | — |
| `gitignore_comprehensive` | L1 | `.gitignore` covers `.env`, venv, build artifacts, IDE | — |
| `codeowners` | L3 | `CODEOWNERS` file maps ownership | — |
| `dependency_update_automation` | L3 | Dependabot/Renovate configured | — |
| `secret_scanning` | L4 | Secret scanning (gitleaks/GH secret scanning, or a wired secret-guard hook) | needs admin API / N/A |
| `automated_security_review` | L4 | SAST/code scanning (CodeQL/Snyk/Semgrep) | needs API access |
| `branch_protection` | L4 | Branch protection rules | needs GH admin API |
| `log_scrubbing` | L4 | Log sanitization / PII scrubbing | — |
| `dast_scanning` | L5 | DAST scanning | not a web service |
| `pii_handling` | L5 | PII handling controls | doesn't process PII |
| `privacy_compliance` | L5 | Privacy compliance (GDPR/consent) | no user-data collection |

## 8. Task Discovery

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `issue_templates` | L2 | `.github/ISSUE_TEMPLATE/` present | — |
| `issue_labeling_system` | L2 | Consistent label taxonomy (bug/feature/docs…) | — |
| `backlog_health` | L2 | Open issues have descriptive titles (>10 chars) + labels | — |
| `pr_templates` | L3 | `.github/pull_request_template.md` present | — |

## 9. Product & Analytics

| Criterion | Lvl | What it checks / how to detect | Skip when |
|---|---|---|---|
| `product_analytics_instrumentation` | L5 | Product analytics (PostHog/Amplitude/etc.) | not a user-facing product |
| `error_to_insight_pipeline` | L5 | Error→issue automation (Sentry↔GitHub) | — |

---

## Golden rules for the subagent

1. **Investigate, don't `ls`.** Read the configs/CI/hooks/tests. A config that exists but isn't wired in is `fail`, not `pass`.
2. **Do the concrete cross-check** where one is flagged above (the **bold** ones) — that's where the highest-value findings come from: diff `env_template` against env reads; open ≥3 test files; verify `agents_md` claims resolve; grep for committed secrets.
3. **Skip honestly.** Mark `skip` only for genuine N/A (and say why); don't skip to inflate the score, don't fail a criterion that doesn't apply to this repo type.
4. **One-line evidence per criterion**, with a file path where possible — Factory-style ("Dependabot configured for github-actions and uv").
5. **Credit real signals in any form.** `alerting_configured` passes on a CI-failure→Discord webhook just as on PagerDuty; `agentic_development` passes on an AI-PR-review workflow or agent co-authored commits.
