---
name: wachi-ideacion
description: 'Ideación anti-slop para el proceso de producto: toma una idea cruda o un espacio de problema, lo ancla en evidencia real (inputs del fichero, brain, repo, usuarios), genera muchas opciones, las critica TODAS con un verificador de contexto fresco y presenta solo las sobrevivientes con su base citada — más las 6 preguntas forzadoras para exponer si la demanda es real. Usar en la etapa de ideación/discovery de wachi-producto, o suelta cuando el equipo quiere pensar un problema antes de definir. Aterriza en RumIAndo: ficha IDEA→BORRADOR, contexto crudo como fichero_input. NO define requisitos (eso es wachi-definicion).'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-ideacion — pensar opciones sin slop

Generás y evaluás **ideas fundadas**, no una lluvia de genéricos. El mecanismo de calidad es el **rechazo explícito con razones**, no el ranking optimista. Y antes de enamorarte de una idea, las **preguntas forzadoras** exponen si alguien la necesita de verdad.

> **Fuentes robadas** (skill propia, los originales NO se invocan): EveryInc/compound-engineering-plugin `ce-ideate` @ v3.17.0 (basis + verificador fresco + meeting-test) · garrytan/gstack `office-hours` @ v1.58.0.0 (forcing questions + principios). Re-sync: revisar upstream cada ~2 meses.
> Aterrizaje en RumIAndo: `skills/wachi-producto/references/aterrizaje-rumiando.md`.
> Embebé el spine (`_shared/agent-spine.md`): voz directa, anti-slop, quote-the-evidence, completion honesto.

## ⚖️ IRON LAW
**NINGUNA IDEA AFLORA SIN BASE CITADA.** Cada idea lleva exactamente una base tageada; sin base articulada, se rechaza por `sin-justificar`. La especificidad es la única moneda.

## Fase 0 — Anclá (grounding antes de idear)

No generes consejos abstractos desconectados de la realidad. Antes de idear, juntá evidencia (en paralelo, subagentes si conviene):
- **RumIAndo:** los `fichero_input` del fichero (la materia prima ya cargada), fichas hermanas, hallazgos de sesiones previas (`actividad_filtrada`).
- **El brain** (`wachines-brain`): decisiones ya tomadas, benchmarks, contradicciones — no ideés lo que ya se decidió no hacer.
- **El repo/producto real** si la idea toca algo construido.
- Lo que el usuario trajo (transcripciones, notas de campo, WhatsApp).

Si el contexto crudo que trajo el usuario no está en RumIAndo, **cargalo como `fichero_input`** (`url`|`texto`|`adjunto`) — la materia prima queda para la próxima.

## Fase 1 — Las preguntas forzadoras (cuando la idea es apuesta, no ajuste)

Para ideas con ambición (profundidad Estándar/Profunda), pasá al usuario por las 6 preguntas — **de a una** (AskUserQuestion), empujando hasta que la respuesta sea específica, con evidencia, e incómoda. La comodidad significa que no se fue lo bastante hondo:

1. **Demanda real** — ¿cuál es la evidencia más fuerte de que alguien QUIERE esto — no "le interesa", no "se anotó en la lista": que se enojaría si desaparece mañana? *(Red flag: "la gente dice que está bueno")*
2. **Status quo** — ¿qué hacen HOY los usuarios para resolver esto, aunque sea mal? ¿Qué les cuesta ese workaround? *(Si "nada" — quizás el dolor no alcanza. El status quo es el competidor real.)*
3. **Especificidad desesperada** — nombrá al humano concreto que más lo necesita. ¿Qué lo asciende? ¿Qué lo hace echar? *(Una categoría no es una persona: no le podés escribir a "los productores".)*
4. **Cuña más angosta** — ¿cuál es la versión MÁS chica por la que alguien pagaría esta semana, no después de construir la plataforma?
5. **Observación y sorpresa** — ¿viste a alguien usarlo SIN ayudarlo? ¿Qué hizo que te sorprendió? *(Encuestas mienten; demos son teatro. Mirar, no demostrar.)*
6. **Encaje futuro** — si el mundo cambia en 3 años (y va a cambiar), ¿esto se vuelve más esencial o menos? *(“el mercado crece 20%” no es una visión.)*

**Anti-obsecuencia:** tomá posición en cada respuesta y decí qué evidencia te haría cambiar. Prohibido "interesante enfoque", "hay muchas formas de verlo", "podría funcionar". Desafiá la versión más fuerte del argumento, no un espantapájaros.

## Fase 2 — Generá muchas, criticá todas

1. **Descomponé el tema en 3–5 ejes ortogonales** (aspectos distintos del problema) y generá candidatos por eje — evita que todas las ideas sean variaciones de la misma.
2. Cada candidato lleva **exactamente una base**:
   - `directa:` cita textual de evidencia real ("el técnico dijo X en la sesión del 12-jun", `fichero_input` #N, `archivo:línea`)
   - `externa:` prior art nombrado y verificable (producto, benchmark, práctica)
   - `razonada:` argumento de primeros principios, escrito
3. **Verificador de contexto fresco:** spawneá un subagente que NO vio la generación (pasale solo el grounding + la lista de candidatos) y que dictamine por candidato: `sólida` / `débil` / `refutada` + razón de una línea (¿la cita existe? ¿el prior art es real? ¿el razonamiento se sostiene?). Vos hacés el corte final; una base refutada es evidencia fuerte en contra.
4. **Criterios de rechazo** (usa estos nombres): `vaga` · `no-accionable` · `duplica-una-más-fuerte` · `sin-anclar-al-contexto` · `cara-vs-valor` · `ya-cubierta` · `sin-justificar` (sin base) · `base-refutada` · `bajo-el-piso-de-ambición` (falla el **meeting-test**: ¿ameritaría discusión de equipo sin preparación? — se exime si el pedido era explícitamente táctico/polish) · `cambia-de-tema` (abandona el sujeto en vez de operar sobre él) · `se-pasa-de-alcance`.

## Fase 3 — Presentá y aterrizá

**Output:** las sobrevivientes rankeadas — por idea: título, descripción, eje, **base** (tageada), fundamento, contras, confianza (0-100%), complejidad (Baja/Media/Alta) — y la **tabla de rechazadas** con su criterio de una línea (el rechazo visible es el mecanismo de calidad).

**Aterrizaje en RumIAndo:**
- La(s) idea(s) que el usuario elige avanzar → ficha (`criar_ficha` si no existe; `guardar_ficha` con el resultado de la ideación como contenido versionado, `p_nota`: "ideación YYYY-MM-DD") → `transition_ficha(→BORRADOR)`.
- Las rechazadas con valor de registro → quedan en el contenido versionado de la ficha (sección "descartado y por qué") — el porqué de lo que NO se hizo también es de las tres dimensiones.
- Si la ideación produjo una decisión durable de producto/arquitectura → el porqué va al **brain** (git-first), no solo a RumIAndo (`_shared/frontera-datos.md`).

Handoff: ficha en `BORRADOR` con opciones elegidas → **`wachi-definicion`**.
