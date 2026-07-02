---
name: wachi-definicion
description: 'Definición del artefacto de producto: convierte una idea en BORRADOR en un contrato de producto completo — problema, requisitos con IDs estables, actores, flujos, ejemplos de aceptación, fronteras de alcance — como UN artefacto que madura in-place (nunca dos docs que driftan), con right-sizing (el doc crece con el contenido, no por plantilla) y confirmación de alcance ANTES de escribir (Declarado/Inferido/Fuera). Usar en la etapa de definición de wachi-producto, o suelta para escribir/enriquecer el contenido de una ficha funcional. Aterriza en RumIAndo: contenido versionado de la ficha + transición BORRADOR→PARA_VALIDAR. NO decide adopción de tecnología (wachi-validacion-interna) ni valida con usuarios (wachi-validacion-usuario).'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-definicion — el artefacto que madura

Escribís el **contrato de producto** de una ficha: qué se construye y cómo sabremos que está bien — con el detalle justo. Un solo artefacto que se **enriquece in-place** a medida que avanza (el contenido versionado de la ficha), nunca un doc funcional y uno técnico gemelos que driftan.

> **Fuente robada** (skill propia, el original NO se invoca): EveryInc/compound-engineering-plugin `ce-brainstorm` + `ce-plan` @ v3.17.0 (artefacto unificado, secciones canónicas, scoping synthesis, prose economy). Re-sync: revisar upstream cada ~2 meses.
> Aterrizaje en RumIAndo: `skills/wachi-producto/references/aterrizaje-rumiando.md`.

## ⚖️ IRON LAW
**CONFIRMÁ EL ALCANCE ANTES DE ESCRIBIR.** Corregir el alcance en la charla es barato; corregirlo después de escribir el artefacto (o peor, después de validar) es caro. Y: **el progreso NO vive en el doc** — vive en la state machine de RumIAndo. El doc solo declara su completitud.

## Fase 0 — Alcance primero (surface-scope-earlier)

Antes de escribir una línea del artefacto, armá la **síntesis de alcance** en tres baldes:
- **Declarado** — lo que el usuario pidió explícitamente.
- **Inferido** — lo que vos completaste (¡esto es lo peligroso!).
- **Fuera de alcance** — lo que NO entra, dicho.

Emití los **call-outs**: los puntos donde una decisión del usuario cambia materialmente el plan ("¿offline-first o requiere señal?", "¿solo técnicos o también productores?"). **Confirmación bloqueante** (AskUserQuestion, una por vez) salvo profundidad Liviana con cero call-outs → ahí procedé directo.

## Fase 1 — Entendé y dialogá

- Leé el contenido actual de la ficha (versiones previas, la ideación si vino de `wachi-ideacion`) y la materia prima del fichero (`fichero_input`).
- **Presión de producto** (interna, no se la muestres al usuario): ¿dónde le falta rigor a la idea? ¿qué condición de borde nadie nombró? Usala para dirigir el diálogo.
- Diálogo colaborativo: separá los **QUÉ** (requisitos) de los **CÓMO** (implementación — no los resuelvas acá; si son decisiones que constriñen, van como Decisiones Clave).

## Fase 2 — Escribí el contrato (right-sized)

**Piso duro** (siempre): **Cápsula de Objetivo** (objetivo, autoridad, bloqueantes abiertos) + **Contrato de Producto** con **requisitos con IDs estables** (`R1.`, `R2.` — prefijo plano, nunca renumerar al reordenar/borrar).

**Secciones "incluir cuando aporten"** (decidí por contenido, no llenes plantilla):
| Sección | Incluila si… |
|---|---|
| Marco del problema | la motivación no es obvia desde el resumen |
| Decisiones clave | hubo elecciones de encuadre que constriñen (defaults, recortes de alcance) |
| Actores (`A1.`) | hay comportamiento multi-parte (técnico, productor, admin…) |
| Flujos clave (`F1.`) | hay comportamiento multi-paso (default esperable en features de comportamiento) |
| Ejemplos de aceptación (`EA1.`) | algún requisito es condicional/depende de estado y queda ambiguo sin ejemplo |
| Criterios de éxito | hay señales de calidad/métrica que los requisitos no llevan |
| Fronteras de alcance | el alcance está disputado o hay non-goals tentadores (separá "diferido" de "fuera de la identidad del producto") |
| Preguntas abiertas | hay pendientes — distinguí **bloqueantes** (resolver antes de validar) de **diferidas** (las contesta el build) |
| Visualizaciones / wireframe | el concepto tiene **estructura que mostrar** (flujo, estados, relación de entidades) — las UI necesitan wireframe, no prosa |
| Fuentes | hay research que justifique el encuadre |

**Economía de prosa:** encabezá con la decisión, después la razón. Una idea por oración. Un requisito = una oración de intención + a lo sumo un calificador. Sin relleno ni hedges. Resolvé en el lugar (reescribí lo superado), no estratifiques.

**Cuándo NO escribir artefacto** (las dos juntas): el diálogo no produjo alcance/decisiones dignas de IDs, **y** lo decidido fluye a los artefactos siguientes sin doc intermedio. Un ajuste trivial no necesita contrato — decilo y aterrizá directo.

## Fase 3 — Aterrizá

- El contrato es el **contenido de la ficha**: `guardar_ficha` (versiona snapshot inmutable; `p_nota` = qué cambió en esta versión). El JSONB `contenido` lleva las secciones; los IDs estables (`R*/A*/F*/EA*`) hacen trazable la validación y el build.
- **Sembrá el DoR** (`actualizar_dor_ficha`): los ítems que este contrato ya sabe que deben cumplirse antes de construir (ej. "validado con ≥1 usuario", "sin preguntas bloqueantes", "wireframe revisado") — nacen `done: false`.
- Cuando el contrato está completo **y sin preguntas bloqueantes** → `transition_ficha(→PARA_VALIDAR)`. Si quedan bloqueantes, la ficha se queda en `BORRADOR` — la completitud es binaria, no "casi lista".

Handoff: ficha en `PARA_VALIDAR` → **`wachi-validacion-usuario`** (o directo a `wachi-validacion-interna` si la profundidad Liviana no amerita sesión con usuarios — decilo explícito).
