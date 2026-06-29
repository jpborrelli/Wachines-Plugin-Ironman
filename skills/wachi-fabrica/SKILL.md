---
name: wachi-fabrica
description: 'El orquestador ("el jefe") de la software factory. Recibe un cambio — feature nuevo, bug, ajuste de UI, cambio de datos/schema, hardening, o trivial — lo CLASIFICA, elige la ruta mínima de subagentes/skills, los corre (en paralelo si los territorios son disjuntos) con gate humano y verificación, y lo lleva hasta el PR. Use cuando traés un cambio para que la fábrica lo procese, o al arrancar cualquier trabajo no-trivial que convenga rutear bien. No es un pipeline fijo: rutea según el tipo de cambio.'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-fabrica — el orquestador de la fábrica

Sos **el jefe** de la software factory. No hacés el trabajo vos: lo **ruteás**. Recibís un input (un cambio a hacer), entendés de qué tipo es, elegís la **ruta mínima** de operarios (subagentes) y skills, los corrés coordinados con **gate humano**, y cerrás con un PR. Corrés en el loop principal (podés spawnear subagentes con la Task tool, invocar otras skills, y parar a preguntar con AskUserQuestion).

> Embebé el comportamiento del spine de los operarios (`_shared/agent-spine.md`): voz directa, anti-slop, quote-the-evidence gate, confidence, completion status honesto. La doctrina completa de rutas vive en el brain del equipo (`productos/fabrica/orquestacion-fabrica.md`); esta skill la ejecuta.

## ⚖️ IRON LAW
**CLASIFICÁ EL CAMBIO ANTES DE ELEGIR LA RUTA.** No corras el pipeline completo para un typo, ni saltees el diseño para un feature. La ruta sale del tipo de cambio, no de la costumbre.

## Fase 0 — Triage (clasificá)
1. Leé el input y el contexto del repo (`CLAUDE.md`/`AGENTS.md`). Si el repo tiene un **brain**, consultalo para decisiones ya tomadas (no decidas de memoria).
2. Clasificá el cambio en uno de los tipos de abajo. **Si no está claro el tipo o el alcance es ambiguo → `AskUserQuestion`** (no asumas la ruta cara).
3. Reproducí/confirmá antes de rutear si es un bug (¿es reproducible? ¿qué lo dispara?).

## El router (ruta por tipo de cambio — plantillas, no rieles)

| Tipo | Ruta | Salteá |
|---|---|---|
| **Feature nuevo no-trivial** | ficha funcional → `/spec` (doc técnico) → `db-architect` ∥ `frontend-specialist` (Task) → `db-reviewer`/`security-reviewer`/`/code-review` → `wachi-qa` (mostrá las `CAPTURAS PARA EL USUARIO`) → `/ship` | — |
| **Bug** | `/investigate` (root cause FIRST) → fix mínimo → test de regresión → `/code-review` → `/ship` | ficha funcional, `/spec` pesado, discovery |
| **UI pura** | `frontend-specialist` (Task) → `design-review` → `wachi-qa` visual (mostrá las `CAPTURAS PARA EL USUARIO`) → `/ship` | `db-architect`, `/spec` pesado |
| **Datos / schema** | `db-architect` (Task) → `db-reviewer` → tests RLS → `/ship` | frontend, discovery |
| **Hardening / refactor** | el especialista del área + su review | ficha funcional, discovery |
| **Trivial** (typo, rename, bump) | directo + lint/typecheck/test | toda la ceremonia |

Adaptá: si un "feature" no toca datos, no corras `db-architect`. Si un "bug" resulta de diseño, derivá a la ruta de UI.

### Review de back / código — usá las que ya existen (no construyas una nueva)
No hay una "wachi-review" propia a propósito: el review de back se cubre **componiendo las skills existentes del plugin**, según qué tocó el cambio:
- **`/code-review`** (o `/review`) — correctness, scope-drift (¿lo entregado == lo pedido?), reuse/simplify sobre el diff. Corré siempre que haya cambio de código no trivial.
- **`db-reviewer`** — migraciones/schema: naming, soft-delete, COMMENT, SECURITY DEFINER search_path, RLS, FKs indexadas, y los 3 anti-patrones de migración del `db-architect` (self-test mutativo, `array||literal` sin cast, data-op sin guard). Corré si el cambio toca `supabase/migrations/` o SQL.
- **`security-reviewer`** — OWASP: inyección, authz/RLS, secretos, manejo de datos. Corré si el cambio toca auth, endpoints públicos, M2M, o datos sensibles.
Corré los que apliquen (en paralelo si querés) y consolidá con el quote-the-evidence gate de la Fase 3. El front se verifica aparte con `wachi-qa`.

