---
name: ruuts-api
description: Convenciones y flujo de trabajo para contribuir al repo ruuts-api (GitLab ruuts-la/ruuts-api) — la API que GRASS consume. Usar SIEMPRE que se trabaje en ruuts-api: un MR (!XXXX), un endpoint v2 de monitoring (tasks/pictures/events), el write-path canónico (_rev, recalc de status), responder una code review de Grego, o cualquier cambio en ese repo. Codifica los patrones que las reviews de Ruuts marcan una y otra vez (paridad con el endpoint hermano, errores tipados, concurrencia en batch, reglas del changelog) y el flujo de self-review ANTES de pedir review. NO es para el repo GRASS (ReporteGrass) ni para la plataforma Perennia.
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# Trabajar con ruuts-api

`ruuts-api` es de **Ruuts**, no nuestro: lo consumimos desde GRASS y contribuimos MRs (partnership Perennia × Ruuts, track GRASS). Sus mantenedores (Grego) revisan en serio. Esta skill existe porque sus reviews marcan los **mismos 5 patrones** una y otra vez — codificándolos, llegamos a la review con un MR casi limpio en vez de hacerles encontrar lo de siempre.

> **Origen:** destilado de la review del MR !1045 (bulk endpoints), donde 12 hallazgos cayeron en 5 patrones. La meta no es memorizar 12 fixes, es internalizar los 5 patrones + el flujo de self-review.

## Setup del repo

- Remote: `ssh://git@gitlab.com/ruuts-la/ruuts-api.git`. CLI: **`glab`** (no `gh`).
- Worktrees en `~/Documents/ruuts-api-worktrees/<branch>/`; repo principal en `~/Documents/ruuts-api`.
- Branch base de los MRs: **`staging`**. Conventional Commits.
- Node del proyecto: el que pide su `.nvmrc` (corre con node 18 en CI; los tests son **vitest**: `npx vitest run`).
- **Leé sus reglas antes de tocar nada**: `.agents/rules/` (`update-changelog.md`, `unit-tests.md`, `lint-verification.md`, `comments.md`) y `.agents/commands/pr.md`. La mitad de los hallazgos evitables salen de no haber leído estas reglas que YA existen.

## Los 5 patrones (lo que las reviews marcan siempre)

### 1. Paridad con el endpoint "hermano" — el más importante
Al agregar una **variante** de un endpoint existente (bulk/batch, v2 de un v1, un nuevo método sobre el mismo recurso), replicá **todo** lo que hace el hermano single, no solo el happy path:
- **Permisos**: los mismos claims (`validatePermissions` es OR-semantic; si el single tiene `write:all`, el bulk también — sino un superuser recibe 403 en uno y 200 en el otro).
- **Middleware de normalización**: si el single pasa por un middleware de ingress (ej. `monitoringTaskUpdateIngressNormalization` que canonicaliza el `dataPayload` y descarta el `dataPayloadSchemaVersion` del cliente), el bulk debe aplicar la **misma** normalización. Si el middleware no es reusable per-item, extraé su núcleo a una función pura compartida.
- **Side-effects**: `_rev` bump del padre, recalc de status de activity/event, etc. Si el single bumpea el `_rev` del evento (para que los devices hermanos se enteren vía el beacon de `_rev`), el bulk también — una vez por entidad distinta, no por item.
- **Shape de respuesta**: si el single devuelve `meta.eventRev` o un shape de conflicto `{ conflict, serverVersion }`, el bulk devuelve lo mismo.

> Test mental: *"¿qué hace el hermano que yo no estoy haciendo?"* Listá los middlewares, side-effects y campos de respuesta del single y verificá uno por uno.

### 2. Errores tipados, nunca `new Error().status`
- Lanzá los errores de negocio **tipados** desde `src/services/errors/errors.js`: `BusinessEntityError` (→422), `NotFoundEntityError` (→404), `ConflictError` (→409), `ForbiddenError`, `ExternalServiceError`. Metadata extra va en `parameters` (ej. `{ taskId, serverVersion }`).
- `catchAPIError` (`src/api/v2/controllers/errors/errors.js`) los mapea a HTTP. Los controllers **no ramifican** con `if (error.status === ...)` — delegan a `catchAPIError`.
- Validaciones de **input** (array vacío, campo faltante) → `response.errorBadRequest({ res, message })` en el controller (400), no `res.status(400).json()` a mano.
- Si necesitás un campo extra en la respuesta de error (taskId, serverVersion), extendé `catchAPIError` de forma **aditiva y condicional** (solo cuando el campo está), para no cambiar el shape de los errores de otros endpoints.
- No aplanes errores en un `catch` genérico (`throw new Error('Unable to X: ' + e.message)`) — eso colapsa un error tipado a 500. Re-lanzá si es `RuutsError`; envolvé solo lo inesperado, con `{ cause }`.

