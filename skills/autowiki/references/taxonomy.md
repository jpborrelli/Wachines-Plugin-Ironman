# Taxonomía AutoWiki (Factory.ai) — referencia

Ingeniería inversa del producto **AutoWiki** de Factory.ai (GA 2026-06-19), de su doc
técnica y de comparar las wikis reales de React/Kubernetes/Django. Es el estándar contra
el que esta skill genera y audita.

## Principio: doc = build artifact

*"Documentation should be a build artifact, not a side project."* La doc de referencia se
**compila del código**, no se escribe a mano, y se **regenera en cada push**. Si es un
artefacto de build, nunca queda desincronizada.

## El eje que ordena todo: GENERATED vs AUTHORED

- **GENERATED** (clase `reference`): hechos que el código ya contiene — conteos, inventarios,
  mapa de directorios, listas de funciones/rutas/migraciones. Se **generan o se omiten,
  nunca se copian a mano** (un AUTHORED que sostiene un hecho generable envejece apenas
  cambia el código). → los produce `scripts/gen-docs.mjs` en `docs/reference/`.
- **AUTHORED**: el *por qué* — arquitectura, decisiones (ADRs), trade-offs, narrativa de
  dominio. Lo escribe un humano (o la skill `docs-architect` ayuda a auditarlo). No lo toca
  el generador.

Esta skill cubre el lado **GENERATED**. La skill `docs-architect` cubre la auditoría/anti-drift
del lado AUTHORED. Son complementarias.

## Las secciones de una wiki AutoWiki

**Esqueleto fijo** (aparece siempre, en React/K8s/Django):
`Overview` (+ Architecture, Getting Started, Glossary) · `By the Numbers` · `Lore` ·
`Fun Facts` · `How to Contribute` · `Reference` · `Maintainers`.

**Secciones que se adaptan a la escala/stack** (aparecen según lo que el generador encuentra):
`Packages` (monorepos) · `Components` · `Systems` · `Primitives` · `API` · `Security` ·
`Features` · páginas dedicadas por subsistema.

> Regla: a más grande el repo, más se subdivide. El generador decide la estructura según lo
> que encuentra, no aplica plantilla rígida.

## Qué genera ESTA skill (subset determinístico, sin LLM)

De las secciones de arriba, las **mecánicas/determinísticas** se computan del código en CI
(gratis, reproducible). El resto (Glossary narrativo, Lore, Architecture) es AUTHORED.

| Página generada | Contenido | Sección AutoWiki |
|---|---|---|
| `by-the-numbers.md` | LOC, # archivos, componentes, SQL, tests, docs | By the Numbers |
| `repo-map.md` | Directorios top-level con conteos + descripción | (Project Structure) |
| `inventories.md` | Migraciones, edge functions, funciones Postgres, rutas API | API / Reference |
| `README.md` | Índice de la referencia generada | (Overview) |

## Cómo analiza el código (scan en dos pasadas — el patrón de Factory)

1. **Structural scan:** README, manifests, config de CI, entry points.
2. **Semantic scan:** routes, API endpoints, service classes, DB schemas, feature flags.

Nuestro generador hace la versión determinística de esto vía `git ls-files` + patrones por
config. El "scan semántico" profundo (entender qué hace cada cosa) lo hace un **subagente al
instalar** la skill en un repo nuevo — produce el `docs-gen.config.json` (el glue por
proyecto), sin hardcodear nada en el script.

## Fuentes

- Benchmark interno: `referencias/benchmarks/factory-wiki.md` y
  `productos/fabrica/autowiki/benchmark-docs-2026-06-19.md` (en el repo Wachines-Brain).
- Factory: docs.factory.ai/cli/features/wiki/overview · factory.ai/product/autowiki
