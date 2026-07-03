---
name: wachi-validacion-usuario
description: 'Validación con usuarios reales sobre RumIAndo: prepara la sesión desde el contrato de la ficha (qué hipótesis se testean, con qué prototipo, con quiénes), guía la conducción (mirar sin ayudar, no vender), y registra TODO en RumIAndo — sesión de validación, hallazgos tipados (ux/funcional/tecnico/bloqueante), decisiones (aceptar/rechazar/iterar/derivar) — cerrando el loop: procesa las decisiones a transiciones de ficha. Usar cuando una ficha/fichero en PARA_VALIDAR se testea con productores/técnicos/usuarios, y también para registrar a posteriori una sesión que ya ocurrió. NO es QA técnico (wachi-qa) ni review interno (wachi-validacion-interna).'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-validacion-usuario — validar con usuarios de verdad

Convertís el contrato de la ficha en una **sesión de validación con evidencia**: qué se testea, con quién, qué pasó, qué se decidió — todo registrado en RumIAndo, con el loop cerrado a la state machine. La sesión que no se registra no existe; el hallazgo sin evidencia es opinión.

> Skill **propia** (sin fuente externa directa — el modelo de sesión es el de RumIAndo). Principios de conducción robados de garrytan/gstack `office-hours` @ v1.58.0.0 ("mirar, no demostrar"). Re-sync: revisar upstream cada ~2 meses.
> Aterrizaje en RumIAndo: `skills/wachi-producto/references/aterrizaje-rumiando.md`.
> Embebé el spine (`_shared/agent-spine.md`): voz directa, anti-slop, quote-the-evidence, completion honesto.

## ⚖️ IRON LAW
**MIRÁ, NO DEMUESTRES.** Un walkthrough guiado no enseña nada del uso real; ver a alguien trastabillar — mordiéndote la lengua — enseña todo. Y todo hallazgo lleva la **evidencia de qué hizo o dijo el usuario**, no tu interpretación.

## Fase 0 — Prepará la sesión (desde el contrato)

1. Leé la ficha: los **requisitos (R-IDs) y flujos (F-IDs)** del contrato son las hipótesis a testear. Extraé 3–5 **preguntas de la sesión** ("¿el técnico encuentra dónde cargar la recorrida sin ayuda?" — conductuales, no de opinión).
2. **Prototipo:** el `prototipo_url` del fichero (o del release si se valida un corte). Si no hay prototipo y el contrato tiene UI, frenó — pedí el wireframe/prototipo primero (a `wachi-fabrica` o al equipo).
3. **Participantes:** usuarios reales del actor correcto (los A-IDs del contrato). Un productor no valida el flujo del técnico.
4. **Abrí la sesión en RumIAndo:** `crear_sesion_validacion(id_fichero, fecha, participantes[], prototipo_url, notas)` — las notas llevan las preguntas de la sesión.

## Fase 1 — Conducí (o registrá lo conducido)

Guía de conducción (para el humano que la corre — vos preparás el guion):
- **Tarea, no tour:** dale al usuario una tarea real ("cargá la recorrida de ayer") y mirá. No expliques salvo bloqueo total.
- **Preguntas no inductoras:** "¿qué esperabas que pasara?" — nunca "¿viste qué fácil que es X?".
- **Cazá la sorpresa:** lo que el usuario hace que contradice tus supuestos es el dato más valioso de la sesión.
- Las **palabras del usuario le ganan al pitch**: si describe el valor distinto a como lo escribimos en el contrato, su versión es la verdad.

Si la sesión ya ocurrió (transcripción, notas, audio): extraé hallazgos y decisiones de ahí — mismo registro, a posteriori.

## Fase 2 — Registrá (todo, tipado, con evidencia)

Por cada cosa que pasó: `agregar_hallazgo` (sobre la sesión abierta; params exactos en `mis_capacidades`)
- **Tipos:** `ux` (no encontró/no entendió) · `funcional` (falta o sobra comportamiento) · `tecnico` (roto/lento) · `bloqueante` (impide el valor central).
- **La descripción lleva la evidencia:** *"[Participante] intentó X, pasó Y — «cita de lo que dijo»"*. Vinculá la **ficha afectada** cuando el hallazgo apunta a una ficha concreta (puede ser transversal).

Por cada resolución tomada con el equipo: `agregar_decision` (sobre la sesión; params en `mis_capacidades`)
- **Acciones:** `aceptar` (la hipótesis validó) · `rechazar` (no va) · `iterar` (vuelve a definición con estos cambios) · `derivar` (abre un ticket/ADR y vinculalo a la decisión).

Cerrá: `cerrar_sesion_validacion` — después del cierre no entran más hallazgos.

## Fase 3 — Procesá las decisiones (el loop que no se cierra solo)

RumIAndo registra pero **no transiciona automáticamente** — eso es tuyo:
- `aceptar` sobre la ficha → `transition_ficha(→VALIDADA)` + marcá el ítem de DoR "validado con usuario" (`actualizar_dor_ficha`).
- `iterar` → `transition_ficha(→BORRADOR)` y pasale a `wachi-definicion` los hallazgos como input (los R-IDs afectados).
- `rechazar` → charla con el humano: ¿se elimina la ficha (`eliminar_ficha`) o queda en `PARA_VALIDAR` esperando otra vuelta? El porqué del rechazo va al contenido de la ficha (y si es aprendizaje durable, a `wachi-compound`).
- `derivar` → creá el ticket (`crear_ticket`) y, si bloquea la ficha, `vincular_adr_ficha`.
- Hallazgos `bloqueante` sin decisión → **gate humano** (AskUserQuestion): no cierres la corrida con bloqueantes flotando.

**Reporte final:** qué se testeó, con quiénes, hallazgos por tipo (con evidencia), decisiones tomadas, y **en qué estado quedó cada ficha** (los `effects` reales). Handoff: ficha `VALIDADA` → **`wachi-validacion-interna`**.
