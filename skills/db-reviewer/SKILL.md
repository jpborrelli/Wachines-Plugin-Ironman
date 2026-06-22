---
name: db-reviewer
description: Review SQL migrations before applying them. Validates naming conventions, soft-delete filtering, COMMENT ON coverage, SECURITY DEFINER hardening, RLS policies, and Postgres performance. Use when reviewing a migration, a CREATE TABLE/FUNCTION/POLICY, or any schema change before it hits production.
metadata:
  author: perennia-regen
  version: "1.0.0"
license: MIT
---

# SQL Migration Reviewer

Review SQL migrations before they are applied to a database. The checklist below is
generic — adapt the project-specific lists (domains, soft-delete columns, RLS helper
functions) to your codebase. A worked example for a fictional project is shown in each
section so you can see the shape of a real configuration.

> **Companion skill:** for the performance checks in section 7, use the
> `supabase-postgres-best-practices` skill.

## Configure for your project (read this first)

> **Perennia BackOffice:** if you are working in the BackOffice repo, the concrete config
> (12 DDD domains, soft-delete table list, `private.*` RLS helpers, test guardrails) is in
> [`references/perennia-backoffice.md`](references/perennia-backoffice.md). Load it and skip
> the inference below.

Before reviewing, establish the project's conventions. Look in this order:
1. The project's `CLAUDE.md` / `AGENTS.md` for documented naming and schema rules.
2. A schema dump (e.g. `schema-remote.sql`, `schema.sql`) — the **source of truth** for
   which tables, columns, enums and functions actually exist. Local per-domain files can
   drift; always cross-check against the real dump to avoid false positives.
3. Existing migrations under `supabase/migrations/` (or equivalent) for established patterns.

If a project config is missing, infer conventions from the existing migrations and state
your assumptions in the review.

## Checklist

### 1. Naming convention
- Migration files usually follow a timestamped format: `YYYYMMDDHHMMSS_<area>_<description>.sql`.
- If the project groups migrations by domain/bounded-context, verify the file uses a **valid
  domain prefix**. Read the project's list of domains — do not assume.
