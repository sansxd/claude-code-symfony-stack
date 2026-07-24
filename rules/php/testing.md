# Convenciones de Testing — PHPUnit / Symfony

**Alcance de la regla:** se carga bajo demanda al tocar `tests/**` o al escribir un test nuevo.

## TDD — rojo antes que verde, siempre
Escribe el test que falla ANTES que la implementación. Un test escrito después de la implementación no cuenta como TDD y debe rehacerse si el sprint lo exige.

## WebTestCase — aislamiento de base de datos
- Cada test funcional (`WebTestCase`) corre dentro de una transacción que se revierte al final (vía `DAMADoctrineTestBundle` o un `ORMPurger` manual en `setUp`/`tearDown`). Sin esto, los tests se contaminan entre sí en el orden en que corren.
- Nunca reutilices el `EntityManager` de un test anterior sin resetear su estado — Doctrine cachea entidades por identidad y un test puede leer datos "fantasma" de otro.

## Nombres de clase únicos
Cada archivo de test tiene una clase con nombre único en todo el proyecto — PHPUnit no tolera clases duplicadas entre archivos aunque estén en namespaces distintos si el autoload las colisiona.

## Fixtures
- `DoctrineFixturesBundle` o Foundry para datos de prueba reproducibles — nunca `INSERT` manual en el test.
- Fixtures declaran dependencias explícitas entre sí (`DependentFixtureInterface`) en vez de asumir orden de carga.

## Mocks vs base de datos real
- Unit tests (`TestCase` simple): mockea dependencias con `createMock()`.
- Tests funcionales (`WebTestCase`): usa una base de datos real de test (`APP_ENV=test`), nunca mockees el `EntityManager` — un mock que pasa puede ocultar una migración rota que solo aparece contra una base real.

## Cobertura de rutas sensibles
Toda ruta protegida por un Voter o `#[IsGranted]` tiene al menos un test que confirma el 403 para un usuario sin permiso, no solo el 200 para el usuario correcto.

## Mutation testing — Infection en modo PR-diff
Coverage mide qué líneas se ejecutan, no si el test afirma algo real sobre su comportamiento. Infection inyecta bugs deliberados ("mutantes") en el código y corre la suite contra cada uno — si ningún test falla, el mutante "escapó" y ese código está cubierto en apariencia pero no verificado.

**Nunca correr full-project en cada push** — es lento (horas en un codebase grande). El modo diff solo muta el código fuente que cambió en el PR respecto a la rama base:

```bash
composer require --dev infection/infection
```

```bash
# CI — solo sobre el diff del PR
git fetch origin main --depth=50
vendor/bin/infection \
  --git-diff-filter=AM \
  --git-diff-base=origin/main \
  --min-msi=80 --min-covered-msi=95 \
  --threads=8 --only-covered
```

- `--git-diff-filter=AM` — muta solo archivos **A**ñadidos/**M**odificados en el diff, no el proyecto completo.
- `--only-covered` — no penaliza líneas sin ningún test (eso ya lo atrapa el gate de coverage; aquí solo importa si el test que sí cubre esa línea afirma algo real).
- `--min-msi` / `--min-covered-msi` — el build falla si el score baja del umbral. Arranca en `min-msi=60-70` sobre código legacy sin tocar; sube a `80-90` para código nuevo o crítico (Voters, servicios de dominio, cálculo de precios). `min-covered-msi` siempre más alto (90-95) porque ya excluye el ruido de código sin cobertura.
- El fetch necesita profundidad suficiente (`--depth=50` o `fetch-depth: 0` en GitHub Actions) — sin el historial de la rama base, Infection no puede calcular el diff.

**Triage de mutantes escapados:**
- Escapó en un Voter, cálculo de negocio o validación de seguridad → corrige el test, es un hueco real.
- Escapó en un getter/setter trivial o un DTO sin lógica → ignóralo vía `ignoreSourceCodeMutatorsMap` en `infection.json5`, no persigas el 100% MSI a ciegas — infla el tiempo de CI sin mejorar la calidad real de los tests.
