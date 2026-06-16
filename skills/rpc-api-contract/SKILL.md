---
name: rpc-api-contract
description: Standard for exposing business logic as a uniform, agent-operable API. Postgres business actions live under a dedicated `api` schema with a fixed success envelope ({data, effects, warnings}), RFC 7807 errors, mandatory Idempotency-Key on mutations, SECURITY DEFINER auth, and preview/confirm for heavy ops. Use when creating or exposing a business action / RPC / api endpoint / MCP tool, or when reviewing one. Forward-only from 2026-06-16.
metadata:
  author: perennia-regen
  version: "1.0.0"
license: MIT
---

# RPC / API contract

How to write a **business action** that any channel — web, WhatsApp agent, MCP, cron, third party — can call without surprises. The same operation, one definition.

> **Why this exists (canon):** the blocker to exposing our logic to agents was never "Postgres vs TypeScript" — it was the lack of a *uniform contract* (inconsistent naming, heterogeneous return types, no envelope, uneven idempotency). This skill is the operating procedure; the full rationale and the LaPyme benchmark live in the company brain page `estrategia/caso-lapyme` + `productos/profundizacion-tecnica/rpc-contract`. We assemble public conventions: **Google AIP** (resource-oriented + custom methods), **RFC 7807/9457** (errors), **Stripe / IETF Idempotency-Key**, **PostgREST** api-schema.

## When to apply

- Creating a new business action (a mutation or a non-trivial read meant to be called by a channel).
- Exposing an existing function to a new channel (web → agent/MCP/third party).
- Reviewing a migration that adds/changes a callable function.

**Forward-only:** applies to functions created **from 2026-06-16**. Legacy `rpc_*` / unprefixed / `fn_` callables stay as they are until deliberately migrated. **No mass retrofit** — strangler fig (wrap on demand when a function gets exposed to a new channel).

## The architecture (where this fits)

```
   web UI  ·  WhatsApp agent  ·  MCP  ·  cron      ← channels (each a thin adapter)
                       │  all call the same core
                       ▼
   schema `api`  =  business actions  (this contract)   ← single definition
                       ▼
   public / private / <domain> schemas  =  internal logic, triggers, helpers
```

A **channel** (the WhatsApp agent, the web) brings its own LLM/UI. An **MCP server for users** is just the `api.*` actions wrapped in MCP protocol — no logic of its own (same model as LaPyme's `api.*` + `mcp.*`). Both bottom out on `api.*`.

## The 9 rules

**R1 — The boundary is the schema, not the prefix.** Exposed actions live in a dedicated **`api`** schema (PostgREST serves one schema and generates its OpenAPI). Everything else is internal and not exposed. This is what makes the surface enumerable → OpenAPI → SDK + docs + MCP tools.

**R2 — Naming (forward-only).** Exposed: `api.<verb>_<noun>` (AIP style): `crear_`, `actualizar_`, `confirmar_`, `anular_`, `revertir_`, `listar_`, `obtener_`, `calcular_…_preview`. New internal: `fn_`. Legacy stays.

**R3 — Success envelope, never `void`.** Every `api.*` returns `jsonb`:
```json
{ "data":    { "...": "the affected resource(s): ids, amounts, state" },
  "effects": { "...": "what the command changed, grouped by domain" },
  "warnings":[ { "code": "STOCK_NEGATIVO", "message": "..." } ] }
```
`data` never absent (use `{}`/`null`). `effects` groups side-effects by domain — its **key taxonomy is per-project** (see `references/<project>.md`); what's invariant is that `effects` exists. No `ok`/`success` flag — failure travels via the error (R4). **`RETURNS void` is forbidden in `api.*`.**

**R4 — Errors, RFC 7807 style.** `RAISE EXCEPTION` with a parseable, prefixed code: `RESOURCE_NOT_FOUND: educador % no existe`. The gateway maps it to `application/problem+json` (`{type, title, status, detail, code}`). Codes in `MAYUS_SNAKE`, domain-prefixed where it helps (`LIQUIDACION_PERIODO_CERRADO`).

**R5 — Idempotency, explicit.** Mutations accept `p_idempotency_key` and use **`INSERT … ON CONFLICT`** on a unique constraint — never a prior `IF EXISTS` (races under READ COMMITTED). Declare the state in the COMMENT: `[IDEMPOTENT: ON CONFLICT (...)]` or `[NOT IDEMPOTENT: caller guarantees single invocation]`.

**R6 — Uniform auth.** `SECURITY DEFINER` + `SET search_path = ''` + an **internal access check** (`establecimiento_id` / `id_hub`) that does not depend on the caller's RLS. Identity is resolved server-side (closure / JWT) — **never** a caller-supplied argument an LLM could forge.

**R7 — Documentation is mandatory.** `COMMENT ON FUNCTION` on every `api.*`: what it does, its idempotency mark (R5), and which `effects` it produces. (This is what `db-reviewer` enforces and what auto-generates the docs.)

**R8 — Preview/confirm for costly or irreversible ops.** Expose a `…_preview` that returns the **same `effects` shape** without committing (dry-run), plus a `confirmar_…` that executes.

**R9 — Version without breaking.** Don't mutate a live `api.*` contract. New signature → `_v2`, deprecate the old ≥ 2 cycles. Version the schema (`api` → `api_v1`) if needed.

## Template (new compliant action)

```sql
create or replace function api.crear_<noun>(
  p_body jsonb,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor   <type> := <resolve from session, NOT from p_body>;  -- R6
  v_id      <type>;
  v_effects jsonb := '{}'::jsonb;
begin
  -- validate (read-only) → RAISE 'CODE: detalle' on failure (R4)

  insert into <domain>.<table> (...)
  values (...)
  on conflict (<idempotency unique key>) do nothing     -- R5
  returning id into v_id;

  if v_id is null then
    select id into v_id from <domain>.<table> where <idempotency key> = ...;
  end if;

  -- collect side-effects into v_effects, grouped by domain (R3)

  return jsonb_build_object(
    'data',     jsonb_build_object('<noun>_id', v_id, 'estado', '...'),
    'effects',  v_effects,
    'warnings', '[]'::jsonb
  );
end; $$;

comment on function api.crear_<noun>(jsonb, text) is
  'Crea <noun>. [IDEMPOTENT: ON CONFLICT (<key>)]. effects: {<dominios>}.';
```

## Per-project specifics

The `effects` key taxonomy and the `api` schema bootstrap differ per repo. See `references/<project>.md` (e.g. `references/perennia-backoffice.md`, `references/gestionganadera.md`) for that repo's effect domains, identity resolution, and which legacy functions are already wrapped.

## Relationship to other skills

- **`db-reviewer`** enforces this on every migration (R1/R3/R5/R6/R7). If a check here isn't in db-reviewer yet, flag it.
- **`supabase-postgres-best-practices`** covers the performance side (volatility, indexes).
- Channels (WhatsApp agent, MCP) must call `api.*` — not tables directly, not generic CRUD.
