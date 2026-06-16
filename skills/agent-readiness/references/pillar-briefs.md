# Pillar investigation briefs

One brief per Factory pillar. The orchestrator hands the matching brief to each pillar subagent. Each brief lists: the **failure mode** it prevents, the **criteria** to investigate (tagged by maturity level `L1`–`L5`), and the **quality lens** (how to tell a real signal from a hollow one). The subagent investigates the repo, judges each criterion `pass / partial / fail` **with file-path evidence**, and returns the schema in `SKILL.md`.

> **Golden rule for every pillar:** presence ≠ quality. A config that exists but isn't wired in, a doc that's stale, a test that asserts nothing — these are `partial` or `fail`, not `pass`. Read the files; don't `ls` them.

The **criteria→level map** is the union of all `L#` tags below. Level reached = ≥80% of that level's criteria pass **and** every lower level too.

---

## 1. Style & Validation
**Failure mode:** "Agent submits code with formatting issues, waits for CI, fixes blindly, repeats."

Criteria:
- **L1 — editorconfig:** `.editorconfig` present and non-trivial.
- **L2 — linter:** a linter is configured (ESLint, Biome, Ruff, golangci-lint, …). *Quality:* is it actually run (a `lint` script, a CI job, a pre-commit step), or an orphan config? Sample the config — is it the framework default or a real ruleset?
- **L2 — formatter:** a formatter (Prettier, Biome, Black, gofmt…). *Quality:* enforced (CI `--check` / pre-commit), not just installed.
- **L3 — type checking:** static types enforced (tsconfig `strict`, mypy, etc.) and run (`typecheck` script / CI). *Quality:* `strict` actually on? `any` everywhere defeats it.
- **L3 — pre-commit hooks:** Husky / Lefthook / pre-commit / lint-staged, **wired** to run lint+format+typecheck before commit. This is the fastest agent feedback loop — judge whether it really fires.

Quality lens: an agent should get a green/red signal in seconds, locally, before CI. Configs that exist but aren't invoked are `partial` at best.

---

## 2. Build System
**Failure mode:** tribal knowledge to build → the agent can't verify its own work.

Criteria:
- **L1 — lock file:** `package-lock.json` / `yarn.lock` / `pnpm-lock.yaml` / `Cargo.lock` / `poetry.lock` / `go.sum`. Reproducible installs.
- **L2 — build script:** a documented, single-command build (`build` script, `Makefile`, Gradle/Maven). *Quality:* does it actually build from a clean checkout, or need undocumented steps?
- **L2 — CI configured:** `.github/workflows`, GitLab CI, CircleCI… present and **non-empty**.
- **L5 — version pinning:** runtime pinned (`.nvmrc`, `.tool-versions`, `engines`, `rust-toolchain`). An agent on the wrong Node/Python version fails mysteriously.

Quality lens: can a cold agent install + build with one documented command and no human in the loop?

---

## 3. Testing
**Failure mode:** no fast, trustworthy signal that a change is correct → the agent ships regressions.

Criteria:
- **L2 — test framework/script:** a runner is configured and invocable (`test` script, vitest/jest/pytest/go test).
- **L2 — test files present:** real test files exist. *Quality:* **do they assert behavior, or are they smoke/snapshot/`expect(true)` filler?** Sample several.
- **L4 — E2E tests:** Playwright/Cypress or equivalent, covering real user flows.
- **L4 — coverage:** coverage configured *and* meaningful (not 100% of trivial getters). Note the real number if visible.
- **L4 — CI runs tests:** the test suite runs on PR and **gates merge** (not an allowed-to-fail job).

Quality lens: would these tests actually catch a regression an agent introduces? Coverage of the critical business logic matters more than a high headline %.

---

## 4. Documentation
**Failure mode:** the agent can't learn the system → wrong assumptions, wasted loops.

Criteria:
- **L1 — README (substantive):** exists, ≥ a few hundred chars, and actually explains what/why/how to run.
- **L2 — CONTRIBUTING or docs/:** contribution/dev guidance exists.
- **L3 — AI context file:** `AGENTS.md` and/or `CLAUDE.md` (or `.cursorrules`/copilot-instructions) at the repo root. *Quality:* **is it accurate against the current code, or stale?** Does it actually let a cold agent be productive — conventions, gotchas, where logic lives?
- **L4 — docs/dev backbone:** a `docs/dev` (or `docs/development`) with setup / environments / testing / gotchas.
- **L5 — AGENTS.md + CLAUDE.md (both):** multi-agent coverage at root.
- **L5 — architecture docs / ADRs:** design rationale recorded (`docs/architecture`, ADR files).

