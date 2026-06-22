---
name: html-perennia
description: >-
  Recordatorio + paleta para que Claude prefiera HTML sobre markdown cuando arma artefactos
  para que un humano lea, valide o interactúe — planning, validación, comparaciones, wireframes,
  mapas conceptuales, code review, decisiones, reports, editores ad-hoc. La skill NO impone un
  formato ni un catálogo de componentes; cada caso se diseña libremente. Solo asegura que (a)
  Claude considere HTML como default cuando el doc se va a leer o interactuar y (b) los
  colores/tipografías sean los de Perennia para que el artefacto se sienta parte del repo, no
  genérico. Activar cuando el usuario pida "plan", "spec", "doc", "review", "comparación",
  "wireframe", "mapa conceptual", "mockup", "reporte", "editor para X", "armame un HTML", o
  cuando Claude esté por escribir un markdown de más de 100 líneas que un humano va a tener que
  leer, validar o compartir.
license: MIT
metadata:
  author: perennia-regen
  version: "1.2.0"
---

# html-perennia — Pensá en HTML, con la paleta de Perennia

Esta skill es **una señal, no un generador**. No tiene boilerplates, no tiene catálogo de componentes obligatorios, no tiene templates rígidos. Cada artefacto se diseña libremente según el caso.

Asegura tres cosas: (1) que Claude considere HTML como default cuando el artefacto se va a leer/validar/compartir, en lugar de defaultear a markdown plano; (2) que el resultado tenga la identidad visual de Perennia (paleta tierra-verde, DM Sans + Inter + JetBrains Mono); y (3) un **piso de legibilidad** — que no se vaya a denso-apretado-arcoíris. Lo que NO impone es el formato: qué componentes, qué layout, qué estructura, lo decidís libremente en cada caso.

