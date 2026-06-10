# Project config — Perennia BackOffice

Concrete configuration for the `db-reviewer` skill when working in the **Perennia BackOffice**
repo. (The skill is generic; this is the project overlay the Perennia team uses.) Always
cross-check against the real schema dump — values here can drift.

## 1. Naming — valid domains (12)
Migration files: `YYYYMMDDHHMMSS_<dominio>_descripcion.sql`.

- **CORE:** `clientes`, `presupuestos`, `servicios`, `facturacion`, `educadores`, `sara`,
  `especializacion`, `indicadores`, `contabilidad`
- **SUPPORTING:** `gestion_interna`, `comunicacion`
- **GENERIC:** `shared`
- **Deprecated:** `finanzas` → use `facturacion`; `carbono` → use `sara`

Dedicated schemas (beyond `public`): `private` (RLS helper functions),
`plan_cerrado` / `plan_abierto` / `planificacion` (pastoreo), `datos_campo` (lotes/muestreos),
`indicadores`, `contabilidad` (libro diario, conciliación bancaria, partida doble).

## 2. Soft-delete tables — ALWAYS filter in SELECT (direct and JOINs)

| Table | Column | Domain |
|-------|--------|--------|
| `agenda` | `isdeleted` ⚠️ no underscore | servicios |
| `contenido` | `is_deleted` | gestion_interna |
| `establecimientos` | `is_deleted` | clientes |
| `presupuesto` | `is_deleted` | presupuestos |
| `linea_presupuesto` | `is_deleted` | presupuestos |
| `cuota_presupuesto` | `is_deleted` | facturacion |
| `solicitud_factura` | `is_deleted` | facturacion |
| `evento` | `is_deleted` | gestion_interna |
| `tareas` | `is_deleted` | gestion_interna |
| `token_confirmacion_presupuesto` | `is_deleted` | presupuestos |
| `sara_input_presupuesto` | `is_deleted` | sara |
| `nota_seguimiento` | `is_deleted` | gestion_interna |
| `indicadores.campana` / `indicador_valor` / `servicio` / `tacto` / `paricion` / `destete` / `pesaje` / `movimiento` / `stock` | `is_deleted` | indicadores |
| `datos_campo.dc_capa_gis` | `is_deleted` | shared |

- ⚠️ `agenda` uses `isdeleted` (no underscore); everything else uses `is_deleted`.
- `dc_capa_gis.is_deleted` also hides its children (lotes, ambientes, cruces) — no own column.
- `indicadores.*_detalle` tables have **no** soft delete (they use `ON DELETE CASCADE`).

## 3. RLS helper functions (schema `private`)
Policies must reuse these, not re-implement auth inline:
- `private.is_admin()`, `private.is_admin_or_backoffice()`, `private.is_staff()`
- `private.is_admin_or_socios()`, `private.is_admin_or_lider()`, `private.is_internal()`
- `private.get_user_role()` → `text`
- `private.get_user_grupo()` → `text` (cast to `"Grupos"` when comparing against the enum)
- `private.get_user_educador_id()` → `bigint` (compare only against `bigint` columns)

## 4. Test guardrails
- `fn_rls_check_all_tables_have_rls()` detects tables without RLS.
- `fn_rls_test_count_as_role(role, tabla)` tests access per role.
- Run: `cd web && npm run test:rls`. New tables → add tests in `web/src/test/rls/`.

## 5. DDD context files
- Domain definitions: `supabase/domains/<dominio>/tables/`.
- Real schema dump (source of truth): `supabase/schema-remote.sql` — always cross-check.
- Anti-patterns reference: `docs/dev/ANTIPATRONES.md`.
