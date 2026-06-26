# Rúbrica de health score (0-100)

Calculá el score de cada categoría (0-100), después el promedio ponderado. En modo full se calcula **before** (baseline) y **after** (post-fix); el delta es la métrica clave.

## Consola (peso 15%)
| Errores | Score |
|---|---|
| 0 | 100 |
| 1-3 | 70 |
| 4-10 | 40 |
| 10+ | 10 |

Contá tanto console errors (`agent-browser console`) como page errors / excepciones (`agent-browser errors`) y requests fallidos relevantes. Los **requests fallidos (4xx/5xx)** salen en `agent-browser console` como `Failed to load resource: ... status N`, o se chequean por `agent-browser eval "await fetch('<url>').then(r=>r.status)"`. **NO uses `agent-browser network requests` para esto** — no devuelve status codes (solo lista URLs).

**Para reproducibilidad del score** (que dos runs den el mismo número):
- **Cada síntoma cuenta UNA sola vez**, en su categoría primaria. Un error de consola se penaliza en Consola, no además en Contenido/Funcional. No doble-penalices el mismo hecho.
- **Un 404 de `favicon.ico` es cosmético (Low)** y no se trata como error de app. Excluilo (o márcalo Low) para que el score no oscile entre runs (es una causa típica de varianza tipo 88↔94).

## Links (peso 10%)
- 0 rotos → 100
- cada link roto → -15 (mínimo 0)

## Categorías por hallazgo (Visual, Funcional, UX, Contenido, Performance, Accesibilidad)
Cada una arranca en 100. Restá por hallazgo en esa categoría:
- Critical → -25
- High → -15
- Medium → -8
- Low → -3

Mínimo 0 por categoría.

## Pesos
| Categoría | Peso |
|---|---|
| Consola | 15% |
| Links | 10% |
| Visual | 10% |
| Funcional | 20% |
| UX | 15% |
| Performance | 10% |
| Contenido | 5% |
| Accesibilidad | 15% |

## Score final
`score = Σ (score_categoría × peso)`

## baseline.json
Guardá al final de la Fase 5 para permitir corridas de regresión futuras:
```json
{
  "date": "YYYY-MM-DD",
  "url": "<base url>",
  "mode": "full | report-only",
  "tier": "quick | standard | exhaustive",
  "healthScore": 0,
  "categoryScores": { "console": 0, "links": 0, "visual": 0, "functional": 0, "ux": 0, "performance": 0, "content": 0, "accessibility": 0 },
  "issues": [ { "id": "ISSUE-001", "title": "...", "severity": "high", "category": "functional" } ]
}
```

## Lectura del número
- **90-100** — calidad de producto profesional. Shippeable.
- **70-89** — sólido, con polish pendiente. Arreglar Medium+ antes de exponer a cientos.
- **50-69** — agujeros reales. No está a la vara.
- **<50** — no probar con usuarios todavía.
