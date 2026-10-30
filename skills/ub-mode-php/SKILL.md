---
name: ub-mode-php
description: >
  Principios de ub-mode (Uncle Bob) adaptados a PHP/Symfony: First Make it Work,
  Then Make it Right (CRAP < 10, duplicación, mutation testing con Infection),
  Follow Practice. Úsalo cuando el usuario corra /ub-mode-php, /ub-mode, o pida
  "modo Uncle Bob" / "los principios reducidos" al escribir o cambiar código PHP.
---

# ub-mode-php

Adaptación a PHP/Symfony de [unclebob/ub-mode](https://github.com/unclebob/ub-mode).
Las herramientas originales (`crapper`, `dryer`, `mutator`) no soportan PHP; acá se
usan equivalentes del ecosistema. Todo comando largo respeta la regla 6 de `CLAUDE.md`
(`timeout` + `memory_limit`).

Cada cambio sigue, en orden:
* First Make it Work.
* Then Make it Right.
* Follow Practice.

# First Make it Work

## Laziness Protocol

* Una decisión vive en un solo lugar.
* Entrega el cambio más chico que resuelve el problema.

## Foundational Thinking

* Primero la forma de los datos (entidad, DTO, enum), después la lógica.
* Haz primero lo que ayuda a todas las fases siguientes.
* Si un escritor concurrente importaría, no compartas estado.

## TDD

* Escribe el test que falla antes de cambiar el código.
* Míralo fallar por la razón que esperas.
* Haz el cambio más chico que lo pone en verde.
* Si un test honesto no es práctico, no escribas uno malo.

## Redesign From First Principles

* No atornilles un requisito nuevo sobre el diseño viejo.
* Pregunta qué habrías construido si hubiera estado desde el inicio, piénsalo y entrégalo por partes.

## Attack the Premise

* Si dos fixes que comparten una premisa fallan el mismo gate, escribe esa premisa en una oración y cuenta qué actores sostienen el desbalance.
* Elimina esa asignación.
* No empieces otro fix hasta haberlo hecho.

## Subtract Before You Add

* Quita complejidad antes de agregar cualquier cosa.

## Outcome-Oriented Execution

* Apunta al estado final que puedes verificar.
* Un quiebre intermedio se permite si lo planificaste y se puede deshacer.

## Build the Lever

* Si el trabajo no es obvio a simple vista, construye la herramienta que lo hace (comando de consola, script).
* Haz una unidad a mano y luego ajusta la herramienta a esa unidad.

## Architecture

### Model the Domain

* Pon el dominio en una estructura que haga imposibles los estados ilegales (enums, value objects, constructores que validan).
* Mantén un glosario de términos del dominio.
* Si el código ya es claro y local, déjalo.

### Boundary Discipline

* Valida los datos donde entran (Form/Validator, DTO con `#[MapRequestPayload]`, Serializer).
* Adentro, confía en ellos.
* La lógica de negocio va en funciones/servicios puros, no en controllers ni en Twig.

### Type System Discipline

* Haz imposible escribir el valor ilegal (tipos estrictos, `readonly`, enums).
* Parsea la entrada externa una vez, donde entra.
* No silencies a PHPStan: nada de `@phpstan-ignore` ni crecer el baseline para tapar un error nuevo.

### Make Operations Idempotent

* Correrlo dos veces, o después de un crash a medias, termina en el mismo estado (handlers de Messenger, comandos de consola, migraciones de datos).

### Separate Before Serializing Shared State

* Si no necesitan lo mismo mutable, dale a cada uno lo suyo.
* Si lo necesitan, un solo escritor, y que la estructura lo obligue (lock, `#[ORM\Version]`, transacción).

# Then Make it Right

## Fix Root Causes

* Reprodúcelo (idealmente con un test).
* Arregla la causa.
* Un guard que solo esconde el crash no es un fix.

## Sequence work into verifiable units

* Termina una unidad chica y verifícala.
* Después empieza la siguiente.

## Test Behavior, Not Implementation

* El test llama al código como lo hace su usuario y verifica el resultado que ese usuario vería.
* Si el test seguiría pasando aunque todas las funciones no devolvieran nada, bótalo.

## CRAP (reemplaza a `crapper`)

CRAP = *Change Risk Anti-Patterns*: `complejidad² × (1 − cobertura)³ + complejidad`.
Un método complejo y sin tests dispara el puntaje; uno simple o bien cubierto queda bajo.

* Umbral: **CRAP < 10** por método.
* `~/.claude/scripts/crap-gate.sh` lo mide solo en los métodos que tocó la rama (corre los tests relacionados con Xdebug en modo coverage). `validate` lo corre como aviso; acá se trata como tarea: lo que marque se corrige antes de cerrar.

* Baja cada método bajo 10 partiéndolo, testeándolo, o ambos.
* Evalúa si vale la pena reducir un `match`/`switch` largo: a veces es la forma más clara.

## Duplicación (reemplaza a `dryer`)

* `~/.claude/scripts/jscpd-gate.sh` escanea todo `src/` con jscpd y reporta solo los clones que tocan líneas de la rama. `validate` lo corre como aviso; acá se trata como tarea.
* jscpd detecta clones por tokens, no similitud estructural como `dryer`: elimina los que sean la misma decisión repetida (regla "una decisión vive en un solo lugar"). Duplicación accidental entre conceptos distintos (boilerplate de comandos, `use`) puede quedarse.

## Mutation testing (pospuesto)

* Infection (equivalente a `mutator`) queda fuera por ahora: es lento y traerlo a un proyecto requiere un ticket propio. No instalarlo ni correrlo sin que el usuario lo pida.

## Refactoring

* Fija lo que el código hace (tests de caracterización si no hay).
* Cambia la estructura.
* Prueba que el comportamiento no cambió.

# Practice

## Guard the Context Window

* Mantén chico el hilo principal.
* Manda el volumen a subagentes y quédate con el resumen.

## Commit and Push

* Commitea seguido, en commits chicos y ordenados (regla 3 de `CLAUDE.md`).
* Cada commit dice por qué, qué cambió y cómo se probó.
* Push una sola vez, al final de la tarea, de la rama `feature/*`; nunca tras cada commit.
* La promoción sigue el flujo propio del proyecto, nunca un PR ni un push a `main`/`master`. En besrc: `/deploy-dev` (integrate/<TICKET>-develop → PR a `develop`) y `/deploy-qa` (integrate/<TICKET>-release → PR a `release/X.Y.Z`); `main` solo recibe la release.
