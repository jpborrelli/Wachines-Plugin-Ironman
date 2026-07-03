# Aterrizaje en RumIAndo — cómo el proceso de producto usa el conector

> **El contrato lo da el MCP, no este archivo.** Las tools del `conector-rumiando`, sus
> params y errores viven en **dos fuentes de verdad vivas**: `mis_capacidades` (discovery del
> propio MCP, filtrado a tu usuario) + `describir_tabla`, y la **doc oficial** en el repo
> RumIAndo (`docs/conector-rumiando-equipo.md` = conexión y uso · `docs/conector-rumiando.md`
> = técnica). **Este archivo NO duplica firmas** — mapea el *proceso* de producto a las
> herramientas. Si un param no está acá, es a propósito: pedíselo a `mis_capacidades`.

## Conectarse (una vez por máquina)

```bash
claude mcp add conector-rumiando https://rumiando.perennia.com.ar/mcp --transport http
```

Después `/mcp` → `conector-rumiando` → **Authenticate** (login de RumIAndo). Opera con **tu
identidad**: cada acción queda a tu nombre en el feed. **Primer paso siempre:** `mis_capacidades`
(te lista las tools y qué podés hacer).

## Cómo funciona (esto sí es del proceso, no del contrato)

- **Escritura solo por el conector** — nunca SQL directo ni tocar la DB "por abajo" (la RLS lo
  prohíbe). El estado de una ficha **solo** cambia por `transition_ficha` (`guardar_ficha` NO
  cambia estado).
- **Idempotencia y envelope los maneja el server** — vos **no** pasás idempotency-key (la inyecta
  el conector); las mutaciones devuelven `{data, effects, warnings}`. **Reportá los `effects`
  reales, no "listo".**
- **Lectura libre por RLS** — `consultar_datos` / `contar_filas` / `obtener_ficha` / `listar_tablas`
  / `describir_tabla`: ves lo que tu usuario puede ver.
- **Las destructivas confirman** — las tools `risk: high` (eliminar_*, `deprecar_release`,
  `reasignar_fichas_fichero`, `transition_ficha`) piden confirmación antes.

## La máquina de estados de la ficha (conocimiento de producto)

Tipos: `funcional` | `tecnica` | `sofa-asset`. Nace en `IDEA`.

```
IDEA → BORRADOR → PARA_VALIDAR → VALIDADA → READY_TO_BUILD → EN_BUILD → SHIPPED (terminal)
   retrocesos sanos: BORRADOR→IDEA · PARA_VALIDAR→BORRADOR · READY_TO_BUILD→VALIDADA · EN_BUILD→READY_TO_BUILD
VALIDADA ⇄ ADR_GATED  (vincular_adr_ficha auto-gatea; vuelve a VALIDADA cuando todos resueltos)
```

Gates que hace cumplir `transition_ficha` (si falla, **el error ES el reporte**):
- → `READY_TO_BUILD`: DoR completo (todos los ítems `ok`).
- `ADR_GATED` → `VALIDADA`: todos los ADRs resueltos.
- Salto ilegal: `TRANSICION_INVALIDA`.

## Qué tool en cada etapa (el mapa proceso → herramienta)

Verbos, no firmas — los params exactos salen de `mis_capacidades`.

- **Orientarse (siempre primero):** `resumen_producto` · `buscar_fichas` · `obtener_ficha` · `actividad_filtrada`.
- **Intake (idea cruda):** `crear_fichero` (auto-crea su ticket) · `crear_fichero_input` (materia prima: url/texto/adjunto) · `criar_ficha` (nace `IDEA`) · `crear_ticket` (trabajo suelto).
- **Ideación / definición:** `guardar_ficha` (versiona el contenido, no el estado) · `transition_ficha` (`IDEA→BORRADOR→PARA_VALIDAR`) · `vincular_ficha_fichero` (una ficha puede vivir en varios ficheros).
- **Validación con usuario:** `crear_sesion_validacion` → `agregar_hallazgo` (`ux|funcional|tecnico|bloqueante`) · `agregar_decision` (`aceptar|rechazar|iterar|derivar`) → `cerrar_sesion_validacion`. Cerrada la sesión, **procesá las decisiones a mano**: `aceptar`→`transition_ficha(→VALIDADA)` · `iterar`→`transition_ficha(→BORRADOR)` · `derivar`→`crear_ticket` (ADR) + `vincular_adr_ficha`.
- **Validación interna (gates → `READY_TO_BUILD`):** `vincular_adr_ficha` / `resolver_adr_ficha` · `actualizar_dor_ficha` · `transition_ficha(→READY_TO_BUILD)`.
- **Handoff a build:** `crear_release` · `agregar_ficha_a_release` · `avanzar_release` · `transition_ficha(→EN_BUILD)` (la toma **`wachi-fabrica`**) → al shippear `transition_ficha(→SHIPPED)`.
- **Tablero (Camilo):** `crear_ticket` · `mover_ticket` · `actualizar_ticket`.

> ⚠️ **Naming:** la tool de crear ficha se llama **`criar_ficha`** (typo heredado del RPC
> `api.criar_ficha`). Es el nombre real hoy — usalo tal cual hasta que JB decida el rename en cascada.

## Frontera de datos

Hecho gobernado (ticket/ficha/sesión/release) → **RumIAndo** (por el conector). Conocimiento durable
+ porqué → **Wachi Brain** (`.md` git-first). Gotcha de código del repo actual → **Engram**
(`mem_save` con `ticket: WCH-NNN`). Detalle: `_shared/frontera-datos.md`.
