---
paths:
  - "migrations/**"
  - "src/Message/**"
  - "src/MessageHandler/**"
  - "src/**/Message/**"
  - "src/**/MessageHandler/**"
  - "config/packages/messenger.yaml"
---

# Checklist de revisión — Migraciones Doctrine y Messenger

**Alcance de la regla:** se carga bajo demanda al tocar migraciones, mensajes, handlers o la configuración de Messenger. Complementa (no repite) las secciones "Doctrine — migraciones" y "Messenger" de `symfony.md`. Base: checklists de `efficience-it/claude-skills-php`, adaptados a MySQL 8 y a estas convenciones.

Úsalo al **generar o revisar** una migración o un cambio de Messenger: recorre la lista y reporta cada hallazgo con severidad (bloqueante / importante), archivo y la corrección propuesta. No es para auditar el repo completo por cuenta propia.

## Migraciones — pérdida de datos (bloqueante)
- `DROP TABLE` / `DROP COLUMN` sin que los datos se hayan migrado antes o sin confirmación de que se pueden perder.
- Cambio de tipo que trunca: `VARCHAR(255)` → `VARCHAR(50)`, `TEXT` → `VARCHAR`, `DATETIME` → `DATE`, `INT` → `SMALLINT`. Verificar el largo/rango real de los datos antes (`SELECT MAX(CHAR_LENGTH(col))`).
- `TRUNCATE` o `DELETE` sin `WHERE` dentro de una migración.
- Agregar un índice `UNIQUE` sobre una columna con datos existentes sin revisar duplicados primero — la migración falla a mitad de camino en el servidor.

## Migraciones — MySQL no es transaccional en DDL (bloqueante)
- En MySQL cada `ALTER`/`CREATE`/`DROP` hace commit implícito: si una migración con varias sentencias falla en la tercera, las dos primeras **quedan aplicadas** y la versión no se registra. Re-correrla falla por "column already exists".
- Por eso: una migración con DDL + `UPDATE` de datos debe poder re-ejecutarse o estar partida en migraciones separadas; nunca mezclar un `UPDATE` riesgoso con DDL que no se puede repetir.

## Migraciones — coherencia `up()` / `down()` (importante)
- `down()` vacío o con `throw` sin justificación cuando el cambio sí es reversible.
- `down()` que no es el inverso exacto de `up()` (índices, FKs, defaults, nullabilidad).
- `down()` que recrea una columna borrada sin poder restaurar sus datos — en ese caso dejarlo explícito con `$this->throwIrreversibleMigrationException()` en vez de fingir reversibilidad.

## Migraciones — compatibilidad con el código desplegado (importante)
Entre que corre la migración y que el código nuevo queda activo (y en los workers de larga vida, hasta que se reinician), el código viejo sigue ejecutándose contra el esquema nuevo:
- Renombrar una columna o tabla rompe el código viejo → preferir agregar la nueva, escribir en ambas, migrar datos y borrar la vieja en un deploy posterior.
- `ADD COLUMN ... NOT NULL` sin `DEFAULT` en una tabla con filas falla o rompe los `INSERT` del código viejo.
- Borrar una columna que el código (o una consulta DBAL/SQL crudo) todavía referencia.
- Tras un cambio de esquema que afecte a entidades usadas por handlers: reiniciar los workers de Messenger (tienen el mapeo Doctrine viejo en memoria).

## Migraciones — rendimiento en MySQL 8 (importante)
- `ALTER TABLE` sobre tablas grandes: preferir operaciones `INSTANT`/`INPLACE` (agregar columna nullable o con default, agregar índice) sobre las que copian la tabla (cambiar tipo de columna, cambiar charset, borrar PK). Si la operación copia la tabla, avisarlo con estimación de filas.
- Varios `ALTER TABLE` sobre la misma tabla → agruparlos en uno solo (cada uno puede reconstruir la tabla).
- `UPDATE` masivo de datos: por lotes o con `WHERE` acotado; nunca un `UPDATE` sin límite sobre una tabla de millones de filas dentro de la migración.

## Migraciones — proceso
- Cambios **solo de datos** (sin cambio de esquema): el usuario prefiere un `UPDATE` manual entregado aparte, no un archivo de migración — preguntar antes de crear la migración.
- Al pasar a dev/QA/prod, nombrar el archivo de migración explícitamente en el comentario de PR/Jira.
- Fuera de local, `doctrine:migrations:migrate` solo con confirmación explícita (regla 11 de CLAUDE.md).

## Messenger — routing (bloqueante)
- Mensaje despachado sin entrada en `routing:` → se procesa **síncrono en el request** sin aviso. Todo mensaje nuevo pensado como async necesita su línea en `routing`.
- Mensaje enrutado a un transport que no existe en `transports:`.
- Mensaje sin handler (`#[AsMessageHandler]`) o handler para un mensaje que ya no se despacha. Verificar con `bin/console debug:messenger`.
- Transport nuevo → también necesita su proceso consumidor (programa de Supervisor o equivalente) en cada entorno; sin eso los mensajes se acumulan en la cola sin error visible.

## Messenger — retry y failure (importante)
- Transport async sin `retry_strategy` explícita → usa el default (3 reintentos); confirmar que tiene sentido para ese mensaje.
- `max_retries: 0` es válido cuando reintentar no tiene sentido o es costoso (exportaciones pesadas, notificaciones que pierden vigencia), pero debe llevar un comentario que explique por qué.
- `failure_transport` definido y revisado: un mensaje que agota los reintentos sin failure transport se pierde.
- Reintentar debe ser seguro: handler idempotente (ver `symfony.md`) o con guard explícito si el mensaje puede llegar duplicado.

## Messenger — handlers (importante)
- `$em->flush()` dentro de un loop → acumular y hacer `flush()` por lotes, con `$em->clear()` cada N iteraciones en procesos largos para no crecer en memoria.
- Llamadas HTTP a terceros sin `timeout` explícito — bloquean al worker indefinidamente.
- Handler con lógica de negocio larga inline → delegar a un servicio; el handler solo traduce el mensaje a la llamada.
- El mensaje carga IDs, no entidades; el handler vuelve a buscar la entidad y maneja el caso de que ya no exista (borrada entre el dispatch y el consumo).
- Errores no recuperables (dato inválido, entidad inexistente) → `UnrecoverableMessageHandlingException` para no gastar reintentos.

## Messenger — serialización
- Transport compartido con otra aplicación (otro lenguaje u otro código) → serializer explícito (JSON), nunca el `PhpSerializer` por defecto.
- Cambiar la firma de un mensaje (renombrar/borrar propiedades) con mensajes viejos todavía en la cola rompe su deserialización → drenar la cola antes del deploy o mantener compatibilidad.
