---
name: symfony-upgrade
description: "Subir la versión de Symfony de un proyecto (minor 8.0→8.1, o major 6.4→7.x/8.x), o corregir advisories de composer audit que exigen subir Symfony. Úsalo cuando el usuario diga 'actualiza Symfony', 'sube a 8.1', 'arregla las vulnerabilidades de composer audit' o similar. Flujo con línea base, dry-run revisado, comparación antes/después y commit único."
---

# Upgrade de Symfony — línea base, dry-run, comparar

Objetivo: que el upgrade sea verificable. Todo se mide **antes y después**; si algo empeora, se reporta en vez de ocultarlo.

## 0. Precondiciones
- Working tree limpio (`git status --short` vacío) y rama base al día (`develop` o la que use el proyecto).
- Detecta versión actual: `jq -r '.packages[]|select(.name=="symfony/framework-bundle")|.version' composer.lock`.
- **Major (ej. 6.4 → 7/8):** antes de tocar constraints, deja la app sin deprecations (`php bin/phpunit --display-deprecations`) y corre Rector con los sets de Symfony en `--dry-run` (ver `rules/php/symfony.md`, sección Rector). Recién después sigue con el paso 1.
- **Minor (ej. 8.0 → 8.1):** sigue directo.

## 1. Rama
`fix/symfony-<X.Y>-<motivo>` si es por seguridad, `feature/symfony-<X.Y>` si no. Nunca en `main`/`master`/`develop` directo.

## 2. Línea base (guardar en el scratchpad)
Corre en paralelo y guarda la salida:
```bash
composer audit                                   # advisories actuales
php bin/phpunit --colors=never                   # conteo de tests/notices
vendor/bin/phpstan analyse --no-progress --error-format=raw --memory-limit=2G
```
Si el proyecto no tiene PHPStan o tests, anótalo — se reporta como "sin red de seguridad".

## 3. Subir constraints
- Todos los `symfony/*` con `"X.Y.*"` en `require` y `require-dev` → nueva versión.
- `extra.symfony.require` → misma versión (si no, Flex sigue bloqueando la anterior).
- No tocar los que usan `^` (flex, ux-*, monolog-bundle, maker): se resuelven solos.

## 4. Dry-run y revisión del diff
```bash
composer update 'symfony/*' --with-all-dependencies --dry-run --no-interaction
```
Revisa la lista y separa:
- `symfony/*` a la versión objetivo → esperado.
- Dependencias **no-Symfony** que suben (doctrine, monolog, twig, polyfills) → listar.
- Cualquier **major** de un paquete no-Symfony, o un paquete que se **elimina** → detenerse y mostrarlo al usuario antes de aplicar.

## 5. Aplicar
```bash
composer update 'symfony/*' --with-all-dependencies --no-interaction
```
Si Composer hace "bump" de constraints `^` en `composer.json` (config `bump-after-update`), es esperado — mencionarlo.

## 6. Comparar antes/después
| Verificación | Criterio |
|---|---|
| `composer audit` | sin los advisories que motivaron el upgrade |
| PHPUnit | mismo conteo de tests, 0 fallos nuevos, sin deprecations nuevas (`--display-deprecations`) |
| PHPStan | mismo número de errores o menos; diff de errores ordenados si cambia |
| `lint:container`, `lint:twig templates`, `lint:yaml config` | rc=0 |
| `php bin/console about` | arranca y muestra la versión nueva |

Si la app usa Mate, compara también errores del log de `test` entre la corrida base y la nueva (deben ser los mismos, generados por los tests).

## 7. Recetas
`composer recipes -o` → **solo listar** las que tienen update. No aplicarlas en este cambio: tocan `config/` y merecen su propia tarea.

## 8. Commit único
Incluye `composer.json`, `composer.lock` y archivos regenerados por el framework (ej. `config/reference.php`). Mensaje: motivo (CVE/advisory si aplica), versiones, bumps no-Symfony relevantes y la tabla de verificación resumida.

## 9. Otras ramas que tocan composer.lock
Si hay ramas abiertas que también modifican `composer.lock`, mergear el upgrade primero y, en esas ramas, **rehacer** el `composer require` sobre la base nueva en vez de resolver el conflicto del lock a mano.

## Reporte final
Tabla antes/después del paso 6, lista de bumps no-Symfony, recetas pendientes y cualquier cosa que haya empeorado.
