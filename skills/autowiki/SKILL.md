---
name: autowiki
description: Genera y mantiene la documentación de referencia GENERADA de un repo (By the Numbers, mapa del repo, inventarios de funciones/migraciones/edge-functions/rutas) computándola del código con un generador determinístico, y la cablea a CI (check en PR). Sigue la taxonomía AutoWiki de Factory.ai (doc = build artifact). Usar cuando se pida instalar/regenerar docs generadas, "documentación que no envejece", un wiki del codebase, o cablear generación de docs en CI. Complementa a docs-architect (que audita la doc AUTHORED escrita a mano).
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# AutoWiki — documentación de referencia como build artifact

Generás la parte **GENERATED** de la documentación de un repo: las secciones mecánicas
(conteos, inventarios, mapa de directorios) que un humano nunca mantiene al día y que envejecen
apenas cambia el código. La computás del código con un generador **determinístico y
zero-dependency**, y la **regenerás al mergear** (push a la branch de integración) — los PRs NO
la llevan. **Lee primero [`references/taxonomy.md`](references/taxonomy.md)** (el estándar
AutoWiki + el eje GENERATED/AUTHORED).

> **Par con `docs-architect`:** esta skill **genera** lo GENERATED (`docs/reference/`).
> `docs-architect` **audita** lo AUTHORED (el *por qué*: arquitectura, ADRs). No se pisan.

## El modelo

- **GENERATED** = hechos que el código ya contiene (LOC, # funciones, lista de migraciones,
  edge functions, rutas, mapa de directorios). **Se generan, nunca se copian a mano.** Viven en
  `docs/reference/` (clase `reference`).
- **AUTHORED** = el *por qué* (arquitectura, decisiones). Lo escribe un humano. El generador no
  lo toca.
- El generador (`assets/gen-docs.mjs`) enumera archivos vía **`git ls-files`** → **CI y local
  dan idéntico resultado** sin importar cruft local. Salida sin fechas/SHAs → determinística.
