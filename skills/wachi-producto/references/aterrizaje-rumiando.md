# Aterrizaje en RumIAndo — el contrato de la capa de producto

> **Qué es esto:** el mapa "etapa del proceso → RPC de RumIAndo" que usan `wachi-producto` y sus skills-hijas. Todo avance del proceso de producto **aterriza acá**: si no quedó en RumIAndo, no pasó. Fiel al schema `api` real (migraciones hasta `20260702000200_mcp_metadata.sql`, 2026-07-02). Si JB re-adapta el modelo (ejes de estado, templates), este archivo se actualiza — las skills referencian esto, no hardcodean firmas.
>
> **Cómo se invoca:** vía el MCP `conector-rumiando` cuando esté (L1/WCH-109 — el sustrato de discovery `api.listar_tablas`/`api.describir_tabla` ya existe). **TODO: listar acá las tools del MCP 1:1 cuando aterrice.** Mientras tanto: RPCs del schema `api` por SQL/conector de plataforma.

## Reglas del contrato (aplican a todo)

- **Solo por RPC `api.*`** — el estado gobernado nunca se toca directo en la tabla. El estado de la ficha **solo** cambia por `api.transition_ficha` (`guardar_ficha` ignora `p_estado` con warning `ESTADO_IGNORADO`).
- **Idempotencia:** toda mutación acepta `p_idempotency_key` — pasalo SIEMPRE (un reintento no debe duplicar).
- **Envelope:** las mutaciones devuelven `{data, effects, warnings}`; los errores son códigos UPPERCASE (`NO_AUTORIZADO`, `FICHA_INEXISTENTE`, `TRANSICION_INVALIDA`…). Reportá los `effects` reales, no "listo".
- **Lecturas** (`buscar_fichas`, `resumen_producto`, `actividad_filtrada`, `listar_tablas`, `describir_tabla`): STABLE, sin envelope.
- **Soft-delete** en todo (`deleted_at`); la actividad se registra sola en cada RPC.

## La state machine de la ficha (hoy)

Tipos de ficha: `funcional` | `tecnica` | `sofa-asset`. Estado default al crear: `IDEA`.

```
IDEA → BORRADOR → PARA_VALIDAR → VALIDADA → READY_TO_BUILD → EN_BUILD → SHIPPED (terminal)
         ↑↓ retrocesos: BORRADOR→IDEA · PARA_VALIDAR→BORRADOR · READY_TO_BUILD→VALIDADA · EN_BUILD→READY_TO_BUILD
VALIDADA ⇄ ADR_GATED  (vincular ADR auto-gatea; se vuelve a VALIDADA cuando todos resueltos)
```

Gates duros en `transition_ficha()`:
- → `READY_TO_BUILD`: DoR no vacío (`DOB_VACIO`) y todos los ítems `done=true` (`DOB_INCOMPLETO`).
- `ADR_GATED` → `VALIDADA`: todos los ADRs con `resuelto_at` (`ADR_PENDIENTE`).
- Cualquier salto fuera de la tabla: `TRANSICION_INVALIDA`.

## RPCs por etapa del proceso

### Orientarse (siempre primero — no crees a ciegas)
| RPC | Para qué |
|---|---|
| `api.resumen_producto(...)` | El estado de un producto de un vistazo |
| `api.buscar_fichas(p_query, p_id_producto?, p_id_fichero?, p_estados?, p_limit?)` | FTS español sobre títulos; devuelve snippets con estado y rank |
| `api.actividad_filtrada(p_entidad?, p_entidad_codigo?, p_id_producto?, p_limit?)` | Feed de actividad con autor |

### Intake (idea cruda → ficha `IDEA` + contexto crudo)
| RPC | Para qué |
|---|---|
| `api.crear_producto(p_slug, p_nombre, p_descripcion?, p_macro?, p_color?, p_orden?, key?)` | Alta de producto (`p_macro`: `tech`\|`uxui`\|`producto`\|`gestion`) — raro, solo si el producto no existe |
| `api.crear_fichero(p_id_producto, p_nombre, p_descripcion_corta?, p_prototipo_url?, key?)` | Crea el fichero **y auto-genera su ticket en backlog** (vinculado por `fichero_ticket` N:N) |
| `api.crear_fichero_input(...)` / `api.eliminar_fichero_input(...)` | **Materia prima** del fichero (`tipo`: `url`\|`adjunto`\|`texto`): URLs, notas, adjuntos de los que se derivan fichas. Acá aterriza el contexto crudo del intake |
| `api.criar_ficha(p_id_producto, p_tipo, p_titulo, p_id_fichero?, p_contenido?, key?)` | Ficha nueva en `IDEA` |
| `api.crear_ticket(p_titulo, p_descripcion?, p_id_producto?, p_area?, p_estado?, p_prioridad?, p_id_owner?, p_fase?, ...)` | Ticket suelto (WCH-NNN) cuando el trabajo no amerita fichero |

