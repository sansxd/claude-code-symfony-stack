# Grupo de Expertos — Roster Symfony/PHP/Twig/JS

Roster enfocado exclusivamente en el stack **Symfony 6.4/8.x · PHP 8.3/8.4 · Twig · JavaScript** — 6 agentes, todos de ámbito PHP.

**Soporte dual de versión:** `backend-expert` detecta con `composer show symfony/framework-bundle` si el proyecto corre 6.4 (LTS, PHP 8.3+) u 8.x (PHP 8.4 obligatorio, deprecaciones de 7.x removidas, componentes nuevos `ObjectMapper`/`JsonStreamer`/`JsonPath`). Detalle completo en `~/.claude/rules/php/symfony.md`.

## Roster (6 expertos)

| Agente | Modelo | maxTurns | Dominio |
|---|---|---|---|
| **architect** | sonnet | 12 | Orquestación, descomposición en task-briefs, ruteo — nunca código |
| **backend-expert** | sonnet | 20 | Controladores, servicios, Doctrine ORM/DBAL, Security, Messenger, consola |
| **frontend-expert** | sonnet | 20 | Twig, Symfony UX (Stimulus/Turbo/Live Components), Webpack Encore/AssetMapper, JS, CSS |
| **adversarial** | sonnet | 20 | Ataque de diseño, OWASP + secretos, diagnóstico de solo lectura |
| **validate** | haiku | 8 | Gate PHPStan/PHP-CS-Fixer/PHPUnit/lint antes de commit |
| **drafter** | haiku | 15 | Implementador de respaldo, TDD en archivos sin dueño de dominio exacto |

## Descripciones

### architect
Orquestador del Grupo de Expertos. Descompone el trabajo en task-briefs seguros para DAG, rutea al experto correcto, nunca escribe código de implementación. Úsalo cuando la tarea toque 2+ archivos o capas.

### backend-expert
Symfony 6.4 / PHP 8.3 — controladores, servicios, Doctrine ORM/DBAL, Security (voters/firewalls), Messenger, Forms/Validator, comandos de consola.

### frontend-expert
Twig, Symfony UX (Stimulus + Turbo + Live Components), Webpack Encore o AssetMapper (el que el proyecto ya use), JavaScript vanilla, CSS. Dueño de toda evidencia visual de cierre de sprint. En Live Components, la lógica de negocio se delega a `backend-expert` — el componente solo consume servicios.

### adversarial
Revisor adversarial — ataca cada decisión de diseño, corre escaneo OWASP + secretos, diagnóstico de solo lectura. Úsalo después de que `architect` diseña, antes de codear, y después de cada commit.

### validate
Gate mecánico de validación pre-commit: `composer validate`, `lint:yaml`, `lint:twig`, `lint:container`, PHPStan, PHP-CS-Fixer, PHPUnit, build de assets. Bloquea en el primer fallo.

### drafter
Implementador de respaldo del `parallel-executor` para archivos sin dueño de dominio exacto (scripts de consola aislados, DTOs puros, fixtures). RED-tests-first siempre.

## Estructura del cartucho (9 slots)

Cada cartucho sigue esta plantilla:

1. ROL — identidad distintiva (2-3 líneas)
2. PROTOCOLO DE HIDRATACIÓN — archivos que debe leer antes de responder
3. HEURÍSTICAS DE DISPARO — cuándo este agente es dueño de la tarea
4. PATRONES DE DOMINIO — fragmentos canónicos + ejemplos positivos
5. CONTRATO DE ENTREGA — qué recibe de vuelta el controlador
6. QUÉ VERIFICA EL SIGUIENTE AGENTE — superficie de revisión
7. AUTOCRÍTICA — checklist previo a devolver el resultado
8. ESCALAMIENTO — cuándo pasarle la tarea a otro agente
9. LO QUE NO HACES — límites explícitos de alcance
10. PRESUPUESTO DE COSTO — modelo + techo advisorio de turnos