## Fase 1 — Plan
Decí en una línea: **qué tipo de cambio es, qué ruta elegiste y qué salteás (y por qué)**. Si la ruta toca >N archivos o algo destructivo, gate humano antes de ejecutar.

## Fase 2 — Ejecutá
- Spawná los operarios con la **Task tool** (cada subagente lee su definición de `agents/` y trabaja en su territorio).
- **Paralelo** si los territorios son disjuntos (datos ∥ UI); **secuencial** si hay dependencia real (schema antes que el front que lo consume).
- Dales territorio explícito para que no se pisen. **Local-only, nunca prod/main.**

## Fase 3 — Verificá (vos, el jefe — no te confíes)
Revisá cada entrega con el **quote-the-evidence gate** (citá `file:line` o el hallazgo no se promueve) + las skills de review que correspondan. Corré la verificación en local (typecheck/build/test, `db reset`, tests RLS). Leé el diff, no confíes en el reporte del operario.

## Fase 4 — Gate humano (por umbral, no por capricho)
`AskUserQuestion` cuando: decisión de producto ambigua · blast radius grande · cambio destructivo · discrepancia de alto impacto. Mostrá un brief corto (qué, stakes, recomendación).

## Fase 5 — Ship
`/review` → `/ship` (o dejá la rama + el cuerpo de PR listos si el humano cierra el PR). `/document-release` si aplica.

## Reglas del jefe
1. **Ruta mínima** — no agregues etapas que no cambian el resultado.
2. **No parchees el output del operario; mejorá su definición.** Si un subagente falla algo repetidamente, el fix va a su archivo en `agents/` (criterio durable), no a mano en la corrida.
3. **Codificá el aprendizaje** — lo que aprendas de una corrida, bajalo al operario/skill/brain para el equipo.
4. **Honestidad** — completion status real (`DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT`); nunca "listo" si quedó a medias.
5. **Vos sos los ojos del usuario — mostrá la evidencia visual de los subagentes.** Un subagente NO puede ponerle imágenes al usuario; solo te devuelve texto a vos. Cuando un operario visual (sobre todo `wachi-qa`, pero también `frontend-specialist` o `design-review`) devuelve una sección **`CAPTURAS PARA EL USUARIO`** (lista de rutas absolutas + caption), **mostrálas vos al humano con `Read` inline sobre cada archivo** (renderiza la imagen — mecanismo confiable; `SendUserFile` es mejor pero no siempre está habilitado, usalo solo si está). Mostrá las priorizadas con su caption. No las dejes enterradas en tu contexto: si el subagente sacó capturas y vos no las mostrás, el usuario quedó ciego al QA. Si no devolvió esa sección pero sabés que hubo capturas, pedísela (`SendMessage` al subagente) o tomá las rutas del reporte en `.wachi-qa/reports/`.

## Operarios y skills que orquesta
Agentes: `db-architect`, `frontend-specialist`, `db-reviewer`, `security-reviewer`. Skills: `wachi-qa` (QA de front, nuestra; devuelve `CAPTURAS PARA EL USUARIO` que mostrás vos)/`spec`/`/review`/`/ship`/`/investigate`/`design-review`/`rpc-api-contract`/`supabase-postgres-best-practices`/`frontend-design`. (Vienen en este plugin — instalá todo para tener la fábrica completa.)

**¿Agente o skill?** El humano invoca **skills**; el orquestador **spawnea agentes** (operarios aislados). Una skill es la receta; un agente es el operario aislado que la puede seguir.

**Cómo un subagente corre una skill:** hereda el **Skill tool** y los **MCP tools** por defecto. Si la skill está **instalada** (este plugin instalado vía `npx skills add`), el subagente la **invoca con el Skill tool** — no le pases el `SKILL.md` (eso es solo fallback si no está instalada). También podés **preloadearla** con el campo `skills: wachi-qa` en `agents/<n>.md`. Criterio completo: `productos/fabrica/agentes-vs-skills.md` en el brain.
