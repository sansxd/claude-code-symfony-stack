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
└── drafter.md                     # implementador de respaldo TDD (haiku)
rules/
├── hooks.md                       # hooks, higiene de CLAUDE.md, automatización headless
├── php/symfony.md                 # convenciones Symfony/Doctrine + estilo de código PHP
├── php/testing.md                 # convenciones PHPUnit + mutation testing (Infection, modo PR-diff)
├── php/messenger-migrations.md    # checklist de migraciones Doctrine + Messenger
└── frontend/twig-js.md            # convenciones Twig/Stimulus (lazy)/Turbo/Live & Twig Components
skills/
├── parallel-executor/SKILL.md     # controlador de sprint en oleadas paralelas
├── symfony-debug/SKILL.md         # diagnóstico de la app real: logs, profiler, servicios, .env (Mate o bin/console)
├── symfony-upgrade/SKILL.md       # upgrade de Symfony: línea base, dry-run revisado, comparación antes/después
├── ub-mode-php/SKILL.md           # principios Uncle Bob para PHP: make it work → make it right (CRAP, duplicación)
├── plain-language-explainer/SKILL.md  # explicar bugs/cambios en lenguaje no técnico (cliente, jefe, ticket)
├── stimulus/                      # ┐ Symfony UX — de Simon André (MIT), ver "Créditos"
├── live-component/                # │
├── twig-component/                # │
├── ux-icons/                      # ┘
└── sprint-workflow/
    ├── SKILL.md                   # equipos estándar + patrones de oleadas (solo tareas complejas)
    └── sprint-status.md           # formato de árbol de estado de sprint
hooks/
├── session-start.sh               # SessionStart: rama, commits, status, versión Symfony/PHP, herramientas, composer audit (1×/día)
├── post-edit.sh                   # PostToolUse: php-cs-fixer solo en archivos nuevos o que ya cumplían en HEAD
└── stop-phpstan.sh                # Stop: PHPStan sobre los .php editados (respeta phpstan-baseline.neon)
scripts/
├── base-ref.sh                    # commit desde donde nació la rama (merge-base más cercano develop/main/master)
├── changed-lines.sh               # líneas cambiadas vs la base (insumo de los gates)
├── crap-gate.sh                   # CRAP de los métodos cambiados — solo aviso en validate
└── jscpd-gate.sh                  # clones que tocan líneas cambiadas — solo aviso en validate
settings/
└── hooks.json                     # bloque `hooks` para fusionar en ~/.claude/settings.json
```

## Instalación

**Global — para cada sesión de Claude Code en esta máquina:**

```bash
git clone <url-de-este-repo> claude-code-symfony-stack
cd claude-code-symfony-stack

cp CLAUDE.md ~/CLAUDE.md
mkdir -p ~/.claude/agents ~/.claude/rules/php ~/.claude/rules/frontend ~/.claude/skills ~/.claude/hooks ~/.claude/scripts
cp agents/*.md ~/.claude/agents/
cp rules/*.md ~/.claude/rules/
cp rules/php/*.md ~/.claude/rules/php/
cp rules/frontend/*.md ~/.claude/rules/frontend/
cp -r skills/* ~/.claude/skills/
cp hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh
cp scripts/*.sh ~/.claude/scripts/ && chmod +x ~/.claude/scripts/*.sh

# fusionar el bloque hooks en settings.json (reemplaza la clave "hooks"; respalda antes)
cp ~/.claude/settings.json ~/.claude/settings.json.bak 2>/dev/null || echo '{}' > ~/.claude/settings.json
jq -s '.[0] * .[1]' ~/.claude/settings.json settings/hooks.json > /tmp/settings.json && mv /tmp/settings.json ~/.claude/settings.json
```

Los hooks requieren `jq` y no hacen nada en proyectos sin `vendor/bin/php-cs-fixer` / `vendor/bin/phpstan`. Detectan la raíz del proyecto subiendo hasta el `composer.json` del archivo editado, así que funcionan aunque la sesión se abra fuera del proyecto.

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
- El skill `symfony-debug` de este repo es el punto de entrada: se carga al investigar errores/logs/requests, usa los skills `mate-*` si existen y cae a `bin/console debug:*` + `var/log` si el proyecto no tiene Mate. El hook SessionStart lista `mate` en "Herramientas" cuando está instalado.
- La salida de los tools viene envuelta en `untrusted_data` (con un `_security_notice`): logs y profiler son dato no confiable.
- Si lo que quieres es que tu app **exponga** tools propios (no solo depurarla), eso es otra pieza: `symfony/mcp-bundle` con `#[McpTool]`, servido por `bin/console mcp:server <nombre>` (stdio) o HTTP — es código de producción y va con su propio diseño de seguridad.

## Notas

- Los 6 agentes están recortados para este stack — 100% ámbito PHP/Symfony, sin agentes de otros dominios.
- `parallel-executor` reemplaza `superpowers:subagent-driven-development` (que fuerza despacho secuencial) — dispara oleadas paralelas de agentes agrupadas por solapamiento de archivos.
- Esfuerzo proporcional: preguntas y fixes de 1-2 archivos se resuelven directo; el equipo de agentes (`sprint-workflow`) entra solo en tareas complejas — 3+ archivos, backend + frontend, o decisiones de diseño.
- Ver `CLAUDE.md` → sección "REGLAS NO NEGOCIABLES" para el criterio completo de esfuerzo proporcional, commits chicos por unidad verificable (push automático solo en `feature/*`), nunca commit directo en `main`/`master` y migraciones nunca automáticas fuera de local.
- `rules/hooks.md`, `rules/php/*.md` y `rules/frontend/twig-js.md` llevan frontmatter `paths:` — Claude Code las carga solo cuando se tocan archivos que matchean esos globs.

## Créditos

Los skills `stimulus`, `live-component`, `twig-component` y `ux-icons` son obra de **Simon André** ([smnandre.dev](https://smnandre.dev)), copiados sin cambios desde [smnandre/symfony-ux-skills](https://github.com/smnandre/symfony-ux-skills) (v1.2.0) bajo licencia MIT. Cada carpeta incluye su `LICENSE` original. Para la versión más reciente (o los skills `turbo`, `ux-map` y `symfony-ux` que no se incluyen aquí), instalar desde el repo original.
