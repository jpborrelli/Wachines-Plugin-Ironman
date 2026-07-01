---
name: rumiando
description: Operar RumIAndo — el producto interno de gestión de Los Wachines SA (Perennia × Ruuts): tickets (WCH-NNN), fichas, ficheros y releases de la software factory. Usar SIEMPRE que se gestione el backlog/roadmap del equipo desde Claude — crear/mover/actualizar un ticket, crear o versionar una ficha o fichero, buscar el estado de un producto, registrar una decisión o hallazgo, armar un release. Codifica el modelo fichero/ficha, la frontera de datos (qué va a RumIAndo vs Wachi Brain vs Engram) y el contrato de RPCs del schema `api` que expone el MCP `conector-rumiando`. Pensada para el equipo de producto (Camilo) — gestión, no código. NO es para tocar el código de la app RumIAndo (eso es la fábrica normal), ni para los productos de cliente (GRASS, Plataforma-Técnicos, Plataforma-Productores).
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /rumiando — operar la gestión de la fábrica

**RumIAndo** es el producto interno del equipo: donde vive el **roadmap + las fichas + la software factory** de Los Wachines SA (Perennia × Ruuts). Es el **dogfood de la fábrica** — la maqueta HTML de Camilo vuelta producto real sobre Supabase. Esta skill es para **operar la gestión** (tickets, fichas, releases) desde Claude, pensada para el **equipo de producto**: gestión, no código.

> Repo de la app: `github.com/Perennia-Regeneracion/RumIAndo` (`~/Documents/RumIAndo`). El proyecto Supabase y el ref exacto viven en el `CLAUDE.md` de ese repo — no se duplican acá para no driftear. Esta skill opera el **contrato** (`api.*` RPCs), no el código.

## ⚖️ IRON LAW
**El estado de la fábrica se escribe SOLO por RPCs del schema `api`, nunca directo a la tabla.** Los campos gobernados solo se modifican por las RPCs que el equipo definió. Ir siempre por RPC — por prolijidad y para que la actividad quede registrada.

## El modelo fichero / ficha (leé esto primero)

Todo en RumIAndo cuelga de un **producto** (`id_producto`). Cada producto tiene **ficheros**, y cada fichero agrupa **fichas**.

| Concepto | Qué es | Ejemplo |
|---|---|---|
| **Producto** | Una unidad de trabajo del ecosistema. El **plugin Ironman** es un producto dentro de RumIAndo. | GRASS · Plataforma-Técnicos · **plugin Ironman (la fábrica)** |
| **Fichero** | Agrupador de fichas. Tiene un **tipo**: `pantalla`, `skill`, `agente`. | La skill `wachi-qa` es un fichero de tipo `skill`; el agente `db-architect` es un fichero de tipo `agente`. |
| **Ficha** | La unidad de capacidad/feature, **versionada**, con un ciclo de vida (lifecycle). | Una capacidad de un agente, un módulo de una pantalla. |
| **Ticket** (WCH-NNN) | Una unidad de trabajo del backlog/roadmap, con estado, área, owner, fase. | WCH-116 |
| **Release** | Un corte versionado de un fichero, que agrupa fichas y avanza por estados. | El release v1 de una pantalla. |

**El plugin Ironman modelado como producto** (L6/WCH-113): cada **skill es un fichero** (con sus fichas adentro); cada **agente es un fichero** de tipo `agente` (las skills son instrucciones del agente, no fichas propias). La ficha de un agente = **capacidad con comportamiento esperado + contrato de éxito** (≈ el set de evaluaciones que determina cómo se construye el agente).

> **Bug conocido (L2/WCH-110):** hoy una ficha vive en **un solo** fichero; debería poder vivir en varios (ej. un módulo de botones que aparece en varias pantallas). Si el trabajo lo requiere, avisá — la migración la maneja JB. No lo asumas resuelto.

## Cómo se opera — el MCP `conector-rumiando`

RumIAndo se maneja por RPCs del schema `api` (envelope `{data, effects, warnings}`, con `idempotency_key` para las escrituras). El **MCP `conector-rumiando`** (L1/WCH-109) las expone una por una.

> ⚠️ **TODO — enganchar el MCP cuando L1 (WCH-109) esté listo.** Hasta entonces el MCP `conector-rumiando` puede no estar conectado. Las RPCs **ya existen** como funciones del schema `api` en el Supabase de RumIAndo — se invocan por el MCP cuando esté, o (fallback) por el conector de plataforma / SQL contra ese schema. Cuando el MCP aterrice, esta sección lista las tools 1:1 con estas RPCs; el contrato no cambia.

### Las RPCs que usás (schema `api`)

**Tickets (el backlog / roadmap de Camilo):**
- `api.crear_ticket(p_titulo, p_descripcion, p_id_producto, p_area, p_estado, p_prioridad, p_id_owner, p_fase, p_fecha_inicio, p_fecha_fin)` — alta de ticket. El código WCH-NNN lo asigna la base.
- `api.mover_ticket(p_id_ticket, p_estado)` — cambia el estado (backlog → in_progress → done, etc.).
- `api.actualizar_ticket(...)` — edita campos del ticket.

