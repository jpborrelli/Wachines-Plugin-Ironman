#!/usr/bin/env bash
# setup-dev.sh — instala el toolchain de skills del equipo wachines (una vez por máquina).
# Idempotente: se puede correr de nuevo para reparar/actualizar.
set -euo pipefail

say()  { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

GSTACK_DIR="$HOME/.claude/skills/gstack"
AGENTS="${WACHINES_AGENTS:-claude-code codex}"
DEV_REPOS="${WACHINES_DEV_REPOS:-$HOME/Documents/BackOffice $HOME/Documents/reporteGrass $HOME/Documents/gestionganadera}"
WACHINES_CORE_SKILLS="${WACHINES_CORE_SKILLS:-db-reviewer docs-architect frontend-design next-best-practices security-reviewer tanstack-query-hooks}"
DEFAULT_ENGRAM_CLOUD_SERVER="https://wachines-engram-cloud.fly.dev"

agent_label() {
  case "$1" in
    claude-code) printf "Claude Code" ;;
    codex) printf "Codex" ;;
    *) printf "%s" "$1" ;;
  esac
}

project_name_for_repo() {
  case "$(basename "$1")" in
    BackOffice) printf "backoffice" ;;
    reporteGrass) printf "reportegrass" ;;
    gestionganadera) printf "gestionganadera" ;;
    *) basename "$1" | tr '[:upper:]' '[:lower:]' ;;
  esac
}

# --- 0. Prerrequisitos ---------------------------------------------------------
have git || { warn "Falta git. Instalalo y reintentá."; exit 1; }
have npx || warn "Falta npx/Node — los 'npx skills add' van a fallar. Instalá Node.js."

# --- 1. gstack (necesita Bun) --------------------------------------------------
if ! have bun; then
  warn "Bun no está instalado (gstack lo necesita). Instalalo con: curl -fsSL https://bun.sh/install | bash"
  warn "Salteo gstack por ahora; corré este script de nuevo después de instalar Bun."
else
  if [ -d "$GSTACK_DIR/.git" ]; then
    say "gstack ya está — actualizando"
    if [ -n "$(git -C "$GSTACK_DIR" status --porcelain)" ]; then
      warn "No actualizo gstack porque tiene cambios locales en $GSTACK_DIR"
    elif [ "$(git -C "$GSTACK_DIR" rev-parse --abbrev-ref HEAD)" = "HEAD" ]; then
      git -C "$GSTACK_DIR" fetch origin main
      git -C "$GSTACK_DIR" checkout -B main origin/main || warn "No pude mover gstack a origin/main"
    else
      git -C "$GSTACK_DIR" pull --ff-only || warn "No pude actualizar gstack (¿cambios locales?)"
    fi
  else
    say "Instalando gstack en $GSTACK_DIR"
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR"
    ( cd "$GSTACK_DIR" && ./setup )
  fi
fi

# --- 2. skills vía npx ---------------------------------------------------------
if have npx; then
  # -g = global (user-level): cae en el directorio user-level del agente y aplica a TODOS los
  # proyectos. Sin -g, el CLI auto-detecta "project si estás dentro de un repo".
  for agent in $AGENTS; do
    say "Instalando wachines-skills core (dev) para $(agent_label "$agent") — global"
    # Instalamos solo el set core para no pisar skills con nombres compartidos
    # (html-perennia, supabase/vercel/web-design) que pueden venir de perennia-skills u otros upstreams.
    npx -y skills add perennia-regen/wachines-skills -g -a "$agent" --skill $WACHINES_CORE_SKILLS || warn "falló wachines-skills para $agent"

    say "Instalando gokapso/agent-skills (WhatsApp/Kapso) para $(agent_label "$agent") — global"
    npx -y skills add gokapso/agent-skills -g -a "$agent" || warn "falló gokapso para $agent (¿necesita auth?)"

    if [ "${PERENNIA_BIZ:-}" = "1" ]; then
      say "Instalando perennia-skills (negocio) para $(agent_label "$agent") — privado, global"
      npx -y skills add perennia-regen/perennia-skills -g -a "$agent" || warn "falló perennia-skills para $agent (¿auth gh?)"
    fi
  done

  if [ "${PERENNIA_BIZ:-}" != "1" ]; then
    printf "\n   (equipo comercial: corré 'PERENNIA_BIZ=1 %s' para sumar perennia-skills)\n" "$0"
  fi
