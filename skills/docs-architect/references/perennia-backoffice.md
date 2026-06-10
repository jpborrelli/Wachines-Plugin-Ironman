# Project config — Perennia BackOffice

Concrete configuration for the `docs-architect` skill when working in the **Perennia
BackOffice** repo. The skill is generic; this is the project overlay the Perennia team uses.

## Documentation layout (`docs/`)
- `docs/dev/` — developer guide hub. Key files: `GUIA_DESARROLLO.md`, `TESTING.md`,
  `ANTIPATRONES.md`, runbooks/postmortems (`RUNBOOK_KAPSO.md`, `POSTMORTEM_*`).
- `docs/arquitectura/` — multi-tenant architecture hub (módulos, UdN, roadmap por olas).
  **Read `docs/arquitectura/README.md` first.**
- `docs/sara/` — SARA program: `comercial/how-to/`, `data-collection/how-to/`.
- `docs/presupuestos/`, `docs/facturacion/` (incl. `RECIBOS_Y_PAGOS.md`),
  `docs/honorarios/`, `docs/clientes/` (incl. `REFRESH_ESTABLECIMIENTOS.md`).

Docs follow the **Diataxis-ish** split (how-to vs reference) and the **colocation principle** —
docs live close to what they document.

## Project-specific audit rules
- **Schema is documented in the DB itself:** every table/column/function/trigger must have a
  `COMMENT ON` explaining what it is for — these comments are the living schema documentation.
  When auditing schema docs, check `COMMENT ON` coverage, not just markdown.
- **Migrations:** `YYYYMMDDHHMMSS_<dominio>_descripcion.sql`; DDD domain definitions live in
  `supabase/domains/<dominio>/`.
- **Commits:** Conventional Commits, `docs:` prefix for documentation changes.
- **Cross-check** doc claims against the real schema dump `supabase/schema-remote.sql` and the
  anti-patterns catalog `docs/dev/ANTIPATRONES.md` before flagging drift.

## Sub-agent streams to spawn for a full BackOffice audit
1. **Schema & DB docs** — `COMMENT ON` coverage + `docs/dev/` vs `supabase/domains/` & schema dump.
2. **Architecture docs** — `docs/arquitectura/` completeness; decisions lacking ADRs; root
   `CLAUDE.md` synced with reality.
3. **Domain how-tos** — `docs/sara/`, `docs/presupuestos/`, `docs/facturacion/`, `docs/honorarios/`.
4. **Link & reference validator** — broken links/paths across all markdown.
5. **Structure & consistency** — naming, hierarchy, formatting, information architecture.
