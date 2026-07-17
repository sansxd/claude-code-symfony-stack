# Convenciones Symfony 6.4/8 · PHP 8.3/8.4 · Doctrine

**Alcance de la regla:** se carga bajo demanda al tocar `src/Controller/**`, `src/Entity/**`, `src/Service/**`, `migrations/**`.

## Detección de versión — primer paso, siempre
Antes de escribir un patrón, confirma con qué versión real trabaja el proyecto:

```bash
composer show symfony/framework-bundle | grep versions
php -v
```

Este repo de agentes soporta **dos líneas de Symfony simultáneamente**:

| | Symfony 6.4 (LTS) | Symfony 8.x |
|---|---|---|
| PHP mínimo | 8.1 (proyecto usa 8.3) | **8.4 obligatorio** |
| Deprecaciones de 7.x | presentes, aún funcionan | **eliminadas** — código que dependía de ellas rompe |
| Componentes nuevos | — | `JsonStreamer`, `JsonPath`, `ObjectMapper` |
| Seguridad por defecto | configuración estándar 6.4 | defaults más estrictos ("secure by default") |

**Regla dura:** si `composer.json` fija `symfony/framework-bundle: "8.*"` pero el entorno corre PHP 8.3, es un error de configuración del proyecto, no algo que se deba silenciar — repórtalo antes de continuar, no lo evadas bajando la versión de Symfony por tu cuenta.

Nunca asumas features de Symfony 8 (`ObjectMapper`, `JsonStreamer`, `JsonPath`) en un proyecto 6.4 — no existen ahí. Nunca reintroduzcas un patrón deprecado de 7.x en un proyecto 8.x — ya fue removido.

## Atributos, no anotaciones
Ambas versiones usan atributos nativos: `#[Route(...)]`, `#[ORM\Entity]`, `#[AsEventListener]`, `#[AsMessageHandler]`. Nunca vuelvas a las anotaciones de doc-comment estilo Symfony 4. En Symfony 8 los atributos se extienden también a comandos de consola y extensiones Twig con sintaxis más expresiva — revisa la implementación existente en el proyecto antes de asumir la forma exacta.

## Doctrine — migraciones
- `doctrine:migrations:diff` genera la migración a partir del mapeo de entidades. **Nunca editar a mano una migración ya aplicada en cualquier entorno** — genera una nueva migración correctiva.
- `doctrine:migrations:migrate` en local antes de comitear, para confirmar que la migración generada corre limpia.
- Nombres de columna e índices explícitos cuando el nombre autogenerado supere el límite de la base (MySQL: 64 caracteres).

## Doctrine — evitar N+1
- `JOIN` explícito en DQL o `fetch: EAGER` puntual en la relación cuando se sabe que siempre se necesita el dato asociado.
- `Repository` con métodos nombrados por intención (`findActiveOrdersForUser`), nunca `QueryBuilder` disperso por controladores.

## Doctrine — nunca concatenar en DQL/QueryBuilder
```php
// MAL — inyección DQL
$qb->andWhere("o.status = '$status'");

// BIEN — parámetro ligado
$qb->andWhere('o.status = :status')->setParameter('status', $status);
```

## Security
- `denyAccessUnlessGranted()` o un atributo `#[IsGranted]` en cada ruta que exponga datos que no son públicos.
- Voters (`Voter`) para reglas de autorización que dependen del dueño del recurso — nunca lógica de permisos inline en el controlador.
- CSRF: usa el token integrado de `form_start()`; si el formulario no usa el componente Form, genera y valida el token manualmente con `CsrfTokenManagerInterface`.

## Serialización — nunca exponer la entidad cruda
Usa `Serializer` con grupos (`#[Groups(['order:read'])]`) o DTOs explícitos de respuesta. Exponer una entidad Doctrine directamente en un endpoint JSON filtra campos internos (contraseñas hasheadas, relaciones no pensadas para el cliente) por defecto.

**Solo en Symfony 8.x:** si el proyecto ya usa `ObjectMapper` para mapear Entity→DTO o `JsonStreamer`/`JsonPath` para payloads grandes, sigue ese patrón existente en vez de volver al `Serializer` clásico — pero no los introduzcas en un proyecto que aún no los usa sin que el usuario lo pida; no son drop-in en 6.4 (no existen ahí).

## Messenger
- Handlers (`#[AsMessageHandler]`) idempotentes — un mensaje puede reintentarse.
- Mensajes son DTOs inmutables (`readonly class`), nunca entidades Doctrine pasadas por referencia a la cola.

## Consola
- `bin/console make:command` para scaffolding — nunca escribir el boilerplate de `Command` a mano.
- Comandos con una sola responsabilidad; lógica real vive en un servicio inyectado, el comando solo orquesta I/O.

## Secretos
- `.env.local` para secretos locales (nunca comiteado). En producción, Symfony Secrets Vault (`bin/console secrets:set NOMBRE`) sobre variables de entorno planas cuando el proyecto ya lo usa.
