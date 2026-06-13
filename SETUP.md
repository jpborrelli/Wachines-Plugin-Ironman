# Setup — toolchain de skills del equipo

> **Para todo el equipo de desarrollo (wachines).** Esto se hace **una vez por máquina**, no
> por proyecto. Las skills viven en repos centralizados, no en cada proyecto. Vos instalás el
> toolchain una vez y queda disponible en todos tus proyectos.

## TL;DR — un comando

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/perennia-regen/wachines-skills/main/bin/setup-dev.sh)
```

Esto instala: **gstack** (browse/QA/plan/review/ship), **wachines-skills** (best-practices,
reviewers, docs), y **gokapso/agent-skills** (WhatsApp/Kapso). Si sos del equipo comercial,
sumá también **perennia-skills** (ver abajo).

## Qué se instala y de dónde

| Toolkit | Qué trae | Cómo se instala | Quién lo mantiene |
|---------|----------|-----------------|-------------------|
| **gstack** | browse, qa, plan-*, review, ship, investigate, cso, design-* (~53) | `git clone … ~/.claude/skills/gstack && ./setup` (necesita [Bun](https://bun.sh) v1+) | upstream (garrytan/gstack) |
| **wachines-skills** | db-reviewer, docs-architect, frontend-design, *-best-practices, security-reviewer | `npx skills add perennia-regen/wachines-skills` | equipo wachines |
| **gokapso/agent-skills** | integrate/automate/observe WhatsApp (Kapso) | `npx skills add gokapso/agent-skills` (necesita cuenta Kapso) | upstream (gokapso) |
| **perennia-skills** (privado) | minuta, prep-reunion, coaching-comercial, html-perennia | `npx skills add perennia-regen/perennia-skills` | equipo Perennia (negocio) |

## Manual (si el script falla)

```bash
# 1. gstack (dev daily driver) — necesita Bun
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup

# 2. skills de desarrollo (wachines) — -g = global (todos los proyectos)
npx skills add perennia-regen/wachines-skills -g

# 3. WhatsApp/Kapso (si trabajás con BackOffice)
npx skills add gokapso/agent-skills -g

# 4. skills comerciales (solo equipo de negocio)
npx skills add perennia-regen/perennia-skills -g
```

## Scope: global vs proyecto (importante)

`npx skills` instala en uno de dos lugares:

| Scope | Comando | Cae en | Aplica a |
|-------|---------|--------|----------|
| **Global** ✅ | `npx skills add <repo> -g` | `~/.claude/skills/` | **todos** los proyectos |
| Proyecto | `npx skills add <repo>` (parado dentro del repo) | `.claude/skills/` | solo ese proyecto |

- **Usá `-g` siempre** para el toolchain compartido. Como usamos el mismo stack en todos lados,
  global = instalás una vez por máquina y lo tenés en todo.
- ⚠️ Sin `-g`, el CLI **auto-detecta**: si lo corrés dentro de un proyecto, instala a scope
  proyecto sin avisar. Por eso el bootstrap fuerza `-g`.
- **El CLI NO toca `.gitignore`.** Una instalación a scope proyecto se commitearía al repo si no
  la gitignoreás vos. En estos repos las skills compartidas ya están gitignoreadas — no las
  re-instales a scope proyecto. Si un proyecto necesita un set propio, usá `skills-lock.json` +
  `npx skills experimental_install` (patrón node_modules: commiteás el lock, gitignoreás los archivos).

## Mantener al día

```bash
/gstack-upgrade        # actualiza gstack
npx skills update      # actualiza wachines + perennia + gokapso (todo lo de npx skills)
```

O usá la skill **`perennia-upgrade`** que hace ambos en un paso.

## 📜 Política de skills (leer esto)

**Las skills compartidas NO se editan ni se commitean dentro del proyecto.** Viven en sus repos
centralizados y se instalan con `npx skills add`. En los proyectos están **gitignoradas** (igual
que `node_modules`).

- ✅ **Usar una skill** → ya la tenés instalada del toolchain. Nada que hacer.
- ✅ **Mejorar o agregar una skill** → abrí una **branch** en el repo de skills que corresponda
  (`wachines-skills` para dev, `perennia-skills` para negocio) y mandá un **PR**. No la edites
  en el `.claude/skills/` de un proyecto: ese cambio no se comparte y se pierde al actualizar.
- ✅ **Skill específica de un proyecto** (acoplada a su app/datos) → esa sí vive en el proyecto
  (`reunion-usuario` en gestión ganadera, pipeline de presupuestos en BackOffice). Está tracked
  en el proyecto, no en los repos compartidos.
- ❌ **Nunca** copiar una skill compartida a mano dentro de un proyecto. Drift garantizado.

**Regla mental:** ¿la skill sirve en más de un proyecto? → repo central + `npx skills add`.
¿Solo tiene sentido en este proyecto? → vive en este proyecto.
