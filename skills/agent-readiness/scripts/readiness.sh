#!/usr/bin/env bash
# ============================================================================
# readiness.sh — Agent Readiness fast inventory (OPTIONAL helper)
#
# Convenience pre-scan for the `agent-readiness` skill. Imitates Factory.ai's
# Agent Readiness framework structure (8 pillars, 5 gated levels) with binary
# file/config checks. Multi-language, project-agnostic, zero dependencies.
#
# Usage:   bash readiness.sh <path-to-repo>      # defaults to "."
#
# IMPORTANT: this is a STARTING SIGNAL, not the score. It only detects
# *presence* (a linter config exists), never *quality* (it is wired in and
# runs). The real assessment is the per-pillar subagent investigation +
# cross-referencing described in SKILL.md. Use this output to give the
# subagents a head start, then let their judgment decide the verdict.
# ============================================================================
set -uo pipefail

TARGET="${1:-.}"; TARGET="${TARGET%/}"
if [[ ! -d "$TARGET" ]]; then echo "Not a directory: $TARGET" >&2; exit 1; fi

# --- detection helpers (run in current shell; chk calls them via eval) ------
PRUNE=( -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/vendor/*' )
ff() { find "$TARGET" -maxdepth 3 "${PRUNE[@]}" -type f -name "$1" 2>/dev/null | grep -q .; }
fd() { find "$TARGET" -maxdepth 3 "${PRUNE[@]}" -type d -name "$1" 2>/dev/null | grep -q .; }
root() { [[ -f "$TARGET/$1" ]]; }
dpath() { find "$TARGET" -maxdepth 4 "${PRUNE[@]}" -type d -name "$1" -path "$2" 2>/dev/null | grep -q .; }
pkgrep() {
  local pkgs; pkgs=$(find "$TARGET" -maxdepth 3 "${PRUNE[@]}" -type f -name package.json 2>/dev/null)
  [[ -n "$pkgs" ]] && echo "$pkgs" | tr '\n' '\0' | xargs -0 grep -lE "$1" >/dev/null 2>&1
}
wfgrep() { grep -rIlE "$1" "$TARGET/.github/workflows" 2>/dev/null | grep -q .; }
contentgrep() { grep -rIlE "$1" "$TARGET" --include='*.ts' --include='*.tsx' --include='*.js' --include='*.py' --include='*.go' \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=dist 2>/dev/null | grep -q .; }
tsstrict() { local t; t=$(find "$TARGET" -maxdepth 3 "${PRUNE[@]}" -type f -name 'tsconfig*.json' 2>/dev/null);
  [[ -n "$t" ]] && echo "$t" | tr '\n' '\0' | xargs -0 grep -lE '"strict": *true' >/dev/null 2>&1; }
readme_big() { local r; for r in README.md readme.md README.MD README.rst; do
    [[ -f "$TARGET/$r" ]] && [[ $(wc -c < "$TARGET/$r") -ge 500 ]] && return 0; done; return 1; }

# --- result registry (bash 3.2 friendly: parallel arrays) -------------------
R_PILLAR=(); R_LEVEL=(); R_PASS=(); R_LABEL=()
chk() { # chk <pillar> <level> <label> <expr-string>
  local p="$1" l="$2" lbl="$3" expr="$4" pass=0
  if eval "$expr" >/dev/null 2>&1; then pass=1; fi
  R_PILLAR+=("$p"); R_LEVEL+=("$l"); R_PASS+=("$pass"); R_LABEL+=("$lbl")
}

# ============================================================================
# CHECKS
# ============================================================================
# Style & Validation
chk Style    1 "editorconfig"                      'ff ".editorconfig"'
chk Style    2 "linter (eslint/biome/ruff/...)"    'ff ".eslintrc*" || ff "eslint.config.*" || ff "biome.json" || ff ".ruff.toml" || ff ".golangci.y*ml" || pkgrep "(eslint|@biomejs/biome)"'
chk Style    2 "formatter (prettier/biome/black)"  'ff ".prettierrc*" || ff "prettier.config.*" || ff "biome.json" || ff ".black" || pkgrep "\"prettier\""'
chk Style    3 "type checking (tsconfig/mypy)"     'pkgrep "\"typecheck\"" || tsstrict || ff "mypy.ini" || ff ".mypy.ini"'
chk Style    3 "pre-commit hooks"                  'fd ".husky" || ff "lefthook.y*ml" || ff ".pre-commit-config.yaml" || pkgrep "(lint-staged|husky|lefthook)"'

# Build System
chk Build    1 "lock file"                         'ff "package-lock.json" || ff "yarn.lock" || ff "pnpm-lock.yaml" || ff "bun.lockb" || ff "Cargo.lock" || ff "poetry.lock" || ff "go.sum"'
chk Build    2 "build script / Makefile"           'pkgrep "\"build\":" || ff "Makefile" || ff "build.gradle*"'
chk Build    2 "CI configured"                      '[[ -d "$TARGET/.github/workflows" ]] || ff ".gitlab-ci.yml" || ff ".circleci"'
chk Build    5 "version pinning (.nvmrc/engines)"  'ff ".nvmrc" || ff ".tool-versions" || ff ".python-version" || ff "rust-toolchain*" || pkgrep "\"engines\""'

# Testing
chk Testing  2 "test framework / script"           'pkgrep "\"test\":" || ff "vitest.config.*" || ff "jest.config.*" || ff "playwright.config.*" || ff "pytest.ini" || ff "*_test.go"'
chk Testing  2 "test files present"                'ff "*.test.*" || ff "*.spec.*" || ff "test_*.py" || ff "*_test.go" || fd "tests" || fd "__tests__"'
chk Testing  4 "E2E tests"                          'ff "playwright.config.*" || ff "cypress.config.*" || fd "e2e"'
chk Testing  4 "coverage config"                    'pkgrep "coverage" || ff ".coveragerc" || ff ".nycrc*"'
chk Testing  4 "CI runs tests"                      'wfgrep "(npm (run )?test|vitest|pytest|jest|go test|cargo test)"'

# Documentation
chk Docs     1 "README >= 500 chars"               'readme_big'
chk Docs     2 "CONTRIBUTING or docs/"             'root "CONTRIBUTING.md" || fd "docs"'
chk Docs     3 "AI context (AGENTS/CLAUDE/cursor)" 'root "AGENTS.md" || root "CLAUDE.md" || ff ".cursorrules" || ff "copilot-instructions.md"'
chk Docs     4 "docs/dev backbone"                 'dpath "dev" "*docs*" || dpath "development" "*docs*"'
chk Docs     5 "AGENTS.md + CLAUDE.md (both)"      'root "AGENTS.md" && root "CLAUDE.md"'
chk Docs     5 "architecture docs / ADRs"          'fd "architecture" || fd "arquitectura" || ff "ADR-*.md" || ff "*adr*.md"'

# Dev Environment
chk DevEnv   1 "setup / bootstrap script"          'pkgrep "\"setup\":" || ff "setup*.sh" || ff "bootstrap*.sh" || ff "Makefile"'
chk DevEnv   3 ".env.example / template"           'ff ".env.example" || ff ".env.template" || ff ".env*.example"'
chk DevEnv   4 "Docker/devcontainer or named URLs" 'ff "Dockerfile" || ff "docker-compose*.y*ml" || fd ".devcontainer" || ff "portless.json"'
chk DevEnv   5 "env vars documented"               'ff "*ENVIRON*.md" || ff "*ENV*.md" || ff "*AMBIENTES*.md"'

# Observability
chk Observ   4 "healthcheck / smoke test"          'contentgrep "api/health|/healthz" || wfgrep "smoke"'
chk Observ   4 "error monitoring (sentry/datadog)" 'pkgrep "(sentry|datadog)" || ff "sentry.*.config.*"'
chk Observ   5 "structured logging"                'pkgrep "(pino|winston|structlog|loglevel|zerolog)"'

# Security & Governance
chk Security 1 "LICENSE"                            'ff "LICENSE*"'
chk Security 3 "secret scanning / guard"           'ff ".gitleaks*" || ff ".secrets.baseline" || wfgrep "(gitleaks|detect-secrets|trufflehog)" || ff "check-secrets*" || ff "check-env*" || ff "check-staged-secrets*"'
chk Security 3 "SECURITY.md"                        'ff "SECURITY.md"'
chk Security 4 "security scanning (CodeQL/Snyk)"   'wfgrep "(codeql|snyk|semgrep|trivy|cargo-audit)"'
chk Security 4 "dependency update automation"      'ff "dependabot.y*ml" || ff "renovate.json*" || ff ".renovaterc*"'

# Task Discovery
chk TaskDisc 4 "issue / PR templates"              'fd "ISSUE_TEMPLATE" || ff "PULL_REQUEST_TEMPLATE*" || ff "pull_request_template*"'
chk TaskDisc 5 "CODEOWNERS"                         'ff "CODEOWNERS"'
chk TaskDisc 5 "agent memory / context dir"        'fd ".engram" || dpath "skills" "*.claude*" || fd ".cursor" || ff "copilot-instructions.md"'

# ============================================================================
# SCORECARD
# ============================================================================
N=${#R_PASS[@]}
PILLARS=("Style" "Build" "Testing" "Docs" "DevEnv" "Observ" "Security" "TaskDisc")
PNAME_Style="Style & Validation"; PNAME_Build="Build System"; PNAME_Testing="Testing"
PNAME_Docs="Documentation"; PNAME_DevEnv="Dev Environment"; PNAME_Observ="Observability"
PNAME_Security="Security & Governance"; PNAME_TaskDisc="Task Discovery"

echo ""
echo "================================================================"
echo "  AGENT READINESS  -  $(basename "$TARGET")"
echo "================================================================"
echo ""
echo "  By pillar:"
TOTPASS=0
for p in "${PILLARS[@]}"; do
  pp=0; pt=0
  for ((i=0;i<N;i++)); do
    if [[ "${R_PILLAR[$i]}" == "$p" ]]; then pt=$((pt+1)); [[ "${R_PASS[$i]}" == "1" ]] && pp=$((pp+1)); fi
  done
  TOTPASS=$((TOTPASS+pp))
  pct=$(( pt>0 ? pp*100/pt : 0 ))
  bar=""; full=$(( pct/10 )); for ((b=0;b<10;b++)); do [[ $b -lt $full ]] && bar="${bar}#" || bar="${bar}."; done
  pn="PNAME_$p"; printf "    %-24s [%s] %3d%%  (%d/%d)\n" "${!pn}" "$bar" "$pct" "$pp" "$pt"
done
echo ""
echo "  By level (80% gate):"
ACHIEVED=0; BROKEN=0
for L in 1 2 3 4 5; do
  lp=0; lt=0
  for ((i=0;i<N;i++)); do
    if [[ "${R_LEVEL[$i]}" == "$L" ]]; then lt=$((lt+1)); [[ "${R_PASS[$i]}" == "1" ]] && lp=$((lp+1)); fi
  done
  lpct=$(( lt>0 ? lp*100/lt : 100 ))
  case $L in 1) ln="Functional";; 2) ln="Documented";; 3) ln="Standardized";; 4) ln="Optimized";; 5) ln="Autonomous";; esac
  mark="x "; [[ $lpct -ge 80 ]] && mark="OK"
  printf "    L%d %-13s %-2s %3d%%  (%d/%d)\n" "$L" "$ln" "$mark" "$lpct" "$lp" "$lt"
  if [[ $BROKEN -eq 0 && $lpct -ge 80 ]]; then ACHIEVED=$L; else BROKEN=1; fi
done
echo ""
case $ACHIEVED in 0) AN="none";; 1) AN="Functional";; 2) AN="Documented";; 3) AN="Standardized";; 4) AN="Optimized";; 5) AN="Autonomous";; esac
echo "  >> LEVEL REACHED: $ACHIEVED ($AN)   -   Production target: 3 (Standardized)"
echo ""
NEXT=$((ACHIEVED+1)); [[ $NEXT -gt 5 ]] && NEXT=5
echo "  To reach Level $NEXT - fix first:"
any=0
for ((i=0;i<N;i++)); do
  if [[ "${R_LEVEL[$i]}" == "$NEXT" && "${R_PASS[$i]}" == "0" ]]; then
    echo "    x  [${R_PILLAR[$i]}] ${R_LABEL[$i]}"; any=1
  fi
done
[[ $any -eq 0 ]] && echo "    (all Level $NEXT checks pass)"
echo ""
echo "  Total: $TOTPASS/$N checks   (presence only - pair with qualitative review)"
echo "================================================================"
