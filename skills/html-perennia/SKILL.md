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
  version: "1.0.0"
---

# html-perennia — Pensá en HTML, con la paleta de Perennia

Esta skill es **una señal, no un generador**. No tiene boilerplates, no tiene catálogo de componentes obligatorios, no tiene templates rígidos. Cada artefacto se diseña libremente según el caso.

Lo único que asegura: (1) que Claude considere HTML como default cuando el artefacto se va a leer/validar/compartir, en lugar de defaultear a markdown plano, y (2) que el resultado tenga la identidad visual de Perennia (paleta tierra-verde, DM Sans + Inter + JetBrains Mono).

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

## Estilo Perennia — la única restricción

Todo lo demás es libre. Pero los colores y tipografías deben ser los de Perennia, sino el artefacto se siente de otro repo. Esta es la "marca de agua" visual.

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

### Inspiración visual

Para calibrar el look, mirá HTMLs ya hechos de tu repo (decks, specs, reports) y fijate cómo
combinan la paleta, la jerarquía tipográfica y los SVG inline. NO copiar la estructura literal
de ninguno — son ejemplos para **calibrar el look**, no templates.

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