Quality lens: open the AI-context file and the README and ask "could I onboard from this alone?" Stale or aspirational docs are worse than none — mark them `partial`/`fail` and say why.

---

## 5. Dev Environment
**Failure mode:** "Undocumented environment variables mean the agent guesses, fails, and guesses again."

Criteria:
- **L1 — setup/bootstrap script:** one command (or short documented sequence) to get running (`setup` script, `Makefile`, bootstrap).
- **L3 — `.env.example` / template:** present **and complete**. *Quality:* cross-check the example against env vars actually read in the code (`process.env.*`, `import.meta.env.*`, `os.environ`). Missing vars = the core failure mode → `partial`/`fail`.
- **L4 — containerization or named dev URLs:** Dockerfile / docker-compose / devcontainer / portless — reproducible environment.
- **L5 — env vars documented:** a doc explaining each variable (not just a bare `.env.example`).

Quality lens: could an agent reproduce the dev environment and know every variable it needs, without asking a human? This is the highest-signal pillar for autonomy — investigate it hardest.

---

## 6. Observability
**Failure mode:** no feedback on what broke → the agent debugs blind; and "missing pre-commit hooks mean the agent waits ten minutes for CI instead of five seconds."

Criteria:
- **L4 — healthcheck / smoke test:** a health endpoint and/or post-deploy smoke test exists.
- **L4 — error monitoring:** Sentry / Datadog / equivalent **or** an equivalent alerting path (CI failure → Slack/Discord, log drains). *Don't only grep for Sentry* — credit real alerting in any form.
- **L5 — structured logging:** a logger (pino/winston/structlog/zerolog) with structured, useful output — not bare `console.log`.

Quality lens: when something breaks at runtime or in CI, does a signal reach a human/agent automatically and legibly? Be generous about *form* (a Discord alert counts) but strict about *existence*.

---

## 7. Security & Governance
**Failure mode:** the agent leaks secrets or pulls vulnerable deps; no guardrails on what it can change.

Criteria:
- **L1 — LICENSE:** a `LICENSE` file.
- **L3 — secret scanning / guard:** gitleaks / detect-secrets / trufflehog, **or** a repo guard script (`check-secrets`, `check-env-safety`) wired into pre-commit/CI. *Quality:* does it actually run?
- **L3 — SECURITY.md:** a disclosure/security policy.
- **L4 — security scanning:** SAST/deps in CI (CodeQL, Snyk, Semgrep, Trivy, `npm/cargo audit`).
- **L4 — dependency update automation:** Dependabot / Renovate configured.

Quality lens: an autonomous agent commits and opens PRs — what stops it from committing a secret or a known-vulnerable dep? Look for *enforced* guards, not just policy docs. (If you spot a secret committed in the repo, flag it loudly as a finding regardless of score.)

---

## 8. Task Discovery
**Failure mode:** the agent can't find what to do, who owns what, or the context it needs.

Criteria:
- **L4 — issue / PR templates:** `.github/ISSUE_TEMPLATE`, `PULL_REQUEST_TEMPLATE` — structured intake an agent can fill.
- **L5 — CODEOWNERS:** ownership mapped.
- **L5 — agent memory / context dir:** a persistent agent-context/memory mechanism (`.engram`, `.claude/skills`, `.cursor`, copilot-instructions) — the repo invests in agent context beyond a single file.

Quality lens: could an agent pick up well-scoped work and know who to route it to, with the context to do it right?

---

## Criteria → level summary (for the 80% gate)

- **L1 (Functional):** editorconfig · lock file · README · setup script · LICENSE
- **L2 (Documented):** linter · formatter · build script · CI configured · test framework · test files · CONTRIBUTING/docs
- **L3 (Standardized — production bar):** type checking · pre-commit hooks · AI context file · `.env.example` · secret scanning · SECURITY.md
- **L4 (Optimized):** E2E · coverage · CI runs tests · docs/dev backbone · containerization · healthcheck/smoke · error monitoring · security scanning · dep automation · issue/PR templates
- **L5 (Autonomous):** version pinning · AGENTS.md+CLAUDE.md (both) · architecture/ADRs · env vars documented · structured logging · CODEOWNERS · agent memory dir

Adapt sensibly per stack (a Go repo's "formatter" is `gofmt`; a Python repo's "type checking" is mypy). When a criterion doesn't apply, say so and exclude it from that pillar's denominator rather than failing it.
