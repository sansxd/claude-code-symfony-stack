#!/usr/bin/env bash
# SessionStart: inyecta contexto del proyecto Symfony (git, versiones, herramientas) para no gastar turnos en el INICIO RÁPIDO.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" 2>/dev/null || exit 0

# limpieza de estado de sesiones viejas (lo usan post-edit.sh y stop-phpstan.sh)
find "$HOME/.claude/hooks/state" -type f -mtime +2 -delete 2>/dev/null

[ -f composer.json ] || exit 0

out="## Contexto del proyecto (hook SessionStart)"
if git rev-parse --git-dir >/dev/null 2>&1; then
  out+=$'\n'"- Rama: $(git branch --show-current)"
  out+=$'\n'"- Últimos commits:"$'\n'"$(git log --oneline -3 | sed 's/^/    /')"
  n=$(git status --short | wc -l)
  out+=$'\n'"- Cambios sin commitear: $n"
  [ "$n" -gt 0 ] && out+=$'\n'"$(git status --short | head -15 | sed 's/^/    /')"
fi

sf=$(jq -r '.packages[] | select(.name=="symfony/framework-bundle") | .version' composer.lock 2>/dev/null)
out+=$'\n'"- Symfony: ${sf:-desconocido} · PHP: $(php -r 'echo PHP_VERSION;' 2>/dev/null)"

tools=""
[ -x vendor/bin/phpstan ] && tools+=" phpstan"
[ -f phpstan-baseline.neon ] && tools+="(baseline)"
[ -x vendor/bin/php-cs-fixer ] && tools+=" php-cs-fixer"
[ -x vendor/bin/phpunit ] || [ -x bin/phpunit ] && tools+=" phpunit"
[ -x vendor/bin/rector ] && tools+=" rector"
[ -f compose.yaml ] || [ -f docker-compose.yml ] && tools+=" docker-compose"
out+=$'\n'"- Herramientas:${tools:- ninguna}"

jq -n --arg c "$out" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
