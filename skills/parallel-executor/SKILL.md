---
name: parallel-executor
description: "Controlador de sprint en oleadas paralelas — reemplazo de superpowers:subagent-driven-development. Úsalo al inicio de cada sprint, inmediatamente después de writing-plans. Agrupa tareas independientes en oleadas por solapamiento de archivos, dispara todos los implementadores de una oleada simultáneamente, luego todos los revisores simultáneamente. Una tarea bloqueada nunca congela a las demás. Disparador: el usuario dice 'inicia el sprint', 'implementa el plan' o 'corre parallel-executor'. Nunca uses superpowers:subagent-driven-development — usa este en su lugar."
---

# Parallel Executor — Controlador de Sprint en Oleadas Paralelas

Reemplazo de `superpowers:subagent-driven-development` para el stack Symfony/PHP/Twig/JS. Reutiliza el mismo formato de task-brief/ledger, solo cambia el controlador secuencial por uno de oleadas paralelas.

**Causa raíz corregida:** la regla de SDD "Nunca despachar múltiples subagentes de implementación en paralelo" forzaba ejecución secuencial sin importar la independencia real de las tareas.

---

## FASE 0 — Análisis de oleadas (antes de disparar cualquier agente)

Lee el archivo del plan (pide la ruta al usuario si no es obvia — usualmente `docs/plans/<fecha>-<nombre>.md`).

Para cada tarea del plan, recolecta su bloque `Files:`:
- `Create:` → archivos nuevos que esa tarea escribe
- `Modify:` → archivos existentes que esa tarea toca

Arma un **conjunto de archivos** por tarea (unión de Create + Modify, normalizado a rutas relativas).

**Reglas de agrupación:**
1. Dos tareas van en la **misma oleada** si sus conjuntos de archivos **no se intersectan**
2. Si el brief dice `prerequisite: Task N`, va en la oleada **después** de la oleada de la Tarea N
3. Máximo **5 tareas por oleada** (techo de costo)
4. Tareas con conjunto de archivos vacío (solo investigación/config) pueden compartir oleada con cualquiera

**Salida antes de disparar cualquier agente — imprime el plan de oleadas:**

```
Plan de oleadas:
  Oleada 1: [Tarea 1, Tarea 3]  — implementadores se disparan simultáneamente
  Oleada 2: [Tarea 2, Tarea 4]  — se dispara tras aprobar la Oleada 1
```

Si solo existe 1 tarea, forma la Oleada 1 sola (igual se dispara como agente, nunca inline).

---

## FASE 1 — Ejecución por oleada

Repite para cada oleada en orden:

### Paso 1 — Registrar SHA base
```bash
git rev-parse HEAD
```
Guárdalo como `WAVE_BASE_SHA`. Se usa para los paquetes de revisión por tarea.

### Paso 2 — Extraer task-briefs
Lee la sección de la tarea directamente del archivo del plan para cada tarea de la oleada (llamadas rápidas, no agentes).

### Paso 3 — Despachar todos los implementadores simultáneamente

**Un mensaje, múltiples llamadas a `Agent()`** — este es el cambio central frente al controlador secuencial.

Para cada tarea de la oleada, despacha un agente usando la tabla de ruteo abajo. Todos se disparan en el mismo turno de mensaje.

Cada implementador recibe:
- Ruta del task-brief
- Directorio de trabajo
- "Reporta resultados con: estado (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED), lista de commits hechos (SHA + mensaje), archivos cambiados."

**Tabla de ruteo:**

| Tipo de tarea | subagent_type |
|---|---|
| Controladores, servicios, Doctrine ORM/DBAL, Security, Messenger, consola | `backend-expert` |
| Twig, Stimulus/Turbo, Webpack Encore/AssetMapper, JS/CSS | `frontend-expert` |
| Archivo nuevo sin dueño de dominio exacto (script, DTO puro, fixture) | `drafter` |
| Sin match exacto | `drafter` |

**Nunca uses `general-purpose` como implementador.**

### Paso 4 — Recolectar todos los resultados de implementadores

Espera a que los N implementadores retornen. Para cada tarea, maneja según el estado:

| Estado | Acción |
|---|---|
| `DONE` | Genera paquete de revisión → encola para la oleada de revisores |
| `DONE_WITH_CONCERNS` | Lee las preocupaciones. Si hay riesgo de corrección → trátalo como BLOCKED. Si es una observación → sigue a revisión, anótalo en el ledger. |
| `NEEDS_CONTEXT` | Responde inline, redespacha ese agente individual. Los demás slots siguen a la oleada de revisores sin esperar. |
| `BLOCKED` | Muestra el bloqueo específico al usuario de inmediato. Los demás slots continúan. Redespacha tras resolver. |

### Paso 5 — Generar paquetes de revisión (por tarea, independientemente)

```bash
git diff <sha-base-tarea-N>..<sha-head-tarea-N> > .superpowers/sdd/review-<base>..<head>.diff
```

