---
name: actualizar-wachines
description: >-
  Actualiza el plugin de la fábrica Wachines (marketplace `wachines` de Claude Code:
  Wachines-Plugin-Ironman) a la última versión — refetchea el marketplace y recarga los
  plugins. Reemplaza el flujo viejo de `npx skills` (el equipo instala por plugin de Claude
  Code, no por npx). Usar cuando el usuario diga "actualizar wachines", "actualizá el plugin
  de la fábrica", "traé las skills nuevas", "/actualizar-wachines", o después de un release
  del plugin.
---

# actualizar-wachines

Pone al día el plugin de la fábrica (`Wachines-Plugin-Ironman`, marketplace **`wachines`**) en
Claude Code. El equipo instala por **plugin de Claude Code** (`claude plugin` / `/plugin`), **no**
por `npx skills` — así que actualizar = **refetchear el marketplace y recargar los plugins**.

## Por qué hace falta esta skill

El auto-update del plugin solo sube a la versión que el **clon local del marketplace conoce**, y
ese clon solo se refetchea en el **arranque** de Claude Code (con `autoUpdate: true`). Si no
reiniciaste, quedás pegado en una versión vieja aunque GitHub ya tenga una nueva — el botón
"Actualizar" aparece gris porque compara *instalado* vs *marketplace-local*, no contra GitHub.
Esta skill **fuerza el refetch sin reiniciar**.

## Procedimiento

### 1. Refetchear el marketplace (trae la última versión al clon local)

```bash
claude plugin marketplace update wachines
```

> Este comando CLI es no-interactivo (equivale a `/plugin marketplace update wachines`). Hace
> `git fetch/pull` del clon del marketplace en `~/.claude/plugins/marketplaces/wachines/`.

### 2. Aplicar en la sesión actual

Corré el slash command:

```
/reload-plugins
```

…o **reiniciá Claude Code** — con `autoUpdate: true` toma la nueva versión sola en el arranque.

### 3. Verificar

```bash
claude plugin marketplace list
```

Confirmá que `wachines` figura y reportá la versión instalada. **Si seguís pegado en una versión
vieja**, revisá que el release haya **bumpeado `version` en `.claude-plugin/plugin.json`**: si el
string de versión no cambia, Claude Code trata la copia como cacheada y no baja los commits nuevos.

## Config recomendada (para que el arranque lo haga solo)

En el `settings.json` de cada persona (user scope), asegurá:

```json
"extraKnownMarketplaces": {
  "wachines": {
    "source": { "source": "git", "url": "https://github.com/Perennia-Regeneracion/Wachines-Plugin-Ironman.git" },
    "autoUpdate": true
  }
},
"enabledPlugins": { "Wachines-Plugin-Ironman@wachines": true }
```

> **Wachines corre con cuentas personales** — no hay *managed settings* de organización que
> fuercen la config, así que vive en el user scope de cada uno + esta skill como el "un comando y
> listo". El plugin de **organización** (plan empresarial, con managed settings que pueden forzar
> el auto-update de forma no-overridable) es **perennia** → ver la skill `actualizar-perennia`.

## Notas

- **Nunca** tokens/keys en las skills — el CI del repo los bloquea.
- **Modo dev** (si tenés el repo clonado y editás skills): actualizá el fuente con
  `git -C ~/Documents/wachines-skills pull --ff-only` antes de trabajar. El flujo del *equipo* es
  el de arriba (`claude plugin`), no el repo clonado.
- Backstop de proceso: el `document-release` del plugin debería recordar correr esta skill (o
  reiniciar) después de cada release, así nadie queda en una versión vieja.
