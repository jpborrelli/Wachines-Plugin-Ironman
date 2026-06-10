# Casos de uso de HTML — inspiración, no templates

Adaptación del artículo de Thariq ([The Unreasonable Effectiveness of HTML](https://x.com/trq212)) al contexto tu proyecto. Cada caso muestra **un tipo de problema** y **un formato que podría servir** — no el único formato. La idea es expandir el menú mental de qué se puede hacer con HTML, no fijar estructuras.

> Importante: **cada artefacto se diseña libremente**. Estos ejemplos son para calibrar el rango de posibilidades, no para clonar.

---

## 1. Specs, planning y exploración

Una buena spec en HTML no es un markdown más bonito — es un **canvas con secciones, mockups, data flow y snippets** que el lector puede saltar por anchors. Para problemas complejos, Claude suele armar 2-3 HTMLs encadenados (uno para brainstorming, otro para mockups, otro para implementation plan).

**Cuándo HTML pega especialmente bien**:
- Specs >100 líneas que un humano va a tener que aprobar.
- Cuando hace falta mostrar mockups o data flow.
- Exploración multi-opción que terminará en una decisión.

**Prompts ejemplo**:

> "No tengo claro cómo va a quedar el screen de distribución de pago. Generame 6 versiones distintas — variá layout, densidad y tono — en una grilla HTML para compararlas lado a lado. Cada una con el tradeoff que está haciendo."

> "Armame un plan de implementación HTML para el refactor de `aplicacion_pago`. Incluí mockups del modal, un diagrama del data flow del nuevo endpoint, los snippets críticos de SQL que voy a tener que revisar, y una tabla de hitos con owners y deadlines."

> "Estoy pensando 3 formas de resolver el matching de cheques con factura. Quiero ver las 3 en HTML, cada una con su lógica simplificada en pseudo-código y los casos donde rompería. La que recomendás destacada."

**Formato típico (no fijo)**: hero + secciones con anchors + mockups embebidos (HTML real o SVG) + tabla de hitos al final. Pero podría ser un grid de 6 cards si es brainstorming.

---

## 2. Code review y understanding

El diff de GitHub es funcional pero **plano**. Para PRs grandes (refactor de 8 archivos, migración con SQL + frontend + tests), un HTML con diff + anotaciones laterales coloreadas por severidad es mucho más legible para el reviewer.

**Cuándo HTML pega especialmente bien**:
- PR que toca >5 archivos relacionados.
- Refactor donde la lógica nueva no es obvia leyendo solo el diff.
- Cuando vas a compartir el cambio con alguien que no es el dueño del módulo (ej. explicarle a un colega un cambio que hizo otra persona).

**Prompts ejemplo**:

> "Ayudame a revisar este PR. No estoy familiarizado con la lógica de triggers de cuotas, así que enfocate ahí. Renderizá el diff real con anotaciones inline al margen, color-coded por severidad (bloqueante, nit, nice catch)."

> "Explicale a un compañero no-técnico qué cambia este PR del módulo. HTML, lo voy a pasar por Discord. Incluí los 3 snippets clave y un párrafo de cada uno explicando qué cambia desde su perspectiva (no la mía)."

**Formato típico (no fijo)**: grid 2-col (diff a la izquierda 2/3, anotaciones a la derecha 1/3). O puede ser narrative: párrafo + snippet + párrafo + snippet, si el cambio es más conceptual que línea-por-línea.

---

## 3. Design & prototipos

Un mockup en HTML es **interactivo** — botones funcionan, animaciones corren, sliders cambian valores. Cuando todavía no sabés exactamente qué animation/spacing/color querés, un prototipo con sliders te deja iterar visualmente antes de pasarlo al componente React real.

**Cuándo HTML pega especialmente bien**:
- Estás tuneando una animación o microinteraction y querés ver el resultado en tiempo real.
- Necesitás explorar variantes de un componente antes de implementarlo en React.
- Vas a iterar con alguien no-técnico (alguien no-técnico) — que toquen los sliders directo.

**Prompts ejemplo**:

> "Quiero prototipar el modal nuevo de distribuir pago. Armame un HTML con sliders para ancho/alto/padding/border-radius, un toggle para mostrar/ocultar el resumen lateral, y un botón 'copy as Tailwind' que copie los valores al clipboard. Que se vea con la paleta tu proyecto."

> "Estoy decidiendo cómo se debería sentir el hover sobre las tarjetas de establecimiento. Generá un HTML con varias opciones (scale, shadow lift, border glow, none) y un toggle entre ellas para probar."

**Formato típico (no fijo)**: split-screen con preview izquierda + controls derecha. O carrusel de variantes con switcher. Casi siempre lleva un botón "copy" al final.

---

## 4. Reports, retro y learning

Los reports semanales en MD nadie los lee. En HTML, con stats grandes destacados arriba y secciones colapsibles, el equipo los abre y los lee.

**Cuándo HTML pega especialmente bien**:
- Status report para stakeholders (dev a PM, equipo a comité).
- Retros donde hay datos cuantitativos (commits, PRs, tickets resueltos) + cualitativos.
- Explainers de funcionalidad compleja para onboardear a alguien nuevo.

**Prompts ejemplo**:

> "Resumen ejecutivo de lo que shippeamos esta semana. Punchline arriba con la métrica más importante. Después por bloques: facturación, indicadores, gestión interna. HTML, comparte-able."

> "No entiendo cómo funciona realmente el trigger de pricing en presupuestos. Leé el código relevante y armame un explainer HTML: diagrama del flujo, los 3-4 snippets clave anotados, y al final una sección de 'gotchas' con los bugs históricos. Optimizado para alguien que lo lee una sola vez."

> "Retro mensual de Mayo: actividad por persona, decisiones importantes, lo que ralentizó. Tabla resumen arriba, detalle abajo."

**Formato típico (no fijo)**: punchline + 3-4 stats arriba + bloques temáticos con highlight de "lo más importante". Reports recurrentes pueden mantener el mismo formato — pero solo si vos lo decidís.

---

## 5. Mapas conceptuales / arquitecturas

Diagramas de arquitectura, mapas mentales, relaciones entre tablas, flujos de datos. SVG inline maneja esto perfecto y queda crisp.

**Cuándo HTML pega especialmente bien**:
- Hay que mostrar relaciones espaciales (FKs entre tablas, módulos del sistema, jerarquías).
- Onboarding de alguien nuevo al stack.
- Documentar una decisión arquitectural compleja.

**Prompts ejemplo**:

> "Mapa conceptual de cómo se conectan las tablas del módulo facturación: solicitud_factura, cuota_presupuesto, recibo, aplicacion_pago. SVG inline. Mostrar FKs y triggers críticos."

> "Diagrama del flujo de datos desde que un técnico carga un pastoreo hasta que sale el indicador productivo. Boxes por sistema (campo / web / postgres / cron), flechas con anotaciones."

> "Arquitectura del sistema Kapso: workflows + functions + WhatsApp Flows + DB. Layers stack con cuál habla con cuál."

**Formato típico (no fijo)**: un SVG dominante en el viewport con leyenda al lado, o un layout layers-stack vertical si hay capas claras. Casi siempre lleva un párrafo explicativo arriba.

---

## 6. Wireframes y mockups

Distinto a prototipos interactivos — un wireframe es más estático, pensado para discutir layout antes de codear. HTML wireframe se siente más real que un Figma porque tiene texto real y se ve en el browser.

**Cuándo HTML pega especialmente bien**:
- Estás definiendo el layout de un screen nuevo antes de implementar.
- Vas a revisarlo con alguien que no usa Figma (cualquiera del equipo no-técnico).
- Necesitás varios screens encadenados (flujo de onboarding, wizard).

**Prompts ejemplo**:

> "Wireframe HTML del nuevo screen de carga de gastos vía WhatsApp con confirmación. 3 pantallas mostradas como mocks de phone-frame en una fila. Cada una con su título y nota de qué pasa en ese paso."

> "Mockup del dashboard del técnico: arriba KPIs (3-4 stats), izquierda lista de establecimientos, derecha mapa. Sin estilizar demasiado — quiero ver el layout, no el final visual."

---

## 7. Editores ad-hoc (one-shot UIs)

Cuando tenés que reordenar/curar/etiquetar data y el chat es muy lento para describir cada movimiento. Un HTML one-shot con drag & drop + botón "copy as JSON" al final que devuelve el resultado al chat.

**Cuándo HTML pega especialmente bien**:
- Reordenar / priorizar / categorizar muchos items.
- Editar config estructurada con dependencias entre campos.
- Curar un dataset (aprobar/rechazar filas, taggear ejemplos).
- Anotar un documento o transcript.
- Elegir valores difíciles de describir en texto (color, easing curve, crop region, cron schedule, regex).

**Prompts ejemplo**:

> "Tengo 30 tareas en estado 'pendiente'. Armame un HTML con cada una como card draggable a 4 columnas: Now / Next / Later / Cut. Pre-ordená por tu mejor guess. Botón 'copy as markdown' que exporte el resultado con una línea de rationale por bucket."

> "Quiero curar esta lista de minutas pendientes de envío. HTML con checkboxes (enviar / pasar / borrar) + textarea para nota inline. Al final un botón que exporte el JSON de decisiones."

> "Editor para ajustar el system prompt del agente de WhatsApp. Side-by-side: prompt editable a la izquierda con variables resaltadas, 3 sample inputs a la derecha que se rerenderean live. Token counter + copy button."

**Formato típico (no fijo)**: layout funcional según la tarea + siempre un botón export al final que devuelve algo pasteable al chat (JSON, markdown, diff). Sin botón export es solo lectura — perdés la mitad del beneficio.

---

## Cuando dudes del formato

Hacele al usuario una pregunta corta antes de empezar — o asumí lo razonable y armá una versión:

- *"¿Lo vas a leer solo vos o lo vas a compartir al equipo? (cambia el tono y el detalle)"*
- *"¿Querés un doc fijo o un editor con sliders/inputs para tunear vos algo?"*
- *"¿Hace falta que sea exportable (JSON/markdown) o solo lectura?"*

Si no querés interrumpir, asumí: doc fijo, comparte-able, sin export. Esa es la opción que sirve en el 70% de los casos.