### 3. Concurrencia e integridad en batch
- **Optimistic concurrency obligatoria**: si el write usa `_rev`, en un **batch** exigilo por item (400 si falta). Opcional está bien en el single, pero en un lote de 100 omitirlo degrada a last-write-wins silencioso y pisás 100 ediciones. (Si el consumidor —GRASS— no lo manda, ajustá el consumidor: tiene el `_rev` fresco del record que cargó.)
- **Orden de lock determinístico**: si cada item toma `LOCK.UPDATE`, ordená el batch por `id` antes del loop, o dos batches concurrentes con items solapados deadlockean (Postgres aborta uno con 500).
- **Atomicidad**: todo el batch en una transacción; un fallo en cualquier item hace rollback de todo.
- **Write-path canónico compartido**: single y bulk deben usar la MISMA función de escritura (ej. `applyTaskUpdate`), no lógica paralela. El bulk es un wrapper batch sobre el write-path del single.

### 4. Cleanup de recursos externos en error paths
Subidas a S3 (u otro recurso externo) que ocurren **antes** de la transacción de DB deben estar dentro del `try` cuyo `catch` limpia. Usá `Promise.allSettled` (no `all`) para que una subida que resuelve **después** de que una hermana rechaza también quede trackeada y se limpie — `Promise.all` corta al primer reject y deja huérfanas las que ya subieron.

### 5. Changelog (regla de ELLOS, leéla)
`.agents/rules/update-changelog.md` es explícita y la violamos seguido:
- Entradas nuevas van bajo **`## RELEASE vNext`** (arriba de todo), nunca bajo un release ya publicado (cuidado al rebasear: el rebase a veces las mete en el release viejo).
- **Sin endpoints crudos** (`POST /v2/...`), sin jerga interna (`allowedFields`, `tasks.list retorna {count,rows}`). Lenguaje de **producto/usuario**.
- Prefijo **`(ID XXXX)`** de Notion en cada entrada (como las vecinas). Ante la duda, **confirmá el ticket** antes de redactar — no inventes el ID; dejá `(ID XXXX)` y pedilo.

## Flujo de un MR (con self-review — el cambio de hábito clave)

1. **Leé** las `.agents/rules/` relevantes del repo ANTES de escribir.
2. Branch desde `staging`; implementá siguiendo los 5 patrones.
3. **Tests + lint locales**: `npx vitest run` (suite entera verde) + `npx eslint .` (0 *errores*; los warnings pre-existentes no bloquean). Agregá tests que documenten el comportamiento nuevo (ej. el bump de `_rev`, el cleanup en fallo de subida, el 400 por `_rev` faltante).
4. **Self-review ANTES de pedir review** (shift-left): corré `/code-review` sobre tu diff y atendé lo que salga. Grego revisa con un agente igual — si vos lo corrés primero, llega un MR casi limpio. Pasá el diff por los 5 patrones de arriba como checklist.
5. Push + abrí el MR (Draft mientras itera). Si toca el contrato que GRASS consume (permisos, shape de error, `_rev`), abrí el **PR espejo en GRASS** y notá la dependencia **lockstep** en ambos.
6. Al responder una review: **no patees nada**. Corregí cada hallazgo o explicá por qué no aplica. Si un fix implica cambiar GRASS, cambialo. Respondé punto por punto en el MR y reaccioná 👍.

## Checklist pre-push (pegá esto mentalmente antes de cada `git push`)

- [ ] ¿Mi endpoint hace **todo** lo que su hermano single hace? (permisos, normalización, `_rev` bump, recalc, shape de respuesta)
- [ ] ¿Errores **tipados** + `catchAPIError`, sin `new Error().status` ni ramificación manual en el controller?
- [ ] ¿`_rev` obligatorio en batch? ¿lock ordenado por `id`? ¿una sola transacción?
- [ ] ¿Cleanup de S3/recursos externos en el error path, con `allSettled`?
- [ ] ¿Changelog en `vNext`, sin jerga/endpoints, con `(ID XXXX)`?
- [ ] ¿Suite verde + ESLint 0 errores?
- [ ] ¿Corrí `/code-review` sobre el diff y atendí lo que salió?
- [ ] ¿Si toca un contrato que GRASS consume, abrí el PR espejo y noté el lockstep?