- Flag deprecated domain names if the project documents a rename map (old → new).

  *Example config (replace with your project's):* valid domains `accounts`, `billing`,
  `catalog`, `shared`; deprecated `finance` → use `billing`.

### 2. Soft delete
If the migration does `SELECT`/`JOIN` over tables that use soft delete, verify it filters
out deleted rows. Detect the soft-delete column per table — conventions vary:
`is_deleted` (boolean), `isdeleted` (no underscore), or `deleted_at` (timestamp, filter `IS NULL`).

Build the list of soft-deleted tables from the schema (grep for the column), don't hardcode
blindly. Watch for **inconsistent column naming across tables** — that's a common trap.

### 3. COMMENT ON (gate de schema auto-descriptivo / RAG-ready)

El COMMENT es la **fuente de verdad de la semántica**: lo lee `pg_catalog`, PostgREST lo vuelve la `description` del OpenAPI, y el catálogo de RPCs/columnas se genera de ahí. Una columna sin COMMENT obliga a agentes (y humanos) a adivinar. Por eso es un **gate**, no un nice-to-have.

**Forward-only (bloquea lo nuevo):**
- Cada **tabla nueva** → `COMMENT ON TABLE`.
- Cada **columna nueva** → `COMMENT ON COLUMN`.
- Cada **función nueva** → `COMMENT ON FUNCTION`.
- Los comentarios explican **para qué sirve**, no repiten el nombre. Para enums, listar el significado de cada valor (evita drift tipo `tipo_educador`).

**Regla boy-scout — "arreglá la casa mientras la construís" (idea de Emi):**
- Cuando una migración **altera** una tabla existente (ADD/RENAME/ALTER COLUMN, nuevos índices, cambio de lógica), **aprovechá y completá el COMMENT de TODAS las columnas de esa tabla**, no solo las nuevas. Si la tabla tiene columnas viejas sin comentar, este es el momento.
- Cuando una migración **toca una función** (`CREATE OR REPLACE`), exigí su `COMMENT ON FUNCTION` aunque ya existiera sin comentar.
- Objetivo: el backfill de los ~miles de columnas sin comentar ocurre **orgánicamente sobre lo que más se edita**, sin un proyecto-mamut aparte. Cada PR de schema deja su zona mejor de como la encontró.
- Como reviewer: si ves un ALTER sobre una tabla con columnas sin comentar, **marcalo y pedí completarlas en el mismo PR** (o proponé los COMMENT vos, para validación del autor — no inventes semántica que no se deduzca del código/uso).

> Contexto: el baseline de cobertura está en el benchmark RAG-readiness (tablas ~80-93%, columnas ~17-30%). El gate forward-only + esta regla boy-scout son cómo se cierra sin reescribir todo a mano.

### 4. SECURITY DEFINER
- Any function created with `SECURITY DEFINER` **must** also `SET search_path = public`
  (or the appropriate fixed schema). Without it the function is vulnerable to
  search_path injection.

### 5. Row Level Security (RLS)

#### 5a. New tables
- A `CREATE TABLE` on a public-facing table must include
  `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- It must have at least one `CREATE POLICY` — a table with RLS enabled but no policies
  blocks all access.
- Recommended minimum: an admin `FOR ALL` policy plus role-specific policies.

#### 5b. Policies and soft delete
- If a policy's `USING` clause selects from a soft-deleted table (see section 2), it should
  filter deleted rows (`AND NOT is_deleted` / `AND deleted_at IS NULL`), especially for
  restrictive/least-privilege roles. Broad admin `FOR ALL` policies may omit it if the
  application layer already filters.

#### 5c. Policies and data types
- Verify comparisons in `USING`/`WITH CHECK` are type-safe. RLS helper functions return
  specific types — compare only against matching columns (e.g. a function returning `bigint`
  must not be compared against a `text` column without an explicit cast).

#### 5d. RLS helper functions
- Policies should reuse the project's RLS helper functions (commonly under a `private`
  schema) rather than re-implementing auth logic inline. Read which helpers exist before
  reviewing.

  *Example:* `private.is_admin()`, `private.is_staff()`, `private.get_user_role()`.

#### 5e. Test guardrails
- If the project has RLS test helpers (e.g. a function that asserts every table has RLS, or
  per-role access tests) and a test command, recommend running them and adding tests for any
  new table.

### 6. General best practices
- Use `IF NOT EXISTS` where appropriate (`CREATE INDEX`, `CREATE TABLE`).
- No magic IDs without an explanatory comment.
- Correct data types (e.g. `bigint` for FKs, `text` over `varchar`, `timestamptz` over
  `timestamp`).
- Add indexes for new FK columns.
- Avoid nested dollar quoting (`$f$` inside `$function$`) — use `quote_literal()` if needed.
- **Accent-insensitive text search.** Any user-facing fuzzy search over names/labels
  (`ILIKE`/`LIKE`, `=`, or `similarity()`/`pg_trgm`) must wrap **both** the column and the
  search term in `unaccent()` — otherwise it fails on diacritics (user types `Espin`, the
  row is `El Espín` → 0 results). Apply it consistently on both sides and combine with
  `lower()` for case-insensitivity: `unaccent(lower(col)) ILIKE unaccent(lower('%'||term||'%'))`.
  Notes: `unaccent()` is **not IMMUTABLE** by default — fine at query runtime, but a functional
  index needs an IMMUTABLE wrapper. On Supabase the extension lives in schema `extensions`, so
  schema-qualify it (`extensions.unaccent(...)`) when the function's `search_path` doesn't
  include `extensions`. Flag any text-search predicate that touches only one side.

### 7. Postgres performance
Use the `supabase-postgres-best-practices` skill to validate:
- Efficient queries (avoid N+1, correct JOINs, materialize CTEs only when needed).
- Adequate indexes for query patterns (partial, covering).
- Optimal data types.
- Function volatility (`STABLE`/`IMMUTABLE` where correct; avoid needless `VOLATILE`).
- Avoid sequential scans on large tables.

## Process

1. Read the migration under review.
2. Read related table/domain definitions for context.
3. **Cross-check against the real schema dump** — confirm any enum/column/table/function the
   migration references actually exists. Flag false positives that come from stale local files.
4. If new tables are added, verify existing RLS migrations cover the area.
5. Apply the full checklist (sections 1–7).
6. Report: **OK**, or a list of issues with line numbers and a suggested fix for each.
