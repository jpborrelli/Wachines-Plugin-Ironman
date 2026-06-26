# Taxonomía de issues + checklist de exploración

## Severidades

| Severidad | Definición | Ejemplos |
|---|---|---|
| **critical** | Bloquea un flujo core, causa pérdida de datos, o crashea la app | Submit del form tira página de error; el flujo de carga de datos roto; se borra algo sin confirmación |
| **high** | Feature mayor roto o inusable, sin workaround | Búsqueda devuelve resultados equivocados; upload falla en silencio; loop de redirect en auth |
| **medium** | Funciona pero con problemas notorios, hay workaround | Página lenta (>5s); falta validación pero el submit igual funciona; layout roto solo en mobile |
| **low** | Cosmético / polish | Typo en el footer; desalineación de 1px; hover inconsistente |

> **La vara (IRON LAW):** clasificá pensando en "producto profesional usado por cientos". Un form que traga input inválido sin avisar NO es "low" porque "se entiende" — es un agujero de calidad. Un empty state feo en una pantalla core es un problema real.

## Categorías

### 1. Visual / UI
Layout roto (solapamiento, texto cortado, scroll horizontal indebido), imágenes rotas/faltantes, z-index mal (cosas atrás de otras), inconsistencia de fuente/color, glitches de animación, desalineación, problemas de dark mode/tema.

### 2. Funcional
Links rotos (404, destino equivocado), botones muertos (click no hace nada), validación de form (falta, mal, bypasseable), redirects incorrectos, estado que no persiste (datos perdidos al refrescar / con back), race conditions (doble submit, datos stale), búsqueda que devuelve mal o nada.

### 3. UX
Navegación confusa (sin breadcrumbs, dead ends), falta de indicador de loading (el usuario no sabe que algo pasa), interacciones lentas (>500ms sin feedback), mensajes de error poco claros ("Algo salió mal" sin detalle), sin confirmación antes de acciones destructivas, patrones de interacción inconsistentes entre páginas.

### 4. Contenido
Typos y errores de gramática, texto desactualizado/incorrecto, placeholder / lorem ipsum olvidado, texto truncado sin ellipsis ni "más", labels equivocados en botones o campos, empty states faltantes o inútiles.

### 5. Performance
Cargas lentas (>3s), scroll con jank (frames perdidos), layout shifts (contenido que salta al cargar), exceso de requests (>50 en una página), imágenes pesadas sin optimizar, JS bloqueante (página no responde durante la carga).

### 6. Consola / Errores
Excepciones JS (errores no atrapados), requests fallidos (4xx/5xx), warnings de deprecación, errores CORS, mixed content (recursos HTTP en HTTPS), violaciones de CSP. **Capturá con `agent-browser console` + `agent-browser errors` tras cada interacción.** Los **requests fallidos** salen en `console` como `Failed to load resource: ... status N` — `agent-browser network requests` NO da el status (solo lista URLs); para un endpoint puntual usá `agent-browser eval "await fetch('<url>').then(r=>r.status)"`.

### 7. Accesibilidad
Imágenes sin alt, inputs sin label, navegación por teclado rota (no se puede tabular), focus traps (no se puede salir de un modal/dropdown), ARIA faltante o incorrecto, contraste insuficiente, contenido inalcanzable por lector de pantalla.

## Checklist de exploración por página

Para CADA página visitada (la vara: tocá todo, como usuario real exigente):

1. **Scan visual** — `agent-browser screenshot <path> --full` + Read. Layout, imágenes, alineación, contraste.
2. **Elementos interactivos** — clickeá TODOS los botones/links/controles (`click @eN` o `find role button click --name X`). ¿Cada uno hace lo que dice? Consola después.
3. **Forms** — llená y enviá. Probá: **vacío**, **inválido** (email mal, número en campo de texto), **edge** (texto larguísimo / overflow, unicode `áéíóú 🐄`, caracteres peligrosos `<script>`, `'`, `"`, `;--`). ¿Hay validación? ¿Mensaje claro? ¿Se bypassea el submit? **OJO:** un botón `is enabled = true` NO implica que falte validación — muchos forms validan **on-submit**. Confirmá clickeando y mirando qué pasa, no solo con `is enabled`.
4. **Navegación** — todos los caminos in/out: breadcrumbs, back/forward del browser, deep links, menú mobile. ¿Dead ends?
5. **Estados** — empty (sin datos), loading (¿indicador?), error (¿se maneja?), overflow (muchos datos / texto largo).
6. **Consola** — `agent-browser console` + `errors` tras las interacciones. ¿Errores JS o requests fallidos nuevos? (Los 4xx/5xx salen en `console`; `network requests` NO da status — ver categoría 6.)
7. **Responsive** — mobile (375x812), tablet (768x1024), desktop. ¿Se rompe algo?
8. **Límites de auth** — ¿qué pasa deslogueado? ¿con distintos roles?
9. **Modales / diálogos** — al abrir uno, **re-snapshoteá** (`snapshot -i`): el árbol se reduce al modal y los refs arrancan de nuevo desde `@e1`. Verificá el cierre por las 3 vías: **Esc**, **click afuera** y botón **Cancelar/X**. Verificá el **focus trap**: `Tab` repetido no debe escaparse del modal.
10. **Toasts / notificaciones efímeras** — aparecen ~2-4s y se van. Capturá con `screenshot` INMEDIATO tras la acción, o leé el texto con `agent-browser eval "document.querySelector('[role=status],[role=alert]')?.textContent"`. **Si una acción no da ningún feedback visible → hallazgo de UX.**
11. **Drag & drop** — `agent-browser drag` reporta `✓` pero **NO mueve cards de dnd-kit / react-beautiful-dnd** (falso positivo). (a) Verificá la **a11y del handle** en `snapshot -i` — si la card solo expone "Abrir" y no hay handle ni movimiento por teclado → hallazgo de a11y. (b) Asumí que `drag` puede no andar; si necesitás ejercerlo, secuencia de pointer events por `eval` (`pointerdown`→`pointermove`×N→`pointerup` con coords de `get box`). (c) Si nada anda, documentá "DnD no verificable por la tool" como **PUNTO CIEGO** — no lo ignores ni afirmes que anda/está roto.
