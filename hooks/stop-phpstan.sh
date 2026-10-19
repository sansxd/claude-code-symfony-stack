#!/usr/bin/env bash
# Stop: corre PHPStan sobre los .php que Claude editó en esta sesión (registrados por post-edit.sh), agrupados por proyecto.
# Errores → bloquea una vez para que Claude los corrija; si persisten en el reintento, avisa al usuario y deja terminar.
# El baseline del proyecto (phpstan-baseline.neon) se aplica solo vía phpstan.dist.neon.
input=$(cat)
sid=$(jq -r '.session_id // "nosession"' <<<"$input")
active=$(jq -r '.stop_hook_active // false' <<<"$input")
list="$HOME/.claude/hooks/state/$sid.php-files"

[ -s "$list" ] || exit 0

declare -A byroot
while IFS= read -r f; do
  [ -f "$f" ] || continue
  root=$(dirname "$f")
  while [ "$root" != "/" ] && [ ! -f "$root/composer.json" ]; do root=$(dirname "$root"); done
  [ -x "$root/vendor/bin/phpstan" ] || continue
  byroot[$root]+="$f"$'\n'
done < "$list"

errors=""
for root in "${!byroot[@]}"; do
  mapfile -t files < <(printf '%s' "${byroot[$root]}")
  out=$(cd "$root" && timeout 150 vendor/bin/phpstan analyse --no-progress --error-format=raw --memory-limit=2G "${files[@]}" 2>&1)
  rc=$?
  [ "$rc" -eq 0 ] && continue
  if [ "$rc" -eq 124 ]; then
    jq -n --arg m "PHPStan (hook Stop) superó 150s en $root y se omitió." '{systemMessage: $m}'
    rm -f "$list"
    exit 0
  fi
  errors+=$(grep -v '^Note: Using configuration file' <<<"$out")$'\n'
done

if [ -z "$errors" ]; then
  rm -f "$list"
  exit 0
fi

errors=$(head -c 4000 <<<"$errors")
if [ "$active" = "true" ]; then
  rm -f "$list"
  jq -n --arg m "PHPStan sigue reportando errores tras el reintento:"$'\n'"$errors" '{systemMessage: $m}'
  exit 0
fi

jq -n --arg r "PHPStan encontró errores en archivos que editaste. Corrígelos antes de terminar (o explica por qué no aplican):"$'\n'"$errors" \
  '{decision: "block", reason: $r}'
