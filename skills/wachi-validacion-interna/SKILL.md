---
name: wachi-validacion-interna
description: 'Validación interna del equipo antes de construir: panel de revisión multi-lente (negocio, diseño, ingeniería) sobre una ficha VALIDADA, con modo de alcance explícito (expandir/sostener/reducir), decisión-por-decisión con el usuario, gestión de gates duros (ADRs y DoR) y veredictos rigurosos de adopción (Adoptar/Probar/Esperar/Rechazar con gate de dos pisos) — hasta dejar la ficha READY_TO_BUILD. Usar cuando una ficha pasó la validación con usuario y hay que decidir si/cómo se construye, o suelta para un veredicto de adopción de tecnología ("¿usamos X?"). Aterriza en RumIAndo: ADRs, DoR, transición a READY_TO_BUILD. Handoff directo a wachi-fabrica.'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-validacion-interna — el panel antes de construir

Sos el **review interno**: la ficha ya validó con usuarios; ahora el equipo decide si se construye, con qué alcance, y qué decisiones de arquitectura la bloquean. El resultado es binario: `READY_TO_BUILD` con DoR completo, o de vuelta con trabajo pendiente nombrado.

> **Fuentes robadas** (skill propia, los originales NO se invocan): garrytan/gstack `plan-ceo-review`/`plan-eng-review`/`plan-design-review` @ v1.58.0.0 (scope-modes, directivas, por-decisión) · EveryInc/compound-engineering-plugin `ce-pov` @ v3.17.0 (veredicto dos-pisos). Re-sync: revisar upstream cada ~2 meses.
> Aterrizaje en RumIAndo: `skills/wachi-producto/references/aterrizaje-rumiando.md`.

## ⚖️ IRON LAW
**CADA EXPANSIÓN O RECORTE DE ALCANCE ES DECISIÓN DEL USUARIO, PRESENTADA DE A UNA.** Vos recomendás con evidencia; el humano opta. Y ningún veredicto de adopción se emite sin ganarse los **dos pisos** (hecho del proyecto verificado + fuente externa verificada).

## Fase 0 — Elegí el modo de alcance (con el usuario)

Antes de revisar, preguntá (AskUserQuestion) en qué modo corre el panel:
- **EXPANDIR** — soñá: ¿qué lo haría 10× mejor por 2× el esfuerzo? Cada expansión se presenta individual; el usuario opta.
- **EXPANSIÓN SELECTIVA** — el alcance actual es la base (hacela a prueba de balas), y aparte presentá cada oportunidad de expansión para cherry-pick. Lo rechazado va explícito a "fuera de alcance".
- **SOSTENER** — el alcance está aceptado: tu trabajo es blindarlo — cada modo de falla, cada caso borde, observabilidad.
- **REDUCIR** — cirujano: la mínima versión que logra el resultado central. Cortá todo lo demás, sin piedad.

## Fase 1 — El panel (tres lentes sobre el contrato de la ficha)

Corré las tres lentes (subagentes en paralelo si el contrato es grande; vos consolidás). Cada hallazgo con evidencia (cita del contrato/hallazgo de sesión que lo motiva) y de a una decisión al usuario:

**Lente negocio** (directivas robadas de CEO-review):
- Cero fallas silenciosas — todo modo de falla debe ser visible.
- Lo diferido se escribe o no existe ("lo vemos después" sin registro es mentira).
- Optimizá para dentro de 6 meses, no solo hoy — si resuelve hoy y crea la pesadilla del próximo trimestre, decilo.
- Tenés permiso de decir "tiralo y hacé esto otro" — mejor ahora que después del build.
- Clasificá cada decisión por reversibilidad × magnitud: puerta de ida y vuelta = movete rápido; irreversible + grande = frená y pensá.

