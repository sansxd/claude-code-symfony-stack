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
├── php/symfony.md                 # convenciones Symfony/Doctrine
├── php/testing.md                 # convenciones PHPUnit
└── frontend/twig-js.md            # convenciones Twig/Stimulus/JS
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

## Notas

- Los 6 agentes están recortados para este stack — 100% ámbito PHP/Symfony, sin agentes de otros dominios.
- `parallel-executor` reemplaza `superpowers:subagent-driven-development` (que fuerza despacho secuencial) — dispara oleadas paralelas de agentes agrupadas por solapamiento de archivos.
- Ver `CLAUDE.md` → sección "REGLAS NO NEGOCIABLES" para el detalle de mínimo 3 / objetivo 5 agentes en paralelo por tarea.
