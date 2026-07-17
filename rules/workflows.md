# Equipos de Trabajo Estándar + Patrones de Oleadas Paralelas

**Alcance de la regla:** se carga bajo demanda para planificación de sprint y decisiones de despacho multiagente.

## Agentes en paralelo — Grupo de Expertos

**Mínimo 3 agentes por tarea. Objetivo por defecto: 5. Máximo: 8 simultáneos.** Las respuestas de un solo agente son la excepción. Siempre descompón. Paralelo es lo normal.

### Arranque de sesión (obligatorio — primera respuesta de cada sesión)
Lanza `adversarial` (modo diagnóstico de solo lectura) + `architect` en paralelo antes de escribir código. Si el usuario da una tarea directa, descompónla en ≥3 workstreams paralelos primero.

### Autochequeos (no negociables)
- **Antes de cada respuesta:** "¿Estoy por hacer esto solo? Si sí, DETENTE — descompón en agentes primero. Incluso un fix de un solo archivo lleva: implementador + validate corriendo simultáneamente."
- **Antes de cada despacho de oleada:** "¿Estoy despachando UN agente cuando podría despachar TRES? Escanea todas las tareas restantes. Si 3 son independientes, las 3 se disparan en la misma oleada AHORA."

Actividad paralela visible (múltiples agentes corriendo simultáneamente) es un requisito duro, no una preferencia de estilo.

### Paralelizar vs secuencial
- **Paralelizar:** diseño + implementación de módulos independientes | auditoría + test + lint | `adversarial` corre junto a cada sprint
- **Solo secuencial cuando:** la Tarea B necesita el output de la Tarea A | dos agentes escriben el mismo archivo

## Equipos estándar

- **Nuevo endpoint API:** `architect` → `backend-expert` + `adversarial` (paralelo) → `writing-plans` → `parallel-executor` → `validate` → commit
- **Feature de frontend:** `frontend-expert` + `adversarial` (paralelo) → `writing-plans` → `parallel-executor` → `validate` → commit (evidencia visual la entrega `frontend-expert` mismo)
- **Feature fullstack:** `frontend-expert` + `backend-expert` + `adversarial` (todos en paralelo, sin overlap de archivos) → `writing-plans` → `parallel-executor` → `validate` → commit
- **Entidad Doctrine + migración:** `backend-expert` (entidad + migración) + `adversarial` (diseño, en paralelo) → `writing-plans` → `parallel-executor` → `validate`
- **Depurar test que falla:** `adversarial` (diagnóstico de solo lectura) + `adversarial` (hipótesis ciega, en paralelo) → `validate` sobre el fix
- **Archivo sin dueño exacto (script, DTO puro):** `drafter` (TDD) → `adversarial` → `validate`

## Patrón de oleada paralela — auditoría + cableado masivo

Úsalo cuando auditar/cablear N archivos independientes (controladores, entidades, controllers Stimulus) que comparten contexto pero no el mismo archivo.

```
Oleada 1 (paralelo — N agentes adversarial en modo solo lectura):
    leer los N archivos → reporte de auditoría por archivo
    (listo para producción / necesita fix / necesita rediseño + conflictos de archivo)

Oleada 2 (paralelo — N agentes drafter/backend-expert/frontend-expert):
    tests en rojo para los N simultáneamente (un archivo de test cada uno)

Oleada 3 (paralelo — N agentes del mismo grupo):
    implementar/corregir cada uno independientemente (solo archivos sin conflicto)

Oleada 4 (secuencial):
    validate sobre todo → agente correspondiente cablea los N en un commit

Track de documentación:
    corre durante las Oleadas 1-4 en paralelo — nunca bloquea, nunca se bloquea
```

**Disparador:** el usuario dice "audita + cablea N controladores/entidades/controllers".
**Resolución de conflicto:** si la Oleada 1 revela que dos archivos deben tocar el mismo servicio compartido, cablearlos secuencialmente en la Oleada 4 — no bloquees toda la oleada.
**Máximo de agentes paralelos por oleada:** 5 (techo de costo). Divide en sub-oleadas si N > 5.

