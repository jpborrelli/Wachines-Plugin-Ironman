#!/usr/bin/env bash
# setup-dev.sh — instala el toolchain de skills del equipo wachines (una vez por máquina).
# Idempotente: se puede correr de nuevo para reparar/actualizar.
set -euo pipefail

say()  { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

GSTACK_DIR="$HOME/.claude/skills/gstack"

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
    git -C "$GSTACK_DIR" pull --ff-only || warn "No pude actualizar gstack (¿cambios locales?)"
  else
    say "Instalando gstack en $GSTACK_DIR"
    git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR"
    ( cd "$GSTACK_DIR" && ./setup )
  fi
fi

# --- 2. skills vía npx ---------------------------------------------------------
if have npx; then
  # -g = global (user-level): cae en ~/.claude/skills, aplica a TODOS los proyectos, no se
  # commitea en ningún repo. Sin -g, el CLI auto-detecta "project si estás dentro de un repo".
  say "Instalando wachines-skills (dev) — global"
  npx -y skills add perennia-regen/wachines-skills -g -a claude-code || warn "falló wachines-skills"

  say "Instalando gokapso/agent-skills (WhatsApp/Kapso) — global"
  npx -y skills add gokapso/agent-skills -g -a claude-code || warn "falló gokapso (¿necesita auth?)"

  if [ "${PERENNIA_BIZ:-}" = "1" ]; then
    say "Instalando perennia-skills (negocio) — privado, global"
    npx -y skills add perennia-regen/perennia-skills -g -a claude-code || warn "falló perennia-skills (¿auth gh?)"
  else
    printf "\n   (equipo comercial: corré 'PERENNIA_BIZ=1 %s' para sumar perennia-skills)\n" "$0"
  fi
fi

say "Listo. Verificá con: npx skills list   |   actualizá con: /gstack-upgrade + npx skills update"
