# claude-code-symfony-stack

Configuración base de Claude Code para un tech lead fullstack en **Symfony 6.4/8 · PHP 8.3/8.4 · Twig · JavaScript** — Grupo de Expertos con 6 agentes, patrones de oleadas paralelas, y skills de Superpowers cableados.

Setup multi-agente enfocado exclusivamente en el ámbito PHP.

## Qué incluye

```
CLAUDE.md                          # instrucciones raíz — rol, reglas no negociables, ruteo de agentes
agents/
├── architect.md                   # descomposición de tareas, diseño de sistema
├── backend-expert.md              # Symfony/Doctrine/Security/Messenger
├── frontend-expert.md             # Twig/Stimulus/Turbo/JS/CSS
├── adversarial.md                 # ataque de diseño, OWASP, diagnóstico de solo lectura
├── validate.md                    # gate de type/lint/format/test (haiku)
├── drafter.md                     # implementador de respaldo TDD (haiku)
└── README.md                      # roster auto-generado
rules/
├── workflows.md                   # equipos estándar + patrones de oleadas paralelas
├── sprint-status.md               # formato de árbol de estado de sprint
├── hooks.md                       # hooks, higiene de CLAUDE.md, automatización headless
├── php/symfony.md                 # convenciones Symfony/Doctrine + estilo de código PHP
├── php/testing.md                 # convenciones PHPUnit + mutation testing (Infection, modo PR-diff)
└── frontend/twig-js.md            # convenciones Twig/Stimulus (lazy)/Turbo/Live & Twig Components
skills/
└── parallel-executor/SKILL.md     # controlador de sprint en oleadas paralelas
```

## Instalación

**Global — para cada sesión de Claude Code en esta máquina:**

```bash
git clone <url-de-este-repo> claude-code-symfony-stack
cd claude-code-symfony-stack

cp CLAUDE.md ~/CLAUDE.md
mkdir -p ~/.claude/agents ~/.claude/rules/php ~/.claude/rules/frontend ~/.claude/skills/parallel-executor
cp agents/*.md ~/.claude/agents/
cp rules/*.md ~/.claude/rules/
cp rules/php/*.md ~/.claude/rules/php/
cp rules/frontend/*.md ~/.claude/rules/frontend/
cp skills/parallel-executor/SKILL.md ~/.claude/skills/parallel-executor/
```

**Por proyecto — versionado dentro de un repo Symfony específico:**

```bash
git clone <url-de-este-repo> .claude-code-symfony-stack
cp .claude-code-symfony-stack/CLAUDE.md ./CLAUDE.md
mkdir -p .claude/agents .claude/rules .claude/skills
cp -r .claude-code-symfony-stack/agents/* .claude/agents/
cp -r .claude-code-symfony-stack/rules/* .claude/rules/
cp -r .claude-code-symfony-stack/skills/* .claude/skills/
```

## Plugin requerido

Este setup depende del plugin `superpowers` (brainstorming, TDD, systematic-debugging, writing-plans, etc.):

```bash
claude plugin install superpowers
```

## Plugin recomendado

`php-lsp` (Intelephense) da inteligencia de código real sobre archivos `.php` del proyecto Symfony (goToDefinition, findReferences, hover, workspaceSymbol) — no es parte del roster de agentes, pero complementa a `backend-expert` cuando navega el código existente:

```bash
claude plugin install php-lsp
npm install -g intelephense   # requerido por el plugin, se instala aparte
```

## Herramienta recomendada por proyecto — Symfony Mate

[Symfony Mate](https://symfony.com/doc/current/ai/components/mate.html) (`symfony/ai-mate`, PHP ≥8.2, Symfony 5.4/6.4/7.3/8) le da al agente acceso al profiler, logs de Monolog y contenedor compilado de la app real vía CLI:

```bash
composer require --dev symfony/ai-mate symfony/ai-symfony-mate-extension symfony/ai-monolog-mate-extension
vendor/bin/mate init
composer dump-autoload
vendor/bin/mate discover
```

- Todavía es 0.x — la API puede cambiar entre versiones.
- `mate discover` instala skills oficiales en `.agents/skills/` y los replica en `.claude/skills/` con prefijo `mate-` (no chocan con `parallel-executor`): `symfony-request-triage`, `symfony-profiler-debugging`, `symfony-service-inspection`, `symfony-dotenv-diagnostics` y `symfony-log-investigation` (Monolog). Son salida generada — no se editan a mano; `vendor/bin/mate skills:disable <nombre>` para apagar uno.
- `mate init` genera/modifica `AGENTS.md` y `CLAUDE.md` en la raíz del proyecto — si ya copiaste el `CLAUDE.md` de este repo ahí, revisa el diff y conserva ambos bloques.
- Revisa y comitea `mate/extensions.php`: todo paquete con `extra.ai-mate` se habilita solo.
- Agrega `Bash(vendor/bin/mate *)` a `permissions.allow` para no autorizar cada llamada.
- Si lo que quieres es que tu app **exponga** tools propios (no solo depurarla), eso es otra pieza: `symfony/mcp-bundle` con `#[McpTool]`, servido por `bin/console mcp:server <nombre>` (stdio) o HTTP — es código de producción y va con su propio diseño de seguridad.

## Notas

- Los 6 agentes están recortados para este stack — 100% ámbito PHP/Symfony, sin agentes de otros dominios.
- `parallel-executor` reemplaza `superpowers:subagent-driven-development` (que fuerza despacho secuencial) — dispara oleadas paralelas de agentes agrupadas por solapamiento de archivos.
- Ver `CLAUDE.md` → sección "REGLAS NO NEGOCIABLES" para el detalle de mínimo 3 / objetivo 5 agentes en paralelo por tarea, commit único al final de la tarea (push automático solo en `feature/*`), nunca commit directo en `main`/`master` y migraciones nunca automáticas fuera de local.
- `rules/hooks.md`, `rules/php/*.md` y `rules/frontend/twig-js.md` llevan frontmatter `paths:` — Claude Code las carga solo cuando se tocan archivos que matchean esos globs.
