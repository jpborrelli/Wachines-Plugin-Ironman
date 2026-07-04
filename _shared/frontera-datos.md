# Frontera de datos — Repo · Engram · RumIAndo · Wachi Brain · nativa

> **Copia operativa del plugin** (self-contained: el plugin se instala fuera del hub). El
> **razonamiento completo, los casos frontera y el porqué** viven en el canon:
> `_meta/frontera-datos.md` (hub `Wachines-Brain`). Acá va solo lo que una skill necesita para
> **enrutar solo**. Si algo no está acá, consultá el canon o `mis_capacidades` del conector.

## Principio 0 — escritura ≠ lectura

Esto gobierna dónde se **escribe** cada cosa (quién la *posee*). La **lectura es libre y
cross-canal**: cualquier skill *lee* el Brain (MCP `query`/`search`), *lee* RumIAndo
(`conector-rumiando`) y *lee* su propio repo — sin romper la frontera. **Poseer es de a uno; leer
es de todos.**

## La regla en una línea

**Hecho operativo gobernado → RumIAndo. Doc/decisión técnica de UN producto → su repo (+ gotcha →
Engram). Conocimiento durable TRANSVERSAL + el porqué de empresa → Wachi Brain. Nativa → en
observación.** El discriminante es **naturaleza + durabilidad + ALCANCE** (¿de un producto o del
ecosistema?).

## Los cinco canales

> ⚠️ "Repo" = repos de **código** (GRASS, BackOffice, RumIAndo, GG…). El repo-hub `Wachines-Brain` **ES el Brain**, no "el repo".

| Destino | Qué POSEE | Con qué |
|---|---|---|
| **Repo del producto** | Docs técnicas, **ADRs de producto**, specs, README, doc del conector, `CLAUDE.md`, doc generada (autowiki) | git, en el repo (`/docs`, `/docs/adr`) |
| **Engram** | Gotchas, causa-raíz de bugs, convenciones, fixes no obvios, scratch SDD | `mem_save`, con `ticket: WCH-NNN` en frontmatter |
| **RumIAndo** | Fichas, tickets, ficheros, releases, sesiones, estados, presentaciones | `conector-rumiando` (tools `api.*`; empezá con `mis_capacidades`) |
| **Wachi Brain** | Decisiones **transversales**, estrategia, minutas, benchmarks, análisis del ecosistema, grafo; **referencia** lo de los repos/RumIAndo | `.md` **git-first** en el hub + push (NO `put_page`, efímero) |
| **Nativa** *(observación)* | Nada durable/compartible | — (no apagada aún; monitorear) |

## Cómo discierne el agente

1. **¿Hecho operativo de la fábrica** — ticket, ficha, sesión, release, mover de estado? → **RumIAndo** (por el conector).
2. **¿Decisión/ADR o doc técnica de UN producto** — cómo este repo resuelve algo? → **el repo** (`/docs/adr`); su gotcha → **Engram**.
3. **¿Gotcha / convención / fix del repo que estoy tocando?** → **Engram** (`mem_save` con `ticket:`).
4. **¿Conocimiento durable TRANSVERSAL** — decisión de ecosistema, minuta, estrategia, benchmark? → **Wachi Brain** (`.md` git-first).
5. **¿Encaja en varias?** → por *durabilidad + a quién sirve + alcance*, y **avisá dónde lo dejaste**. No inventes un 6º lugar.

## Reglas del alcance (lo que más se confunde)

- **Decisión de producto → repo · decisión transversal → Brain.** No todo ADR va al Brain; solo los transversales. El Brain **referencia** los ADRs de producto, no los copia (cero drift).
- **Handoff en el build:** pre-build la spec es **ficha (RumIAndo)**; al construir (ficha `EN_BUILD`→`SHIPPED`), la verdad técnica **migra al repo** (autowiki + ADRs).
- **Repo vs Engram:** repo = doc *formal* versionada; Engram = memoria *informal* ("ojo con esto") recuperable por búsqueda.
- **Nunca secretos** en ningún `.md` (el CI los bloquea) → gestor de secretos.

## Referencias

- **Canon (razonamiento completo + tabla "esto → X"):** `_meta/frontera-datos.md` (hub).
- Sesión que lo definió: `reuniones/2026-07-01-jb-rumiando-plugin-frontera-datos` (hub).
- Conexión al conector: `skills/wachi-producto/references/aterrizaje-rumiando.md`.
