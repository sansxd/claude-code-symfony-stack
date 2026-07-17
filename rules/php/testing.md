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
