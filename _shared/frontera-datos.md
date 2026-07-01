# Frontera de datos — Wachi Brain · RumIAndo · Engram

> **Fuente única, referenciada desde las skills.** Dónde vive cada tipo de dato en la fábrica de Perennia × Ruuts, para que el agente **enrute solo** en vez de tirar todo al mismo lado. Cuando una skill dice "guardá esto", esta tabla decide **dónde**.
>
> ⚠️ **DRAFT.** La versión canónica la escribe **L3 · WCH-114** (Pablo, keystone) como `.md` dedicado en el hub `los-wachines-sa` + el `CLAUDE.md` raíz. Esto es el modelo acordado en la sesión del 01-jul-2026 (`reuniones/2026-07-01-jb-rumiando-plugin-frontera-datos`), suficiente para operar hoy. Cuando L3 aterrice, esta referencia apunta a ella y no se duplica el criterio.

## La regla en una frase

**Hecho estructurado y gobernado → RumIAndo. Conocimiento durable y razonado → Wachi Brain. Scratch de código del repo actual → Engram.** Ante la duda, la pregunta es *"¿a quién le sirve y por cuánto tiempo?"*, no *"¿dónde es más fácil?"*.

## Los tres destinos

| Destino | Qué guarda | Cómo se escribe | Durabilidad / alcance |
|---|---|---|---|
| **RumIAndo** (Supabase, producto interno) | El **hecho gobernado**: tickets (WCH-NNN), fichas, ficheros, releases, actividad, decisiones/hallazgos de una ficha. El estado operativo de la fábrica. | **Solo por RPCs del schema `api`** (vía el MCP `conector-rumiando` cuando exista — L1/WCH-109). Campos gobernados: nunca directo a la tabla. | Fuente de verdad del **roadmap + fichas**. Lo consume todo el equipo (Camilo). |
| **Wachi Brain** (`wachines-brain`, MCP + git-first) | **Conocimiento durable**: decisiones de arquitectura (ADRs), minutas, benchmarks, el *porqué* (las tres dimensiones: hecho + contexto + razonamiento), doctrina de producto/plataforma. | **git-first:** `.md` en el repo del hub (`los-wachines-sa`) + commit + push. Escribir por `put_page`/MCP es efímero (el sync lo poda). | Compartido, cross-producto, evergreen. Consultable por significado (`search`/`query`/`think`). |
| **Engram** (`mem_save`, por-repo) | **Scratch de código del repo actual**: bugfixes, gotchas técnicos, convenciones de este codebase, decisiones de implementación chicas. | `mem_save` (MCP engram). Local + compartido al equipo tech por su cloud sync. | Por-proyecto, para el que trabaja *este* código. |

## Cómo discierne el agente (árbol de decisión)

1. **¿Es un hecho operativo de la fábrica** — un ticket, una ficha, un release, mover algo de estado? → **RumIAndo** (por RPC `api.*`). No lo guardes como memoria ni como `.md` suelto.
2. **¿Es conocimiento que le sirve al equipo dentro de seis meses** — una decisión con su porqué, una minuta, un benchmark, doctrina? → **Wachi Brain** (`.md` git-first en el hub).
3. **¿Es un detalle técnico del repo en el que estoy programando** — un gotcha, una convención, un fix no obvio? → **Engram** (`mem_save`).
4. **¿Ninguna encaja o encaja en varias?** → decidí por *durabilidad + a quién le sirve* y **avisá** dónde lo dejaste. No inventes un cuarto lugar.

## Fronteras finas (las que se confunden)

- **Brain ↔ RumIAndo.** El Brain puede conocer el **schema público** de RumIAndo (no los campos gobernados) para relacionar entidades. **Los IDs de producto en el Brain deben coincidir con los IDs de RumIAndo** — misma entidad, mismo `id`, para que un concepto del Brain enganche con su ficha/ticket real. El dato duro vive en RumIAndo; el Brain lo *referencia y razona sobre él*, no lo copia.
- **Brain ↔ Engram** (la menos determinística, en revisión). Regla de trabajo: al guardar en Engram, **registrar en el frontmatter el ticket** de RumIAndo en el que se estaba trabajando (`ticket: WCH-NNN`). Una **rutina semanal** audita tickets movidos vs. registros en Engram para detectar desvíos. Si un aprendizaje de código madura a decisión durable de producto/plataforma → **promoverlo** al Brain (git-first).
- **Memoria nativa de Claude / auto-memory.** En evaluación apagarla para que todo caiga en Brain o Engram y no haya un cuarto silo. No urgente; monitorear.

## Lo que NO va al Brain

Datos duros ya estructurados (cargas de campo, facturación, el propio backlog de RumIAndo) **no se copian** al Brain — ya viven en su Postgres. El Brain guarda lo **no estructurado / contextual** (minutas, notas, razonamiento) y *referencia* lo estructurado por ID. Nunca secretos (el sync los lleva a git y el CI los bloquea): tokens/keys → gestor de secretos, redactar en docs.

## Referencias

- Sesión que lo definió: `reuniones/2026-07-01-jb-rumiando-plugin-frontera-datos` (hub).
- Canon pendiente: **L3 · WCH-114** — `.md` de frontera + `CLAUDE.md` raíz (define A/B/C/D del Brain).
- Modelo de los 3 brains y git-first: `_meta/brains-como-funciona.md`, `_meta/operacion-gbrain-fly-supabase.md` (hub).
