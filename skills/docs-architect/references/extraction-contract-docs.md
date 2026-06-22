# Extraction-contract docs (OCR / parsers / scrapers)

A special audit dimension for repos that turn **unstructured documents into structured DB rows**
through a schema — OCR edge functions, PDF/email parsers, scrapers. Load this when the repo has
extraction code (typically `supabase/functions/ocr-*`, `functions/*parser*`, `*-scraper`) and a doc
that tracks its evolution.

## Why this is its own dimension

These functions share an economics that breaks the usual "code is self-documenting" assumption:
**few users, very many edge cases.** Every new source document (a different cooperative, broker,
processor, bank layout) tends to add a field to the extraction schema. That growth is real
knowledge — *what field was added, why, which document triggered it, where it lands in the DB* —
and it is **invisible in the code**: the `JSON_SCHEMA` shows the current shape, never the history or
the rationale. Lose it and you cannot:

- **port the function** to another runtime/provider without reverse-engineering the contract field
  by field; or
- **read the DB** and understand why a column is full of odd values, or why some rows have it and
  others don't.

So the convention is an **extraction-contract ledger**: an AUTHORED `canon` (one per repo, e.g.
`docs/arquitectura/OCR_EDGE_FUNCTIONS.md`) whose changelog tracks a **code-derived** schema. That
makes it a canon with a *three-way drift surface* the normal taxonomy doesn't cover:

```
  JSON_SCHEMA (code)  ◄──►  destination table columns (DB)  ◄──►  changelog (doc)
       the shape              where each field lands              the history + why
```

A field can exist in any one of the three and be missing from the others. The job of
`docs-architect` here is to find those mismatches.

## The three checks

### 1. Coverage — every extraction function has a ledger entry
Enumerate the extraction functions (`supabase/functions/ocr-*` and siblings). Every one must have a
row in the catalog table **and** a section in the changelog of the extraction-contract doc. A
function with no entry = **undocumented extractor** (critical: its contract lives only in code).

### 2. Three-way schema drift (the core check)
For each function, cross-reference the three surfaces:

- **Schema field with no changelog row** → undocumented drift. The field was added to `JSON_SCHEMA`
  but nobody recorded *when / which document / why / how existing rows were backfilled*. This is the
  highest-value finding — it is exactly the knowledge that evaporates.
- **Schema field with no destination column** → it must be explicitly noted as *"lives only in
  `datos_raw`"* (see check 3). If it isn't, flag it: either a missing column or missing documentation
  of an intentional raw-only field.
- **Destination column the schema never populates** → stale column or a parser that stopped emitting
  the field. Flag for verification against the DB.

Read the actual `JSON_SCHEMA` in the function source and the actual table columns (migrations /
generated types) — never trust the doc against another doc.

### 3. Safety-net patterns are documented
Two cross-cutting patterns keep extraction reversible; the doc must register both, and the audit
should confirm they exist in code too:

- **`datos_raw` (the safety net).** Each destination table stores the *complete* extraction output
  in a `datos_raw JSONB` column. If a structured column is left unpopulated (importer bug) or the
  schema didn't yet contemplate a field, the raw payload is still there → **backfill without
  re-uploading the document**. Caveat the doc must state: if a field was *never extracted* (not in
  the schema at capture time), `datos_raw` doesn't have it either → re-extraction is required.
- **`extract_only` mode (reprocess).** The function accepts a flag (e.g. `{ ..., extract_only: true }`)
  that returns *only* the extracted payload — no storage upload, no matching, no side effects — so a
  document already stored can be **re-run when the schema grows**. The doc should record per-function
  support status (not every function has the flag yet).

## Changelog row hygiene

Each changelog row should carry: **fecha · cambio · caso que lo disparó · mapeo a columna de DB ·
acción sobre datos existentes (backfill desde `datos_raw` o re-OCR con `extract_only`)**. A row
missing the "acción sobre datos existentes" is a half-documented change — flag it.

## Output (fold into the audit report)

Add a section to the standard report:

```markdown
## 🧬 Extraction-contract drift (OCR / parsers)
- [ ] Extractor with no ledger entry → function → add catalog row + changelog section
- [ ] Schema field with no changelog row → function.field → document trigger + mapping + backfill
- [ ] Schema field with no DB column and not noted raw-only → function.field → add column or note
- [ ] DB column the schema no longer populates → table.column → verify vs DB, mark deprecated
- [ ] datos_raw / extract_only pattern unmentioned → doc → document the safety net + reprocess mode
```

## Bootstrapping the ledger doc

If the repo has extraction functions but no ledger, recommend creating one
(`docs/arquitectura/OCR_EDGE_FUNCTIONS.md` or similar) with this structure:

1. **Why it exists** — the few-users/many-edge-cases rationale, stated for this repo.
2. **Anatomy of an extractor** — the common flow (document → schema → JSON → DB row + `datos_raw`)
   and the two cross-cutting patterns (`datos_raw`, `extract_only`).
3. **Catalog table** — one row per function: documents handled · destination table(s) · storage
   bucket · raw column · model.
4. **Per-function changelog** — for each function: a row per schema change with *fecha · cambio ·
   caso que lo disparó · mapeo a columna · acción sobre datos existentes*, plus a "gotchas confirmed
   against real documents" list.
5. **Checklist when changing a schema** — edit schema + prompt → replicate type on the front →
   deploy → backfill-vs-re-extract decision → **record the changelog row** → regenerate types.

The audit checks above verify a ledger built this way stays in sync with the code.