### Ideación / Definición (contenido que madura)
| RPC | Para qué |
|---|---|
| `api.guardar_ficha(p_id_producto, p_tipo, p_titulo, p_contenido, key, p_id_ficha?, p_nota?, —, p_id_fichero?)` | Re-versiona el CONTENIDO (snapshot inmutable, `p_nota` = changelog de la versión). NO cambia estado |
| `api.transition_ficha(p_id_ficha, p_nuevo_estado, key)` | `IDEA→BORRADOR` al arrancar a trabajarla; `BORRADOR→PARA_VALIDAR` cuando el contrato está completo |
| `api.vincular_ficha_fichero` / `api.desvincular_ficha_fichero` | Membresía SECUNDARIA ficha↔fichero (N:M, WCH-110 resuelto). El principal vive en `ficha.id_fichero` y se cambia con `api.reasignar_fichas_fichero` |

### Validación con usuario (sesiones sobre el fichero)
| RPC | Para qué |
|---|---|
| `api.crear_sesion_validacion(p_id_fichero, p_fecha_sesion, p_participantes[], p_prototipo_url?, p_notas?, key?)` | Abre la sesión (estado `abierta`) |
| `api.agregar_hallazgo(p_id_artefacto, p_tipo, p_descripcion, p_id_ficha?, p_orden?, key?)` | Hallazgo tipado: `ux` \| `funcional` \| `tecnico` \| `bloqueante` |
| `api.agregar_decision(p_id_artefacto, p_descripcion, p_accion, p_id_ficha?, p_id_ticket?, p_orden?, key?)` | Decisión: `aceptar` \| `rechazar` \| `iterar` \| `derivar` (derivar puede linkear un ticket/ADR) |
| `api.cerrar_sesion_validacion(p_id_artefacto, key?)` | Cierra (no admite más hallazgos/decisiones) |

Después de cerrar, **procesá las decisiones a mano** (no hay auto-cierre del loop): `aceptar` → `transition_ficha(→VALIDADA)` · `iterar` → `transition_ficha(→BORRADOR)` · `derivar` → crear ticket ADR + `vincular_adr_ficha`.

### Validación interna (gates ADR + DoR → `READY_TO_BUILD`)
| RPC | Para qué |
|---|---|
| `api.vincular_adr_ficha(p_id_ficha, p_id_ticket_adr, p_nota_bloqueo, key)` | Registra un ADR bloqueante. Si la ficha está `VALIDADA`, la **auto-transiciona a `ADR_GATED`**. Solo desde `VALIDADA`/`ADR_GATED` (`ESTADO_INCOMPATIBLE`) |
| `api.resolver_adr_ficha(p_id_ficha, p_id_ticket_adr, p_nota_resolucion, key)` | Marca resuelto. **NO transiciona sola**: cuando no queden pendientes, llamá `transition_ficha(→VALIDADA)`. Warning `ADR_PENDIENTES_RESTANTES` si quedan otros |
| `api.actualizar_dor_ficha(p_id_ficha, p_dor_checklist, key)` | PUT del DoR completo: `[{id, label, done}, ...]` |
| `api.transition_ficha(p_id_ficha, 'READY_TO_BUILD', key)` | El gate final — falla con `DOB_VACIO`/`DOB_INCOMPLETO`/`ADR_PENDIENTE` |

### Handoff a build (releases del fichero)
| RPC | Para qué |
|---|---|
| `api.crear_release(p_id_fichero, p_nombre, p_descripcion?, key?)` | Release en `borrador` (falla si fichero archivado) |
| `api.agregar_ficha_a_release(p_id_release, p_id_ficha, p_notas?, p_orden?, key?)` | Solo con release en `borrador`; valida mismo producto |
| `api.avanzar_release(p_id_release, key?)` | Ciclo lineal `borrador→lista→validada→en_produccion` (terminal) |
| `api.deprecar_release(p_id_release, key?)` | Desde cualquier estado activo; deprecado = solo lectura |
| `api.transition_ficha(p_id_ficha, 'EN_BUILD', key)` | La ficha entra a construcción → la toma **`wachi-fabrica`**. Al shippear: `transition_ficha(→SHIPPED)` |

### Tickets (el tablero de Camilo)
`api.crear_ticket` · `api.mover_ticket(p_id_ticket, p_estado)` · `api.actualizar_ticket(...)`. El vínculo ticket↔ficha existe (`ticket_ficha_link`, migración 20260701001000) y el fichero acumula sus tickets vía `fichero_ticket`.

## Frontera de datos (dónde va lo que NO es hecho de fábrica)

Hecho gobernado (ticket/ficha/sesión/release) → **RumIAndo** (esta capa). Conocimiento durable + porqué (decisiones de arquitectura, doctrina, minutas) → **Wachi Brain** (`.md` git-first en el hub). Gotcha de código del repo actual → **Engram** (`mem_save`, con `ticket: WCH-NNN` en el frontmatter). Detalle: `_shared/frontera-datos.md`.
