#!/usr/bin/env bash
# PostToolUse Write|Edit|MultiEdit sobre .php:
#  1. registra el archivo para que stop-phpstan.sh lo analice al final del turno
#  2. aplica php-cs-fixer solo si el archivo es nuevo o ya cumplía el estándar en HEAD
#     (evita reformatear archivos legacy enteros y ensuciar el diff del ticket)
input=$(cat)
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty' <<<"$input")
sid=$(jq -r '.session_id // "nosession"' <<<"$input")

[ -n "$f" ] && [ -f "$f" ] || exit 0
case "$f" in */vendor/*|*/node_modules/*|*/var/*|*/public/build/*) exit 0 ;; esac
case "$f" in *.php) ;; *) exit 0 ;; esac

# raíz del proyecto = primer directorio hacia arriba con composer.json (la sesión puede estar abierta fuera del proyecto)
root=$(dirname "$f")
while [ "$root" != "/" ] && [ ! -f "$root/composer.json" ]; do root=$(dirname "$root"); done
[ "$root" != "/" ] || exit 0

state="$HOME/.claude/hooks/state"
mkdir -p "$state"
grep -qxF "$f" "$state/$sid.php-files" 2>/dev/null || echo "$f" >> "$state/$sid.php-files"

cd "$root" || exit 0
fixer=vendor/bin/php-cs-fixer
[ -x "$fixer" ] || exit 0
rel=${f#"$root"/}

if git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
  tmp=$(mktemp -d)
  git show "HEAD:$rel" > "$tmp/$(basename "$rel")" 2>/dev/null || { rm -rf "$tmp"; exit 0; }
  "$fixer" fix --dry-run --using-cache=no --quiet "$tmp/$(basename "$rel")" >/dev/null 2>&1
  compliant=$?
  rm -rf "$tmp"
  [ "$compliant" -eq 0 ] || exit 0
fi

"$fixer" fix --quiet "$f" >/dev/null 2>&1
exit 0
