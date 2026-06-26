# QA Report: {APP}

| Campo | Valor |
|---|---|
| **Fecha** | {YYYY-MM-DD} |
| **URL** | {BASE_URL} |
| **Branch** | {BRANCH} |
| **Modo** | full / report-only |
| **Tier** | quick / standard / exhaustive |
| **Scope** | {scope o "App completa"} |
| **Arranque** | portless ({PORTLESS_URL}) / npm run dev (:{PUERTO}) / URL dada |
| **Duración** | {DURACIÓN} |
| **Páginas visitadas** | {N} |
| **Screenshots** | {N} |
| **Framework** | {detectado o "Desconocido"} |
| **Motor** | agent-browser |

## Health Score: {SCORE_BEFORE} → {SCORE_AFTER} ({DELTA})

| Categoría | Before | After |
|---|---|---|
| Consola | {0-100} | {0-100} |
| Links | | |
| Visual | | |
| Funcional | | |
| UX | | |
| Performance | | |
| Contenido | | |
| Accesibilidad | | |

## Top 3 para arreglar
1. **{ISSUE-NNN}: {título}** — {una línea}
2. **{ISSUE-NNN}: {título}** — {una línea}
3. **{ISSUE-NNN}: {título}** — {una línea}

## Console health
| Error | Count | Primera vez |
|---|---|---|
| {mensaje} | {N} | {URL} |

## Resumen
| Severidad | Count |
|---|---|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| **Total** | **0** |

## Issues

### ISSUE-001: {título corto}
| Campo | Valor |
|---|---|
| **Severidad** | critical / high / medium / low |
| **Categoría** | visual / funcional / ux / contenido / performance / consola / accesibilidad |
| **URL** | {URL de la página} |

**Descripción:** {qué está mal, esperado vs actual.}

**Repro:**
1. Ir a {URL}
   ![before](screenshots/issue-001-before.png)
2. {acción}
3. **Observar:** {qué sale mal}
   ![after](screenshots/issue-001-after.png)

**Consola:** {error JS / request fallido capturado, o "limpia"}

**Fix status** (modo full): verified / best-effort / reverted / deferred
**Commit** (si fixed): {SHA}
**Archivos** (si fixed): {archivos}

---

## Fixes aplicados (modo full)
| Issue | Fix status | Commit | Archivos |
|---|---|---|---|
| ISSUE-NNN | verified / best-effort / reverted / deferred | {SHA} | {archivos} |

## Ship readiness
| Métrica | Valor |
|---|---|
| Health score | {before} → {after} ({delta}) |
| Issues encontrados | N |
| Fixes aplicados | N (verified: X, best-effort: Y, reverted: Z) |
| Deferred | N |

**Resumen para PR:** "QA encontró N issues, arregló M, health score X → Y."

**Completion status:** DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