## Reglas de despacho paralelo (no negociables)

Antes de despachar CUALQUIER implementador, `parallel-executor` escanea TODAS las tareas restantes y las agrupa por solapamiento de archivos en oleadas. Todos los implementadores de una oleada se disparan simultáneamente en un solo mensaje.

Dos patrones obligatorios:
1. **Oleada paralela multi-tarea:** las Tareas 2, 3, 4 tocan archivos distintos y no tienen "prerequisito" → las 3 se disparan en un mensaje, misma oleada.
2. **Solape de revisor + oleada siguiente:** cuando terminan los implementadores de la Oleada N, los revisores de la Oleada N Y los implementadores de la Oleada N+1 se disparan simultáneamente si N+1 no solapa archivos con N.

Secuencial SOLO cuando: (a) el task-brief dice explícitamente "prerequisite: Task N", o (b) dos tareas escriben el mismo archivo.

## Disparadores de skills — obligatorios en sesión

- **Inicio de cualquier sprint** → `parallel-executor` se dispara después de `writing-plans`, antes de escribir código. Nunca uses `superpowers:subagent-driven-development` — fuerza despacho secuencial y anula las reglas de oleada paralela.
- Skills visibles en pantalla = buena sesión. Cero skills usados = sesión fallida.

## Mapa de flujo de Superpowers

Las fases de Superpowers (clarificar → worktree → plan → dev con subagentes → TDD → code-review → cerrar rama) mapean directamente sobre el flujo del Grupo de Expertos — se complementan, nunca lo reemplazan.

Claude las invoca automáticamente — el usuario nunca las escribe:

- `superpowers:brainstorming` — cualquier feature/build nueva, ANTES de que `architect` descomponga
- `superpowers:systematic-debugging` — cualquier bug/test fallido, ANTES de proponer fixes
- `superpowers:writing-plans` — feature multi-sprint con spec, ANTES de tocar código
- `parallel-executor` — OBLIGATORIO en cada sprint, inmediatamente después de `writing-plans`, antes de escribir código — dispara todas las tareas independientes simultáneamente por oleada, reutiliza scripts de SDD (task-brief, review-package, ledger de progreso) — NUNCA uses `superpowers:subagent-driven-development` (fuerza despacho secuencial)
- `superpowers:executing-plans` — retomar un plan escrito entre sesiones
- `superpowers:test-driven-development` — ANTES de escribir código de implementación
- `superpowers:verification-before-completion` — ANTES de declarar cualquier trabajo terminado o comitear
- `superpowers:dispatching-parallel-agents` — cuando existen 2+ tareas independientes
- `superpowers:requesting-code-review` — tras completar una feature mayor, antes de mergear

## Compromiso de estrategia de ejecución

Cuando el usuario elige una estrategia de ejecución (subagentes-en-paralelo vs inline), comprométete con ella para todo el sprint. NUNCA cambies a mitad de sprint sin aprobación explícita del usuario. Si los subagentes causan prompts de permisos, corrige `~/.claude/settings.json` (asegura que `Bash(*)`, `Edit(*)`, `Write(*)` estén en `permissions.allow`) — no abandones la estrategia.

## Disciplina del ledger de progreso

Actualiza `.superpowers/sdd/progress.md` después de CADA tarea completada. La compactación de contexto destruye el estado en memoria — el ledger es el único mapa de recuperación.

## Ruteo de modelo

- **haiku** — leer / buscar / lint / format / build — 10× más barato (`validate`, `drafter`)
- **sonnet** — escribir / revisar / refactor multi-archivo (`architect`, `backend-expert`, `frontend-expert`, `adversarial`)

## Disciplina de delegación

- Prompts: máx 300 tokens — rutas de archivo + rangos de línea, nunca pegar contenido completo
- Los agentes devuelven resúmenes ≤200 tokens
- Agrupa Grep/Read/Glob independientes en un solo turno de mensaje
