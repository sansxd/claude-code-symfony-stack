# Reporte de Estado de Sprint

**Alcance:** referencia del skill `sprint-workflow` — se lee al imprimir un árbol de estado de sprint.

## Regla
Todo sprint tiene dos vistas de estado:

- **Árbol completo** — al inicio (antes de lanzar la primera oleada, muestra el plan) y al cierre del sprint.
- **Línea compacta** — después de cada oleada completada y cuando el usuario pide el estado a mitad de sprint. Si una oleada termina con ❌ o aparece una decisión ❓ nueva, se imprime el árbol completo en vez de la línea.

## Árbol completo

```
😸 Sprint N — TICKET-123 · objetivo de la entrega · 2/6
├── 🤖 agentes    — 2 en paralelo (backend-expert·frontend-expert)
├── 🧠 skills     — sprint-workflow → writing-plans → parallel-executor
├── 📊 métricas   — tests 412→418 · PHPStan 0 · cs ✅ · build ✅
├── ❓ decisiones — default de `active` · ¿migrar antes del dump?
│
├── 🌊 Oleada 1
│   ├── 🐘 Entity + migración — campo active                 [a1b2c3d]
│   └── 🐘 Repository — filtro por active                    [e4f5g6h]
├── 🌊 Oleada 2
│   ├── 🔄🐘 Service + API — rechaza inactivos  [backend-expert · 3 arch]
│   ├── 🔄🍃 listado.html.twig — badge inactivo [frontend-expert · 2 arch]
│   └── ❌🐘 Command de backfill — PHPStan: 3 errores      [backend-expert]
├── 🌊 Oleada 3
│   └── ⏳🐘 Listener de caché — invalidar menú            [backend-expert]
│
└── 🔒 adversarial — revisión del diff al cierre
```

### Encabezado
`😸 Sprint N — <ticket> · <objetivo> · <hechas>/<total>`. El ticket va siempre (usa `—` si no hay). El contador cuenta tareas, no archivos; `🔒 adversarial` no entra en el total.

### Filas de metadata (siempre presentes, en este orden)
1. **🤖 agentes** — cuántos corriendo ahora y cuáles. `0` si no hay ninguno.
2. **🧠 skills** — skills disparados en el sprint, en orden.
3. **📊 métricas** — formato fijo: `tests <antes>→<después> · PHPStan <errores> · cs ✅|❌ · build ✅|❌`. Antes de tomar la línea base: `tests —`. Omite `build` si el proyecto no compila assets.
4. **❓ decisiones** — lo que espera respuesta del usuario, separado por `·`. Sin pendientes: `—`.

Las etiquetas van alineadas al mismo ancho de columna (padding tras el emoji hasta el `—`). Una línea `│` en blanco separa la metadata de las oleadas.

### Filas de tarea
- **Una fila por tarea del plan, no por archivo.** La tarea se nombra por lo que toca y lo que hace (≤50 caracteres antes del sufijo).
- **Agrupadas bajo `🌊 Oleada N`**, en el orden en que corren. Sprint de una sola oleada: igual lleva el encabezado `🌊 Oleada 1`.
- **Sufijo entre corchetes, alineado a la derecha:**
  - `⏳` / `🔄` / `❌` → `[agente · N arch]` (omite `N arch` si es 1 archivo)
  - completada → `[hash corto del commit]`
- **❌ lleva el motivo** tras el `—`, en vez de la descripción: `— PHPStan: 3 errores`, `— test rojo: testRejectsInactive`, `— bloqueado: permisos de Bash`.

## Leyenda de emoji

| Emoji | Significado |
|---|---|
| 😸 | encabezado — uno solo por árbol, en ningún otro lugar |
| ⏳ | pendiente — aún no arranca (oleada futura o esperando una decisión) |
| 🔄 | en progreso — hay un agente trabajando en ella ahora |
| ❌ | fallida / bloqueada — siempre con el motivo |
| ✅ | completada (solo en tareas sin emoji de dominio) |
| ❓ | decisión pendiente del usuario (solo en la fila de metadata) |
| 🌊 | encabezado de oleada |
| 🔒 | revisión adversarial — siempre la última fila |

**Emoji de dominio** según lo que toca la tarea: 🐘 PHP (backend), 🍃 Twig, ⚡ JS. Si la tarea cruza dominios, usa el del archivo principal. Tareas de otro tipo (CSS, YAML, config) no llevan emoji de dominio y usan ✅ al completarse.

- Completada: el emoji de dominio **reemplaza** a ✅ (`🐘`, no `✅🐘`).
- Pendiente / en progreso / fallida: se combina pegado, sin espacio (`⏳🐘`, `🔄🍃`, `❌⚡`).

`🔄` es solo para tareas con un agente corriendo. Si el sprint está detenido (`🤖 agentes — 0`), ninguna fila puede estar en `🔄`.

## Línea compacta

```
😸 S1 · TICKET-123 · 3/6 · O2 🔄 2 agentes · ❌1 · ❓1 · tests 412→416
```

Campos en orden: sprint, ticket, progreso, oleada actual y su estado, fallidas (`❌N`), decisiones pendientes (`❓N`), delta de tests. Omite `❌`/`❓` si están en 0.

## Reglas
- Imprime el árbol completo ANTES de lanzar la primera oleada y al cerrar el sprint; entre oleadas, la línea compacta.
- Las filas 🤖 / 🧠 / 📊 / ❓ siempre están; usa `—` si aún no se sabe.
- Una fila por tarea; el estado sale de la realidad (agente vivo → 🔄; sin agente → ⏳), nunca del plan.
- Tarea completada sin commit todavía: usa `[sin commit]` — señal de que falta comitear.
- `adversarial` siempre tiene su propia fila 🔒 al final.