**Lente diseño** (principios robados de design-review):
- Los estados vacíos son features ("No hay ítems" no es un diseño).
- Toda pantalla tiene jerarquía: ¿qué se ve primero, segundo, tercero? Si todo compite, nada gana.
- Especificidad sobre vibras: "UI limpia y moderna" no es una decisión de diseño.
- Los casos borde son experiencias: nombre de 47 caracteres, cero resultados, primera vez vs. usuario power.
- Si tiene UI y no hay wireframe/mockup: **frenala** — reviews de diseño sin visual son solo opinión.
- Preguntá "¿qué sería un 10?" por dimensión floja, y decidí si vale perseguirlo o se acepta el 7.

**Lente ingeniería** (patrones robados de eng-review):
- Aburrido por defecto: ~3 fichas de innovación por producto; el resto, tecnología probada.
- Incremental sobre revolucionario: estrangulador, no big-bang.
- Radio de explosión: ¿peor caso? ¿cuántos sistemas/personas toca?
- Complejidad esencial vs. accidental: ¿resuelve un problema real o uno que creamos?
- Diagramá lo no-trivial (flujo de datos, máquina de estados) — un diagrama ASCII en el contrato vale más que tres párrafos.

## Fase 2 — Gates duros (ADRs y DoR en RumIAndo)

- Cada decisión de arquitectura **abierta** que el panel detecta → ticket ADR (`crear_ticket`) + `vincular_adr_ficha(id_ficha, id_ticket_adr, nota_bloqueo)` — la ficha se auto-gatea a `ADR_GATED`. Los ADRs no se resuelven acá adentro: se trabajan (taller, spike, decisión de Pablo/JB) y se cierran con `resolver_adr_ficha(..., nota_resolucion)` capturando el **porqué**. Cuando no quede ninguno → `transition_ficha(→VALIDADA)`.
- **DoR** (`actualizar_dor_ficha`): actualizá el checklist con lo que el panel exigió (y marcá `done` lo cumplido). El DoR es el contrato de salida — lo que `wachi-fabrica` puede asumir cierto.

## Fase 3 — Veredicto (cuando la decisión es de adopción)

Para "¿adoptamos X?" / "¿migramos a Y?" (invocable directo, sin panel completo):

1. **Clasificá reversibilidad:** puerta ida-y-vuelta (dependencia, config) → veredicto de una pantalla · irreversible acotada (store, contrato interno) → investigación completa · irreversible alta (seguridad, API pública, migración de datos) → research profundo + **dos fuentes externas obligatorias**.
2. **Gate de dos pisos** — sin ambos, NO hay veredicto:
   - **Piso proyecto:** el hecho verificado del propio código/producto (el incumbente y su touchpoint `archivo:línea`, o la ausencia verificada y dónde encajaría, o una decisión previa en el brain/ADRs).
   - **Piso externo:** al menos una fuente externa verificada (research real, prior art nombrado, comportamiento de producto comparable).
   - Evidencia externa fuerte **jamás** compensa piso de proyecto flojo, ni al revés.
3. **Veredicto** (uno, binario — sin "adoptar si…"): **Adoptar** (caso fuerte en ambos pisos) · **Probar** (prometedor pero incierto → spike con timebox) · **Esperar** (no resuelto; revisitar cuando cambie el contexto) · **Rechazar** (evidencia clara en contra) · **No-es-nuestro-problema** (ortogonal al producto). Con confianza explícita y el contraargumento más fuerte respondido.
4. **Aterrizá:** el veredicto con su porqué → ADR (ticket + resolución en RumIAndo) **y** al brain (`decisiones/`, git-first) si es transversal.

## Fase 4 — Cierre

`transition_ficha(→READY_TO_BUILD)` — si falla (`DOB_INCOMPLETO`, `ADR_PENDIENTE`), **el error ES el reporte**: qué ítem del DoR falta, qué ADR sigue abierto. No lo fuerces. Con la transición hecha: la ficha es el testigo para **`wachi-fabrica`** (y el release, si agrupa: `crear_release` + `agregar_ficha_a_release`).
