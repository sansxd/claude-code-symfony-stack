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

## Migración 6.4 → 8.x — Rector
Cuando el usuario pida subir un proyecto de Symfony 6.4 a 8.x, usa Rector antes de tocar código a mano — detecta y reescribe automáticamente los patrones que dependen de algo removido, en vez de que aparezcan como errores en producción:

```bash
composer require --dev rector/rector
vendor/bin/rector process --dry-run   # revisa el diff propuesto antes de aplicar
vendor/bin/rector process              # aplica tras revisar
```

- Usa el set `SymfonyLevelSetList::UP_TO_SYMFONY_64` como punto de partida y súbelo por versiones — nunca saltes directo a un set de Symfony 8 desde 6.4 sin pasar por los intermedios.
- Corre `composer require symfony/symfony ^8.0` recién después de que Rector deje de proponer cambios, no antes — aplicar Rector sobre una versión que aún no está instalada produce diffs incorrectos.
- El diff de Rector se revisa igual que cualquier otro cambio — no lo comitees sin que `adversarial` lo audite ni sin correr la suite de tests completa después.

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

## Doctrine — enums nativos para campos de estado
PHP 8.1+ soporta backed enums; úsalos en vez de constantes de clase (`const STATUS_PENDING = 'pending'`) para cualquier columna de estado/tipo cerrado — Doctrine los mapea de forma nativa:

```php
enum OrderStatus: string
{
    case Pending = 'pending';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';
}

#[ORM\Column(enumType: OrderStatus::class)]
private OrderStatus $status;
```

- No introduzcas esto en una entidad existente que ya usa constantes de clase para el mismo campo sin que el usuario lo pida — es un cambio de esquema (la migración generada altera el tipo de columna), no una limpieza gratuita.
- El enum vive junto al dominio (`src/Enum/` o junto a la entidad), nunca dentro del namespace `Entity` mezclado con las clases Doctrine.

## Security
- `denyAccessUnlessGranted()` o un atributo `#[IsGranted]` en cada ruta que exponga datos que no son públicos.
- Voters (`Voter`) para reglas de autorización que dependen del dueño del recurso — nunca lógica de permisos inline en el controlador.
- CSRF: usa el token integrado de `form_start()`; si el formulario no usa el componente Form, genera y valida el token manualmente con `CsrfTokenManagerInterface`.
- Rate limiting en login y endpoints públicos de API con `symfony/rate-limiter` (`RateLimiterFactory`) — sin esto, un formulario de login o un endpoint público queda expuesto a fuerza bruta sin ninguna fricción. Symfony 6.4+ ya trae throttling de login integrado (`security.yaml` → `login_throttling`); actívalo antes de escribir un limiter manual.

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

## Calidad estática — extensiones PHPStan requeridas
"PHPStan al nivel máximo viable" sin extensiones específicas de Symfony/Doctrine da falsos positivos (no reconoce servicios autowired, tipos de `QueryBuilder`, entidades cargadas por Doctrine) y deja pasar errores reales de tipos en código Doctrine. Instala junto al core:

```bash
composer require --dev phpstan/phpstan phpstan/phpstan-symfony phpstan/phpstan-doctrine phpstan/phpstan-strict-rules
```

- `phpstan-symfony` entiende el contenedor de servicios y el autowiring — sin él, cada inyección de dependencia aparece como tipo desconocido.
- `phpstan-doctrine` entiende `QueryBuilder`, tipos de columna y relaciones — sin él, una query mal tipada pasa el análisis sin aviso.
- `phpstan-strict-rules` sube el nivel de exigencia en comparaciones y tipos — actívalo cuando el proyecto ya esté en nivel `max` sin errores, no antes (introduce reglas nuevas que pueden generar un backlog grande de golpe).
