# Reporte de Estado de Sprint

**Alcance de la regla:** se carga bajo demanda cuando una sesión está por imprimir un árbol de estado de sprint.

## Regla
Todo sprint recibe un árbol de estado — siempre, antes de lanzar agentes y después de cada oleada completada.

## Formato

```
😸 Sprint N — activo
├── 🤖 agentes   — N en paralelo (agente1·agente2·agente3·...)
├── 🧠 skills    — skill1 → skill2 → skill3
├── 📊 métricas  — tests X→Y · PHPStan 0 errores · build ✅
│
├── ✅🐘 archivo.php      — resumen de una línea de lo hecho
├── 🔄 agente_pendiente  — descripción breve de la tarea
└── 🔒 adversarial       — alcance de la revisión de seguridad final
```

Las tres etiquetas de metadata (`agentes`/`skills`/`métricas`) van alineadas al mismo ancho de columna (9 caracteres tras el emoji, incluido el espacio antes de `—`). La línea `│` en blanco separa la metadata del sprint de las filas de trabajo (archivos/agentes) — no lleva emoji ni texto.

En filas de archivo, si la ruta termina en `.php` se añade `🐘` (elePHPant) inmediatamente después del emoji de estado, sin espacio entre ambos: `✅🐘`, `🔄🐘`, `❌🐘`. Archivos que no son `.php` (Twig, JS, CSS, YAML, etc.) usan solo el emoji de estado, sin `🐘`.

## Orden de filas (fijo — siempre en esta secuencia)

1. **🤖 agentes** — cuántos corriendo y cuáles (señal en tiempo real)
2. **🧠 skills** — skills de Superpowers disparados en este sprint, en orden
3. **📊 métricas** — delta de tests (antes → después), errores de PHPStan, estado del build
4. **✅ / 🔄 / ❌** — una fila por archivo o agente trabajado
5. **🔒 adversarial** — siempre al final

## Leyenda de emoji

- **😸** — solo el encabezado (UNO por árbol de sprint, en ningún otro lugar)
- **✅** — completado
- **🔄** — en progreso / esperando
- **❌** — fallido / bloqueado
- **🔒** — revisión adversarial de seguridad (siempre la última fila)
- **🐘** — marca archivos `.php` (elePHPant); se pega sin espacio al emoji de estado, nunca aparece solo

## Reglas

- Imprime el árbol ANTES de lanzar agentes (muestra el plan — la fila de métricas muestra la línea base)
- Reconstruye el árbol después de cada oleada completada (la fila de métricas se actualiza con deltas)
- UN solo 😸 en el encabezado del sprint — el resto usa ✅ / 🔄 / ❌ / 🔒
- Las filas 🤖 / 🧠 / 📊 siempre presentes — usa "—" si aún no se sabe
- Alinea las etiquetas `agentes`/`skills`/`métricas` a la misma columna (padding tras el emoji) y separa metadata de filas de trabajo con una línea `│` en blanco
- Archivos `.php` llevan `🐘` pegado al emoji de estado (`✅🐘`/`🔄🐘`/`❌🐘`) — el resto de extensiones no lo usa
- Una línea por agente/archivo, descripción ≤50 caracteres
- `adversarial` siempre tiene su propia fila 🔒 al final