Inspirada en [The Unreasonable Effectiveness of HTML](https://x.com/trq212) de Thariq Shihipar.

---

## Cuándo preferir HTML sobre markdown

Markdown es perfecto para texto plano corto (commit messages, comments en un PR, READMEs cortos). Pero hay tareas donde HTML produce un mejor artefacto:

| Tarea | Por qué HTML gana |
|---|---|
| **Planning / specs de >100 líneas** | El humano va a abandonar un MD largo. Un HTML con TOC, secciones bien jerarquizadas y diagramas se lee. |
| **Validar wireframes / mockups** | HTML PUEDE mostrar el mockup, MD solo lo describe. |
| **Mapas conceptuales / arquitecturas** | SVG inline > diagrama ASCII. Boxes, arrows, layered cards. |
| **Decisión técnica (A vs B vs C)** | Tres cards lado a lado con pros/cons + recommended outlined. Imposible en MD. |
| **Code review en branches grandes** | Diff con anotaciones laterales coloreadas por severidad. Mucho mejor que comentar línea por línea en GH. |
| **Status / reports semanales** | Stats grandes, tabla zebra, punchline con número destacado. Lo lee el equipo en 1 minuto. |
| **Editores ad-hoc (one-shot UIs)** | Sliders, drag-and-drop, checkboxes que exportan JSON para copy-paste de vuelta al chat. |
| **Exploración de N opciones de diseño** | 6 mockups en un grid. Imposible en MD. |
| **Explainers de algo que cuesta entender** | Diagramas + snippets anotados + "gotchas" al final. Hipotécnico. |

Si la respuesta es "esto lo va a leer alguien y quiero que la lea bien", inclinarse a HTML.

---

## Cuándo NO usar HTML

- Mensajes cortos en el chat (<50 líneas).
- READMEs del repo (.md sigue siendo lo correcto).
- Comentarios en un PR o issue.
- Commits, changelogs, post-mortems escritos para humanos que prefieren MD.
- Cualquier cosa que vaya a editarse desde la terminal después.
- Si el usuario pide explícitamente markdown.

---

## Cuándo usar `web-artifacts-builder` en lugar de esta skill

Esta skill produce **HTML/CSS vanilla** para abrir con `open` o deployar a `public/` (Vercel). Si en cambio necesitás un artefacto con **estado complejo, routing, o componentes shadcn/ui**, y el destino es el **panel de artifacts de claude.ai** (no un archivo deployable), esa es otra herramienta: la skill `web-artifacts-builder` (React + TS + Tailwind + shadcn, bundleado a un único HTML).

Son targets distintos, no los mezcles: **no metas React/Tailwind/shadcn en los HTML de esta skill** — rompe el deploy estático y la filosofía "sin libraries". Y al revés, si vas a usar `web-artifacts-builder`, traé de acá solo la **paleta y las tipografías de Perennia** (los tokens de más abajo) para que el artefacto no se sienta genérico.

---

## Casos de uso típicos (con prompts)

Más detalle en [`references/inspiracion.md`](./references/inspiracion.md). Highlights:

- **Specs / Planning**: "Hacé el plan en HTML, con mockups y data flow. Que se pueda leer bien en el celular."
- **Exploración**: "Mostrame 6 formas distintas de armar este screen, una grilla en HTML, cada una con su tradeoff."
- **Code review**: "Explicale al equipo qué cambia este PR. HTML con diff anotado, lo voy a pasar por Discord."
- **Decisión técnica**: "Comparame A, B y C para resolver Y. Recomendación destacada."
- **Reports**: "Resumen de lo shippeado esta semana. HTML, comparte-able."
- **Wireframes / prototipos**: "Mockup del nuevo modal de distribuir pago, con sliders para ajustar tamaños."
- **Mapas conceptuales**: "Mapa de cómo se conectan las tablas del módulo facturación, SVG inline."
- **Editores ad-hoc**: "Editor en HTML para reordenar estas 30 tareas en columnas Now/Next/Later, con botón copy as markdown."

El formato concreto de cada uno **lo decidís vos**. No hay un template "para planning" ni un template "para wireframes" — diseñá lo que tenga más sentido para ese caso.

---

## Restricción 1 — identidad Perennia

El formato es libre. Pero los colores y tipografías deben ser los de Perennia, sino el artefacto se siente de otro repo. Esta es la "marca de agua" visual.

### Tokens de color (CSS variables)

```css
:root {
  /* Brand — las 5 que importan */
  --brown:  #3D2920;   /* texto principal, hero bg, table header */
  --warm:   #99673B;   /* acento tierra — subtítulos, antes-state */
  --olive:  #6F8F07;   /* PRIMARY — links, labels, borders, CTAs */
  --lime:   #93B524;   /* accent secundario — números destacados sobre brown */
  --bg:     #F5F7F0;   /* warm off-white — fondo body default */

  /* Grays warm (no neutros — pequeño tinte sepia) */
  --white:    #ffffff;
  --gray-50:  #fafaf8;
  --gray-100: #f0f0ec;
  --gray-200: #e2e2dc;
  --gray-500: #888880;
  --gray-600: #666660;
  --gray-700: #4a4a45;

  /* Semantic — usar solo si hace falta diferenciar funcionalmente */
  --blue-soft:  #4a8ec2;
  --amber-soft: #c6850c;
  --red-soft:   #c25555;
  --green-soft: #5fa869;
}
```

Reglas mínimas: **olive** es el color de cualquier acción (link, CTA, label activo). **Brown** es el texto y los fondos dark (hero, headers de tabla). **Warm** es el acento "tierra". **Lime** es para números destacados sobre fondo brown.

### Tipografía

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

- **Headings (h1-h4)**: `'DM Sans', system-ui, sans-serif`
- **Body**: `'Inter', system-ui, sans-serif`
- **Labels, tags, mono, kbd, code**: `'JetBrains Mono', monospace`

### Base reset (copy-paste al `<head>`)

```html
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html { scroll-behavior: smooth; }
  body {
    background: var(--bg);
    color: var(--brown);
    font-family: 'Inter', system-ui, sans-serif;
    -webkit-font-smoothing: antialiased;
    font-size: 16px;
    line-height: 1.6;
  }
  h1, h2, h3, h4 { font-family: 'DM Sans', system-ui, sans-serif; line-height: 1.15; }
  a { color: var(--olive); text-decoration: none; }
  code { font-family: 'JetBrains Mono', monospace; background: var(--gray-100); padding: 1px 6px; border-radius: 4px; }
  @media (max-width: 900px) {
    /* Cualquier grid de columnas múltiples → 1fr en mobile */
  }
</style>
```

### Evitar el look "AI slop"

El formato es libre, pero hay tics visuales que delatan un HTML "generado por IA" y le sacan la identidad de Perennia. Evitarlos:

- **Todo centrado en una columna estrecha.** Preferí alineación a la izquierda y grids que usan el ancho de la pantalla.
- **Gradientes morados / azul-violeta.** El acento de Perennia es tierra-verde (`--olive` / `--lime`), nunca el gradiente morado genérico de los starters.
- **Rounded corners gigantes y uniformes.** `border-radius` exagerado en todo. Usá radios chicos y consistentes (4–8px), o bordes rectos cuando aporta.
- **Sombras flotantes en cada elemento.** El default es borde `1px solid var(--gray-200)`; reservá `box-shadow` para donde hay elevación real (un modal, un dropdown).
- **Una sola tipografía para todo.** El look genérico usa la misma fuente en títulos, body y labels. En Perennia, Inter como body es **deliberado** (es marca), pero va mezclado: DM Sans en headings, Inter en body, JetBrains Mono en labels/code. Esa mezcla es parte de la identidad — no caigas en "Inter en todo".
- **Borde izquierdo de color como sistema de categorías.** Un `border-left:4px solid` ocasional para un callout está bien. Pero usarlo en CADA card con un color distinto por categoría (azul=técnico, oliva=producto, violeta=PM…) convierte el doc en un semáforo. Es el anti-patrón #8 del blacklist de AI-slop. Si tenés >3 categorías, distinguilas con un **label de texto**, no con 6 hues de borde.
- **La grilla de 3 (o N) cards simétricas:** ícono-en-círculo-de-color + título bold + 2 líneas, repetido idéntico. El layout más reconocible de "lo hizo una IA". Si las cards no tienen pesos distintos (una manda, las otras acompañan), la grilla es decorativa.
- **Emojis como iconos decorativos.** Ya está en anti-patrones: sin emojis salvo que el usuario los pida — y eso incluye un emoji por tab y por heading.

### Inspiración visual

Para calibrar el look, mirá HTMLs ya hechos de tu repo (decks, specs, reports) y fijate cómo
combinan la paleta, la jerarquía tipográfica y los SVG inline. NO copiar la estructura literal
de ninguno — son ejemplos para **calibrar el look**, no templates.

---

## Restricción 2 — piso de legibilidad

La identidad (restricción 1) hace que el doc se sienta de Perennia. Esto hace que se **lea**. Es la restricción que faltaba: sin ella, cada HTML reinventa tipografía, espaciado y color, y termina denso-apretado-arcoíris. La regla general: **denso ≠ apretado**. Denso es sin relleno (sin lorem, sin flavor text); apretado es sin aire ni jerarquía. Querés lo primero, no lo segundo.

Los tokens de abajo son el **default recomendado** (copiá y usá). No son obligatorios, pero si necesitás un tamaño o un espaciado, salí de esta escala antes de inventar un valor suelto.

### Escala tipográfica — 6 pasos, nada en el medio

El olor más común: 10–12 tamaños de fuente casi iguales (15 / 14 / 13.5 / 13 / 12.5 / 11.5…). El ojo no encuentra jerarquía entre escalones de medio px. Usá **estos 6 y solo estos**:

```css
:root {
  --t-label: 12px;   /* labels, tags, mono, captions, celdas densas — MÍNIMO legible */
  --t-sm:    14px;   /* texto secundario, metadata, tablas */
  --t-body:  16px;   /* body — default de lectura */
  --t-h3:    20px;   /* subtítulos, títulos de card */
  --t-h2:    26px;   /* títulos de sección */
  --t-h1:    33px;   /* hero / título del doc */
  /* line-heights */
  --lh-body: 1.5;    --lh-head: 1.2;    --lh-table: 1.4;
}
```

Reglas duras:
- **Nada de contenido legible por debajo de 12px.** Un tag a 9.5px no se lee proyectado. Si no entra, sobra contenido, no falta px.
- **¿Necesitás más jerarquía que 6 pasos?** Usala con **peso** (400/500/600/700) o **color**, nunca con medio px. Peso y color son ejes gratis; los tamaños intermedios solo agregan ruido.
- **Body ≥16px**, line-height 1.5. Headings line-height 1.2. Tablas/datos densos line-height 1.4.
- **Números en columnas → `font-variant-numeric: tabular-nums`** (se alinean y comparan). **Headings → `text-wrap: balance`** (evita viudas). Fuente para datos: la mono (JetBrains).
- **Escala suave a propósito** (~1.25, no 1.6): en un doc denso un h1 gigante desperdicia pantalla. Si el doc es un poster (1 idea, hero grande), ahí sí podés subir el h1.

### Escala de espaciado — base 8, el aire no es desperdicio

```css
:root { --s1:4px; --s2:8px; --s3:12px; --s4:16px; --s5:24px; --s6:32px; --s7:48px; }
```

- **Padding de card ≥ `--s5` (24px).** 11–13px aprieta el contenido contra el borde.
- **Separación entre bloques/secciones ≥ `--s5` (24px).** Las cards pegadas se leen como una sola.
- **Gap de grids ≥ `--s4` (16px).** 
- **Ritmo:** lo relacionado va junto, lo distinto va separado. Más espacio ENTRE secciones que DENTRO de una. Si dos cosas están a la misma distancia, se leen como del mismo grupo.

### Disciplina de color — 1 acento, no 9

La paleta tiene 5 de marca (tierra-verde) + 5 semantic. El olor: usar los 5 semantic como un **sistema de 6 categorías** (cada vertical/bloque su hue de fondo y borde). Resultado: arcoíris, nada manda.

- **`--olive` es EL acento.** Links, CTAs, labels activos, el borde que importa. Uno solo.
- **Los semantic (blue/amber/red/green/violet) son para ESTADO puntual:** un badge "pendiente", un dot de error, una fila destacada. No para colorear secciones enteras, fondos de bloque, ni como paleta de categorías.
- **Máximo ~3 hues visibles por vista** además de los tierra-verde. Si tenés que distinguir 6 cosas, distinguilas con **texto/labels** o con una **intensidad** del mismo color (`rgba(111,143,7,.10/.25/.5)`), no con 6 colores distintos.
- **Contraste:** texto body ≥ 4.5:1 sobre su fondo (WCAG AA). El gris claro sobre off-white no llega — para texto que se lee, usá `--brown` o `--gray-700`.

### Jerarquía por contraste, no por acumulación

- **Máximo 1–2 negritas por párrafo.** Si todo está en bold, nada resalta.
- **Una sola cosa destacada por bloque.** No apiles bold + color + itálica en la misma palabra: elegí UN eje de énfasis.
- **Squint test:** entrecerrá los ojos (o achicá el zoom al 50%). Si no se distingue qué es título, qué es cuerpo y qué es lo importante, la jerarquía está plana. Arreglalo con tamaño/peso/espacio, no con más color.
- **Una idea por vista.** Si una pestaña/sección quiere decir 10 cosas, el lector no sabe dónde mirar. Partila o priorizá.

---

## Checklist — ¿huele a difícil de leer?

Antes de dar por terminado un HTML, pasá esta lista. Cada "sí" es una bandera (no necesariamente un error, pero revisalo):

- [ ] ¿Más de ~6 tamaños de fuente distintos? ¿Hay `13.5px`, `11.5px`, `9.5px` sueltos?
- [ ] ¿Algún texto que se lee por debajo de 12px?
- [ ] ¿Fondos o bordes tintados usados como sistema de categorías (>3 hues)?
- [ ] ¿Más de 1–2 negritas por párrafo? ¿bold + color + itálica juntos?
- [ ] ¿Padding de card o gaps por debajo de 16px? ¿Cards pegadas sin aire entre secciones?
- [ ] ¿Un emoji por tab / por heading?
- [ ] ¿Border-left de color en cada card? ¿Sombra difusa en cada elemento?
- [ ] ¿Grilla de N cards simétricas todas con el mismo peso?
- [ ] Squint test: ¿se distingue la jerarquía con el zoom al 50%?
- [ ] ¿La vista intenta decir más de una cosa?

Si tenés el browser a mano, **mirá el render** (no solo el código): `open <path>` o un screenshot. Los problemas de legibilidad se ven, no se leen.

---

## Output paths

| Caso | Path | Acceso |
|---|---|---|
| Draft local | `/tmp/html/[slug].html` | `open <path>` en macOS |
| Compartir al equipo | el directorio público de tu app (ej. `public/specs/[slug].html`) | servido por tu deploy de preview tras push |
| Presentación formal | el directorio público de tu app (ej. `public/presentaciones/[slug].html`) | servido por tu deploy |

Naming: kebab-case. Fecha si versiona. `plan-refactor-modulo-x-2026-05-13.html`.

Después de escribir el archivo, `open <path>` para abrirlo en el browser default.

---

## Principios de diseño (no reglas)

- **Información densa, no decorativa**. Sin lorem ipsum. Sin "flavor text".
- **Una sola idea por bloque**. Si una sección hace dos cosas, partirla.
- **Mobile responsive**. Grids con `@media (max-width: 900px)` → 1fr. Test achicando el browser.
- **Sin libraries externas**. HTML/CSS vanilla + Google Fonts. No Tailwind CDN, no React, no Alpine.
- **SVG inline para diagramas** (mapas conceptuales, flow charts, arquitecturas). Nunca PNGs externos salvo logos de Perennia.
- **Sin emojis** salvo que el usuario los pida.
- **Encoding UTF-8** + `lang="es"`. Tildes correctas en el contenido.

---

## Si el caso requiere algo no obvio

- **Slider / knob para tunear valores** → `<input type="range">` con event listener que actualiza un `<output>`. Botón "copy as prompt" que copia los valores actuales al clipboard.
- **Drag & drop de cards** → HTML5 drag API (`draggable="true"`, `ondragstart`, `ondrop`). Sin libs.
- **Diagrama SVG con boxes + arrows** → `<svg>` inline con `<rect>`, `<text>`, `<path>` para flechas. Coordenadas hardcodeadas, no library.
- **Comparison antes/después de imágenes** → dos `<img>` lado a lado o slider que revela una sobre la otra.
- **Live editing con preview** → `<textarea>` + `<div contenteditable>` + un `<iframe srcdoc="...">` que se actualiza al cambiar el textarea.
- **Charts simples** → SVG inline. Para charts complejos preguntar al usuario si vale la pena meter una lib (Chart.js).

---

## Anti-patrones

- **NO** convertir esta skill en un sistema de componentes obligatorios. Cada doc inventa el formato que mejor le sirve.
- **NO** mezclar paleta del kit con colores ad-hoc (`#ff5500`). Si necesitás un color nuevo, derivarlo de los tokens (`rgba(111,143,7,0.X)`).
- **NO** llenar el HTML con `style="..."` inline cuando un patrón se repite >2 veces — moverlo a `<style>`.
- **NO** dejar placeholders tipo "TODO: completar". Si falta info, marcarlo explícito con un highlight box.
- **NO** rellenar para alargar. Un doc de 1 página bien diseñado &gt; un doc de 5 páginas mediocre.
