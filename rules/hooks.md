# Hooks — Detalle Técnico

**Alcance de la regla:** se carga bajo demanda al editar `~/.claude/settings.json`, `.claude/settings.json` de proyecto, o al escribir hooks nuevos.

## Ubicaciones

- **Hooks de proyecto:** `.claude/settings.json`
- **Hooks de usuario:** `~/.claude/settings.json`
- **Servidores MCP:** `.mcp.json` en la raíz del proyecto — NUNCA en `settings.json`

## Convenciones de salida

- `exit 2` + stderr → bloquea la llamada a la herramienta
- `exit 0` → continúa
- Cualquier otro código no-cero → se trata como bloqueo, con stderr mostrado

## Hooks clave recomendados para este stack

### PostToolUse (Edit | Write) — autoformateo
- `.php` → `vendor/bin/php-cs-fixer fix <archivo>`
- `.js` → `npx prettier --write <archivo>` (si el proyecto usa Prettier)
- Se dispara automáticamente tras cada Edit/Write; mantiene los commits limpios de estilo.

### PostToolUse (Bash) — comprimir salida verbosa de build
Filtra con `grep -E "(ERROR|error|WARNING|FAIL)" | head -200` antes de que Claude la lea. Evita que un log de build de 10K líneas contamine el contexto.

### PreToolUse (Bash) — bloquear `git push --force*`
Sale con código 2 y stderr explicando el bloqueo. El bypass requiere solicitud explícita del usuario.

### Patrón de auto-fix en pre-push
Si el hook de pre-push falla en PHP-CS-Fixer/PHPStan:

1. `vendor/bin/php-cs-fixer fix && vendor/bin/phpstan analyse`
2. Re-stage los cambios de formato: `git add .`
3. Comitea el fix de formato como commit separado
4. Reintenta `git push`

Nunca `--no-verify` salvo que el usuario lo pida explícitamente.

### Stop hook — gate de verificación
Script de verificación que bloquea el fin de turno hasta que pasa. El gate más fuerte para corridas desatendidas — evita que Claude declare completitud mientras los validadores siguen fallando.

## Recetas de automatización (headless)

- `claude -p "prompt"` — no interactivo, para CI/cron/scripts
- `claude -p "..." --output-format stream-json --verbose` — JSON en streaming para pipelines
- `claude -p "..." --allowedTools "Edit,Bash(git commit *)"` — permisos acotados para corridas por lote
- `claude --permission-mode auto -p "..."` — seguridad por clasificador para corridas desatendidas (bloquea escalamiento de alcance)

## Regla de higiene de CLAUDE.md

Mantenlo corto — archivos abultados causan que se ignoren reglas. Para cada línea: "¿Quitar esto causaría errores?" Si no, córtala.

- `@ruta/al/archivo` dentro de CLAUDE.md carga ese archivo al contexto (útil para docs compartidos por el equipo)
- `CLAUDE.local.md` en la raíz del proyecto = overrides personales, nunca comiteado (agrégalo a `.gitignore`)
- Reglas específicas de dominio → `.claude/rules/` con patrones `paths:` (solo cargan cuando se tocan archivos que calzan)

## Ubicación de skills

`.claude/skills/<nombre>/SKILL.md` — conocimiento de dominio cargado bajo demanda, no en cada sesión. Se aplica automáticamente cuando es relevante, o se invoca con `/nombre-skill`.

**Prefiere skills sobre agregar a CLAUDE.md** para conocimiento que solo se necesita a veces.