- **Regenerar al MERGEAR, no por PR.** `docs/reference/by-the-numbers.md` y `repo-map.md`
  dependen del **árbol entero** (LOC, # archivos por carpeta) → si cada PR los commitea y los
  chequea, **dos PRs cualesquiera que agreguen/saquen un archivo se pisan** (conflicto + check
  stale). Por eso el workflow NO es un check de PR: corre en **`push` a la branch de
  integración** y **auto-commitea** `docs/reference` con `[skip ci]`. Los PRs no tocan
  `docs/reference`; se refresca solo al mergear. Cero conflictos cruzados.

## Cómo instalar la skill en un repo (procedimiento)

El **glue por proyecto NO se hardcodea**: lo descubre un subagente que lee el repo y produce el
config. Pasos:

1. **Descubrir el repo (scan en dos pasadas).** Mandá un subagente a leer la estructura real:
   dónde vive el código, las migraciones SQL, las edge functions (`supabase/functions/`), las
   rutas, los tipos autogenerados grandes (para excluir del LOC). Que produzca un
   **`docs-gen.config.json`** (esquema abajo). Verificá que cada `root` del config EXISTA.
2. **Copiar el generador:** `assets/gen-docs.mjs` → `scripts/gen-docs.mjs`.
3. **Copiar el workflow:** `assets/docs-generate.yml` → `.github/workflows/docs-generate.yml`,
   y reemplazá `__INTEGRATION_BRANCH__` por la branch donde aterrizan los features (main /
   staging / preview según el repo). Corre en `push` a esa branch y auto-commitea.
4. **Script de conveniencia:** agregá `"docs:gen": "node scripts/gen-docs.mjs"` al
   `package.json` root (si existe) — para regenerar a mano cuando quieras.
5. **Generar una vez y verificar determinismo:** corré `node scripts/gen-docs.mjs` dos veces y
   confirmá que la 2da corrida NO produce diff (`diff -r`). Commiteá ese `docs/reference` inicial.
   Si hay diff, el generador no es determinístico — revisá (causa típica: contar archivos no
   trackeados → ya resuelto vía `git ls-files`; o incluir la propia salida → ya se excluye `outDir`).
6. **Documentar (DX):** una nota breve en `CLAUDE.md`/`AGENTS.md`: "`docs/reference/` es
   GENERADO, **no editar a mano, NO regenerarlo en tu PR** — se refresca solo al mergear; el
   resto de `docs/` es AUTHORED; auditar con `docs-architect`".
7. **NO agregues gate por PR ni pre-push** que regenere/bloquee — eso es lo que hace que dos
   PRs se pisen. El refresh vive solo en el workflow de `push`.
8. **PR.** Commiteá solo tus archivos (sin `docs/reference`, salvo el commit inicial de install).

## El config por repo (`docs-gen.config.json`)

Ver [`assets/docs-gen.config.example.json`](assets/docs-gen.config.example.json). Campos:

- `project` — nombre legible. `outDir` — `"docs/reference"`.
- `exclude` — nombres de directorio a saltear (por segmento de path).
- `loc.exts` — extensiones para contar LOC. `loc.excludeFiles` — archivos generados grandes a
  excluir del LOC (tipos autogenerados, dumps SQL).
- `byTheNumbers[]` — métricas: `{type:"ext",exts}` · `{type:"name-suffix",suffixes}` ·
  `{type:"filename",name}`. **Evitá `filename:"index.ts"`** como proxy de edge functions
  (cuenta barrels) — usá el inventario `dirs`.
- `inventories[]` — tipos:
  - `{type:"files",root,ext?,limit?}` — lista archivos (ej. migraciones).
  - `{type:"dirs",root}` — subdirectorios (ej. edge functions).
  - `{type:"grep",roots[],ext?,pattern}` — cuenta coincidencias regex. Para funciones:
    `pattern:"create\\s+(or\\s+replace\\s+)?function"` cuenta **ocurrencias DDL, NO funciones
    únicas** — etiquetalo honesto (o mejor usá `functions`, abajo).
  - `{type:"routes",root,limit?}` — **rutas reales de Next.js App Router**: por cada `route.ts`
    emite la URL (`/api/...`) + métodos HTTP detectados, no el basename repetido. `root` = la
    carpeta `app` (ej. `web/src/app`, `grass-dashboard/src/app`).
  - `{type:"functions",roots[],schema?,limit?}` — funciones SQL **distintas** + su
    `COMMENT ON FUNCTION`. Con `schema:"api"` → **catálogo de RPCs agent-operables**. Las
    **firmas/params NO van acá**: viven en el OpenAPI vivo de PostgREST (ver abajo) — una sola
    fuente, anti-drift.
- `repoMap.describe` — `{dir: "descripción"}` de los directorios top-level reales.

## API agent-operable: el catálogo estático complementa al OpenAPI vivo

Si el repo expone RPCs en un schema (ej. `api`) vía **PostgREST** (Data API de Supabase), ese
schema **autogenera un OpenAPI** (cada `COMMENT ON FUNCTION` → `description`). Esa es la
**referencia viva con firmas/params** (renderizable con Scalar/Redoc/Swagger UI o Mintlify).
Por eso el inventory `functions schema:"api"` solo lista **nombre + COMMENT** (índice grep-able)
y deja las firmas al OpenAPI. Caveat de PostgREST: no documenta argumentos de función (no se
puede `COMMENT ON` los args) → para params, tabla dentro del COMMENT, `postgrest-openapi`, o un
overlay a mano del envelope/errores.

## Refrescar

**Automático al mergear:** el workflow de `push` regenera y auto-commitea `docs/reference` en la
branch de integración. No tenés que hacer nada en tu PR. Para verlo localmente cuando quieras:
`npm run docs:gen` (o `node scripts/gen-docs.mjs`) — pero **no lo commitees en el PR**.

## Cuándo NO usar

- Para auditar/mejorar doc escrita a mano (drift, links rotos, reorganización) → `docs-architect`.
- Para generar prosa/tutoriales con un LLM → no es esto; esto es determinístico, sin LLM.