fi

# --- 3. Engram (memoria local + cloud colaborativo) ---------------------------
if have engram; then
  ENGRAM_BIN="$(command -v engram)"

  if have codex; then
    if codex mcp get engram >/dev/null 2>&1; then
      say "Codex ya tiene MCP engram registrado"
    else
      say "Registrando MCP engram en Codex"
      codex mcp add engram -- "$ENGRAM_BIN" mcp --tools=agent || warn "no pude registrar engram en Codex"
    fi
  else
    warn "Codex CLI no está en PATH; salteo registro MCP de Codex."
  fi

  if have claude; then
    if claude mcp list 2>/dev/null | grep -qi '^engram'; then
      say "Claude Code ya tiene MCP engram registrado"
    else
      say "Registrando MCP engram en Claude Code (user scope)"
      claude mcp add engram --scope user -- "$ENGRAM_BIN" mcp --tools=agent || warn "no pude registrar engram en Claude Code"
    fi
  else
    warn "Claude Code CLI no está en PATH; salteo registro MCP de Claude."
  fi

  if [ -z "${ENGRAM_CLOUD_SERVER:-}" ] && [ -n "${ENGRAM_CLOUD_TOKEN:-}" ]; then
    ENGRAM_CLOUD_SERVER="$DEFAULT_ENGRAM_CLOUD_SERVER"
  fi

  if [ -n "${ENGRAM_CLOUD_SERVER:-}" ]; then
    say "Configurando servidor cloud de Engram"
    engram cloud config --server "$ENGRAM_CLOUD_SERVER" || warn "no pude configurar ENGRAM_CLOUD_SERVER"
    if [ "$(uname -s)" = "Darwin" ]; then
      launchctl setenv ENGRAM_CLOUD_SERVER "$ENGRAM_CLOUD_SERVER" >/dev/null 2>&1 || true
    fi
  fi

  if [ -n "${ENGRAM_CLOUD_TOKEN:-}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      launchctl setenv ENGRAM_CLOUD_TOKEN "$ENGRAM_CLOUD_TOKEN" >/dev/null 2>&1 || true
    fi

    say "Sincronizando proyectos Engram con cloud"
    for repo in $DEV_REPOS; do
      [ -d "$repo/.git" ] || continue
      project="$(project_name_for_repo "$repo")"
      if [ -d "$repo/.engram" ]; then
        (cd "$repo" && engram sync --import) || warn "falló import local de .engram en $project"
      fi
      engram cloud enroll "$project" >/dev/null 2>&1 || true
      engram sync --cloud --project "$project" || warn "falló sync cloud de $project"
    done

    if [ "$(uname -s)" = "Darwin" ] && [ -d "$HOME/Library/LaunchAgents" ]; then
      plist="$HOME/Library/LaunchAgents/dev.engram.serve.plist"
      say "Configurando Engram autosync con launchd"
      cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.engram.serve</string>
  <key>ProgramArguments</key>
  <array>
    <string>$ENGRAM_BIN</string>
    <string>serve</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/.engram/engram-serve.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.engram/engram-serve.err.log</string>
</dict>
</plist>
EOF
      launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
      launchctl bootstrap "gui/$(id -u)" "$plist" >/dev/null 2>&1 || warn "no pude cargar dev.engram.serve"
      launchctl enable "gui/$(id -u)/dev.engram.serve" >/dev/null 2>&1 || true
    fi
  else
    warn "ENGRAM_CLOUD_TOKEN no está seteado; Engram queda local/MCP. Para colaborar, configurá cloud y re-ejecutá."
  fi
else
  warn "Engram no está instalado. Instalalo con Gentle AI o Homebrew y re-ejecutá este script."
fi

say "Listo. Verificá con: npx skills list -g | codex mcp list | engram projects list"