Usa los SHA de commit reportados por el implementador — **no** `HEAD~N` — para no truncar commits de otras tareas de la misma oleada.

### Paso 6 — Despachar todos los revisores simultáneamente

**Un mensaje, múltiples llamadas a `Agent()`** — mismo patrón que los implementadores.

Cada revisor (`subagent_type: adversarial`) recibe: ruta del task-brief, ruta del reporte del implementador, ruta del diff de revisión, y la instrucción: "Emite veredictos: APPROVED / Critical / Important / Minor. Sé específico — archivo:línea para cada hallazgo."

### Paso 7 — Manejar hallazgos de revisión (por tarea, independientemente)

| Veredicto | Acción |
|---|---|
| `APPROVED` | Marca la tarea completa en el ledger de progreso. Listo. |
| Hallazgos Critical o Important | Despacha un agente de fix para esa tarea (misma tabla de ruteo). Re-revisa tras el fix. Las tareas ya APPROVED de la misma oleada no se bloquean — no las retengas. |
| Solo hallazgos Minor | Anótalo en el ledger. Marca completa. Márcalo para la revisión final de toda la rama. |

### Paso 8 — Actualizar el ledger de progreso

Para cada tarea aprobada, agrega a `.superpowers/sdd/progress.md`:
```
Tarea N: completa (commits <base>..<head>, revisión APPROVED — <resumen de una línea>)
```

---

## FASE 2 — Siguiente oleada

Una vez que **todas las tareas de la Oleada N** llegan a estado APPROVED, dispara la Oleada N+1 siguiendo exactamente los pasos de la Fase 1.

Secuencial **entre** oleadas. Paralelo **dentro** de cada oleada.

Si la Oleada N tiene una tarea atascada en NEEDS_CONTEXT o esperando al usuario en BLOCKED, dispara la Oleada N+1 para las tareas sin dependencia del slot bloqueado — no esperes.

---

## FASE 3 — Revisión final

Tras completar todas las oleadas:

1. Obtén el merge-base: `git merge-base main HEAD` → `MERGE_BASE`
2. Genera el diff completo de la rama: `git diff $MERGE_BASE HEAD > .superpowers/sdd/review-final.diff`
3. Despacha `adversarial` con el archivo de diff. Prompt: "Revisión final de rama. Emite veredicto: MERGE-READY o NEEDS-FIX con hallazgos específicos."
4. Si NEEDS-FIX: despacha un agente de fix con la lista completa de hallazgos, luego re-revisa.
5. Agrega al ledger:
   ```
   Revisión final: MERGE-READY (commits <base>..<head>; N tests pasan)
   ESTADO DEL SPRINT: MERGE-READY
   ```
6. Invoca `superpowers:finishing-a-development-branch`.

---

## Árbol de estado de sprint

Imprime **antes de disparar cada oleada** (muestra el plan) y **después de completar cada oleada** (muestra el delta). Formato completo en `~/.claude/rules/sprint-status.md`.

---

## Formato del ledger de progreso

```
# Sprint <nombre>
# Rama: feat/<slug>
# Base: <SHA>
Oleada 1: Tareas [1, 3]
Oleada 2: Tareas [2, 4, 5]
Tarea 1: completa (commits <base>..<head>, revisión APPROVED — <resumen>)
Tarea 3: completa (commits <base>..<head>, revisión APPROVED — <resumen>)
Tarea 2: completa (commits <base>..<head>, revisión APPROVED — <resumen>)
...
Revisión final: MERGE-READY (commits <base>..<head>; N tests pasan)
ESTADO DEL SPRINT: MERGE-READY
```

---

## Señales de alerta — detente y relee este archivo si notas:

- Estás por despachar implementadores de uno en uno → **DETENTE. Agrupa la oleada. Dispara todos a la vez.**
- Estás esperando que la Tarea 1 termine antes de empezar la Tarea 2 → **DETENTE. Revisa si comparten archivos. Si no, misma oleada.**
- Estás usando `general-purpose` como implementador → **DETENTE. Usa la tabla de ruteo de arriba.**
- El revisor de la Tarea 1 bloquea al implementador de la Tarea 2 cuando tocan archivos distintos → **DETENTE. Dispara ambos en paralelo.**
- 3+ tareas tardando mucho más de lo esperado → el análisis de oleadas estuvo mal. Revisa el solapamiento de archivos otra vez.

---

## Diferencia clave vs secuencial (antiguo)

| Secuencial (antiguo) | parallel-executor (este) |
|---|---|
| Un implementador a la vez | Todos los implementadores independientes en un mensaje |
| Un revisor a la vez | Todos los revisores en un mensaje |
| Una tarea bloqueada congela el sprint | Una tarea bloqueada solo pausa su propio slot |
| Regla dura "Nunca paralelizar" | Paralelo es lo normal |
