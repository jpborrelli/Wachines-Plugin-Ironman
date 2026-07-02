---
name: wachi-compound
description: 'Captura de aprendizaje al cierre de cualquier corrida de producto o build: convierte lo aprendido (qué validó, qué falló, por qué se decidió lo que se decidió) en conocimiento retornable con criterio de aplicación explícito — enrutado por la frontera de datos (porqué durable → Wachi Brain git-first · gotcha de código → Engram con ticket · hecho de fábrica → ya quedó en RumIAndo) — y poda el conocimiento viejo (mantener/actualizar/consolidar/reemplazar/borrar). Usar al cerrar una ficha (SHIPPED o rechazada), después de una sesión de validación reveladora, al resolver un ADR, o periódicamente para podar. La primera resolución cuesta 30 minutos; documentada, la próxima cuesta 2.'
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# /wachi-compound — que el trabajo componga

Cada unidad de trabajo debería hacer **más fácil** la siguiente, no más difícil. Capturás el aprendizaje mientras el contexto está fresco, con **criterio de aplicación explícito** (cuándo usar esto — y cuándo NO), y lo enrutás al lugar donde el equipo lo va a reencontrar.

> **Fuente robada** (skill propia, el original NO se invoca): EveryInc/compound-engineering-plugin `ce-compound` + `ce-compound-refresh` @ v3.17.0 (formato de learning-doc, los 5 outcomes de poda). Estructura de retro: garrytan/gstack `retro` @ v1.58.0.0. Re-sync: revisar upstream cada ~2 meses.
> Frontera de datos: `_shared/frontera-datos.md` · Aterrizaje: `skills/wachi-producto/references/aterrizaje-rumiando.md`.

## ⚖️ IRON LAW
**TODO APRENDIZAJE LLEVA "CUÁNDO APLICA" Y "CUÁNDO NO".** Un aprendizaje sin criterio de aplicación es una anécdota: nadie sabe cuándo volver a usarlo. Y se enruta por la frontera de datos — no todo va al mismo lado.

## Fase 0 — ¿Qué se aprendió y de qué tipo es?

Al cierre de una corrida (ficha SHIPPED o rechazada, sesión de validación, ADR resuelto, retro), extraé los aprendizajes y clasificá cada uno en su **pista**:

- **Pista producto/proceso** — "los productores no cargan datos si el win no es visible", "validar con prototipo antes de definir ahorró dos vueltas". → **Wachi Brain**.
- **Pista decisión** — el porqué de un ADR, un veredicto de adopción, un rechazo de feature. → **Wachi Brain** (`decisiones/`) + ya registrado en RumIAndo.
- **Pista código** — gotcha técnico, convención, fix no obvio del repo en el que se trabajó. → **Engram** (`mem_save`) con `ticket: WCH-NNN` en el frontmatter.
- **Hecho de fábrica** — si el evento en sí (decisión de sesión, transición, hallazgo) no quedó en RumIAndo, eso es un bug del proceso: registralo ahora (RPC), no lo "documentes" en otro lado.

## Fase 1 — Escribí el learning-doc (pista producto/decisión → brain)

Formato (`.md` git-first en el hub, `productos/…` o `decisiones/` según la frontera):

```markdown
---
tipo: aprendizaje
categoria: <producto | proceso | validacion | decision>
tags: [<buscables>]
aplica_cuando: "<la condición concreta que lo dispara>"
severidad: <alta | media | baja>
ticket: WCH-NNN
fecha: YYYY-MM-DD
---
# <título que se encuentra buscando el problema, no la solución>

## Qué pasó            ← el hecho + contexto, con evidencia (sesión, ficha, cita)
## Por qué importa     ← el costo de no saberlo
## Cuándo aplicar      ← señales concretas de que este aprendizaje es relevante
## Cuándo NO aplicar   ← los falsos amigos (dónde parece aplicar y no)
## Qué haríamos distinto
```

Regla de las tres dimensiones: capturá **hecho + contexto + razonamiento** — el porqué es lo que el brain no puede reconstruir después.

## Fase 2 — Podá (el conocimiento viejo también se gestiona)

Al escribir uno nuevo, chequeá los existentes que se le solapan (búsqueda en el brain / `docs/solutions` del repo). Cinco salidas, sé decisivo:

| Salida | Cuándo |
|---|---|
| **Mantener** | sigue exacto y útil — no lo toques (no edites solo para dejar huella) |
| **Actualizar** | la solución sigue, pero driftaron referencias (paths, nombres, links) — edición puntual con evidencia |
| **Consolidar** | 2+ docs se solapan fuerte y ambos son correctos — mergeá al canónico, borrá el subsumido |
| **Reemplazar** | el viejo ahora confunde y existe un sucesor mejor — crealo y borrá el viejo |
| **Borrar** | ya no aplica ni es distinto — **borrar, no archivar**: el historial de git es el archivo |

En la duda entre salidas, marcá `estado: revisar` en el frontmatter y seguí — mejor honesto que churn.

## Fase 3 — Retro liviana (cuando cierra un ciclo, no cada corrida)

Al cierre de una semana/release: qué se shippeó (fichas → SHIPPED), qué validó y qué no (sesiones), qué ADRs se resolvieron y qué costaron, y **qué aprendizaje previo se re-aplicó** — decilo explícito ("aprendizaje aplicado: <título>") para que el compounding sea visible. Los patrones que se repiten 2+ veces son candidatos a subir de learning-doc a **regla de skill** (mejorá la definición de la hija que corresponda — la palanca de la fábrica es iterar sus definiciones).