**Fichas:**
- `api.buscar_fichas(...)` — buscar/listar fichas de un producto (empezá por acá para orientarte).
- `api.criar_ficha(p_id_producto, p_tipo, p_titulo, p_id_fichero, p_contenido, p_idempotency_key)` — alta de ficha.
- `api.guardar_ficha(p_id_producto, p_tipo, p_titulo, p_contenido, p_id_ficha, p_nota, p_estado)` — upsert/versionado de ficha.
- `api.transition_ficha(...)` — avanzar el lifecycle de una ficha.
- `api.eliminar_ficha(p_id_ficha, p_idempotency_key)` — soft-delete.
- `api.actualizar_dor_ficha(...)` / `api.resolver_adr_ficha(...)` / `api.vincular_adr_ficha(...)` — Definition-of-Ready y ADRs de una ficha.
- `api.agregar_decision(...)` / `api.agregar_hallazgo(...)` — registrar el *porqué* (decisión) o un hallazgo sobre una ficha.

**Ficheros:**
- `api.crear_fichero(...)` · `api.actualizar_fichero(...)` · `api.archivar_fichero(...)` · `api.reasignar_fichas_fichero(...)`.

**Releases:**
- `api.crear_release(p_id_fichero, p_nombre, p_descripcion, p_idempotency_key)` · `api.agregar_ficha_a_release(p_id_release, p_id_ficha, p_notas, p_orden, p_idempotency_key)` · `api.avanzar_release(p_id_release, p_idempotency_key)` · `api.deprecar_release(p_id_release, p_idempotency_key)`.

**Contexto / lectura:**
- `api.resumen_producto(...)` — el estado de un producto de un vistazo. Buen punto de entrada.
- `api.actividad_filtrada(...)` — el feed de actividad (toda escritura por RPC deja registro).

> Las firmas de arriba son el contrato vigente (extraídas de las migraciones). Confirmá parámetros exactos con la tool del MCP o el `COMMENT ON FUNCTION` de cada RPC; las escrituras aceptan `p_idempotency_key` — pasalo para que un reintento no duplique.

### Regla de desarrollo (compound engineering — L7/WCH-115)
**RPC nueva → se expone en el MCP `conector-rumiando`.** Un bot en cada PR lista los RPCs del schema `api` y agrega los nuevos a un `.md` de inventario (autodocumentación). Si creás/cambiás una RPC de gestión, verificá que quede expuesta y documentada — no dejes contrato huérfano.

## La frontera de datos (dónde guardar qué)

No todo va a RumIAndo. Antes de guardar cualquier cosa, aplicá **`_shared/frontera-datos.md`** (la fuente única):

- **Hecho gobernado de la fábrica** (ticket, ficha, release, decisión de una ficha) → **RumIAndo**, por RPC `api.*`.
- **Conocimiento durable + su porqué** (decisión de arquitectura, minuta, benchmark, doctrina) → **Wachi Brain**, git-first (`.md` en el hub `los-wachines-sa`).
- **Scratch de código del repo actual** (gotcha, convención técnica, fix no obvio) → **Engram** (`mem_save`).

**Al guardar en Engram, registrá el ticket en el frontmatter** (`ticket: WCH-NNN`) — una rutina semanal audita tickets movidos vs. registros para detectar desvíos. Los **IDs de producto** que uses acá deben **coincidir** con los de RumIAndo para que el Brain enganche conceptos con sus fichas/tickets reales.

## Flujo típico (Camilo gestionando el backlog)

1. **Orientate:** `api.resumen_producto` del producto en cuestión, o `api.buscar_fichas` / `api.actividad_filtrada` para ver el estado actual. No crees a ciegas.
2. **Escribí por RPC** con `idempotency_key`: creá/mové el ticket, guardá/versioná la ficha. Nunca UPDATE directo a la tabla.
3. **Registrá el porqué** cuando corresponda: `api.agregar_decision` sobre la ficha (el razonamiento es una de las tres dimensiones, no lo pierdas).
4. **Enrutá lo que aprendiste** por la frontera de datos: ¿es hecho de fábrica (ya quedó en RumIAndo), doctrina durable (Brain) o gotcha de código (Engram)?
5. **Confirmá y avisá** en qué quedó — qué ticket/ficha tocaste y qué `effects` devolvió el envelope.

## Reglas
1. **RPC siempre** — el estado gobernado se escribe por `api.*`, nunca directo a la tabla.
2. **Idempotencia** — pasá `p_idempotency_key` en las escrituras; un reintento no debe duplicar.
3. **Frontera de datos** — antes de guardar, decidí destino con `_shared/frontera-datos.md`. No tires todo a RumIAndo.
4. **IDs coherentes** — mismo `id_producto` en RumIAndo, Brain y Engram para la misma entidad.
5. **Gobernanza del repo** — la app RumIAndo es solo-`main`: `feature → PR a main`, Conventional Commits, nunca push directo ni secretos. (Esto es para cuando toques *código*; la gestión de tickets va por RPC.)
6. **Honestidad** — reportá lo que efectivamente pasó (los `effects`/`warnings` del envelope), no "listo" a ciegas.
