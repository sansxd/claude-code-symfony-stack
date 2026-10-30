---
name: sprint-workflow
description: "Equipos de expertos y patrones de oleadas paralelas para sprints. Úsalo cuando la tarea toca 3+ archivos, cruza backend y frontend (PHP + Twig/JS) o requiere decisiones de diseño (endpoint/entidad nueva, cambio de contrato), una auditoría + cableado de N archivos, o cuando el usuario diga 'inicia el sprint' / 'implementa el plan'. NO lo uses para preguntas, explicaciones, cambios de config ni fixes de 1-2 archivos."
---

# Equipos de Trabajo Estándar + Patrones de Oleadas Paralelas

Este skill aplica solo a tareas complejas (criterio en la regla 1 de `~/CLAUDE.md`: 3+ archivos, backend + frontend, o decisiones de diseño). El árbol de estado de sprint está en `sprint-status.md` junto a este archivo — léelo antes de imprimir el primer árbol.

## Agentes en paralelo — Grupo de Expertos

- **Tamaño del equipo según la tarea:** tantos agentes como workstreams independientes haya — típico 3-5, máximo 8 simultáneos. No inventes workstreams para llegar a un número.
- **Arranque del sprint:** `architect` descompone + `adversarial` ataca el diseño (en paralelo) antes de escribir código.
- **Antes de cada despacho de oleada:** escanea todas las tareas restantes; si varias son independientes, se disparan en la misma oleada.

### Paralelizar vs secuencial
- **Paralelizar:** diseño + implementación de módulos independientes | auditoría + test + lint | `adversarial` corre junto a cada sprint
- **Secuencial cuando:** la Tarea B necesita el output de la Tarea A | dos agentes escriben el mismo archivo | refactors que tocan archivos compartidos (renombres, mover namespaces) — ahí usa secuencial o un worktree por agente

## Equipos estándar

- **Nuevo endpoint API:** `architect` → `backend-expert` + `adversarial` (paralelo) → `writing-plans` → `parallel-executor` → `validate` → commit
- **Feature de frontend:** `frontend-expert` + `adversarial` (paralelo) → `writing-plans` → `parallel-executor` → `validate` → commit (evidencia visual la entrega `frontend-expert` mismo)
- **Feature fullstack:** `frontend-expert` + `backend-expert` + `adversarial` (todos en paralelo, sin overlap de archivos) → `writing-plans` → `parallel-executor` → `validate` → commit
- **Entidad Doctrine + migración:** `backend-expert` (entidad + migración) + `adversarial` (diseño, en paralelo) → `writing-plans` → `parallel-executor` → `validate`
- **Depurar test que falla (no obvio):** `adversarial` (diagnóstico de solo lectura) + `adversarial` (hipótesis ciega, en paralelo) → `validate` sobre el fix
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

## Reglas de despacho paralelo

Antes de despachar CUALQUIER implementador, `parallel-executor` escanea TODAS las tareas restantes y las agrupa por solapamiento de archivos en oleadas. Todos los implementadores de una oleada se disparan simultáneamente en un solo mensaje.

Dos patrones obligatorios:
1. **Oleada paralela multi-tarea:** las Tareas 2, 3, 4 tocan archivos distintos y no tienen "prerequisito" → las 3 se disparan en un mensaje, misma oleada.
2. **Solape de revisor + oleada siguiente:** cuando terminan los implementadores de la Oleada N, los revisores de la Oleada N Y los implementadores de la Oleada N+1 se disparan simultáneamente si N+1 no solapa archivos con N.

Secuencial SOLO cuando: (a) el task-brief dice explícitamente "prerequisite: Task N", o (b) dos tareas escriben el mismo archivo.

## Skills de Superpowers en un sprint

Las fases de Superpowers (clarificar → worktree → plan → dev con subagentes → TDD → code-review → cerrar rama) mapean sobre el flujo del Grupo de Expertos. Úsalas cuando aportan, no como checklist ceremonial:

- `superpowers:brainstorming` — feature nueva con requisitos poco claros, ANTES de que `architect` descomponga
- `superpowers:writing-plans` — feature multi-sprint con spec, ANTES de tocar código
- `parallel-executor` — inmediatamente después de `writing-plans`, antes de escribir código. NUNCA uses `superpowers:subagent-driven-development` (fuerza despacho secuencial)
- `superpowers:executing-plans` — retomar un plan escrito entre sesiones
- `superpowers:test-driven-development` — ANTES de escribir código de implementación
- `superpowers:verification-before-completion` — ANTES de declarar el sprint terminado o comitear
- `superpowers:requesting-code-review` — tras completar una feature mayor, antes de mergear

## Compromiso de estrategia de ejecución

Cuando el usuario elige una estrategia de ejecución (subagentes-en-paralelo vs inline), comprométete con ella para todo el sprint. NUNCA cambies a mitad de sprint sin aprobación explícita del usuario. Si los subagentes causan prompts de permisos, corrige `~/.claude/settings.json` (asegura que `Bash(*)`, `Edit(*)`, `Write(*)` estén en `permissions.allow`) — no abandones la estrategia.

## Disciplina del ledger de progreso

Actualiza `.superpowers/sdd/progress.md` después de CADA tarea completada. La compactación de contexto destruye el estado en memoria — el ledger es el único mapa de recuperación.

## Ruteo de modelo

- **haiku** — leer / buscar / lint / format / build — 10× más barato (`validate`, `drafter`)
- **sonnet** — escribir / refactor multi-archivo (`backend-expert`, `frontend-expert`)
- **opus** — diseño y revisión, donde un error se propaga o pasa sin detectar (`architect`, `adversarial`)

## Disciplina de delegación

- Prompts: máx 300 tokens — rutas de archivo + rangos de línea, nunca pegar contenido completo
- Los agentes devuelven resúmenes ≤200 tokens
- Agrupa Grep/Read/Glob independientes en un solo turno de mensaje
