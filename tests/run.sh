#!/usr/bin/env bash
# Tests del repo: casos del hook pre-bash-guard.sh + frontmatter de agentes y skills + settings/hooks.json.
# Uso: tests/run.sh  (desde cualquier lado; requiere jq)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
fail=0

# pre-bash-guard: cada línea es "<allow|deny>\t<comando>"
while IFS=$'\t' read -r exp cmd; do
  got=$(jq -n --arg c "$cmd" '{tool_input:{command:$c}}' | hooks/pre-bash-guard.sh | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
  [ "$got" = "$exp" ] || { echo "❌ pre-bash-guard: esperaba $exp, obtuvo $got — $cmd"; fail=1; }
done < tests/pre-bash-guard.cases

# frontmatter: name + description en cada agente y SKILL.md; name igual al archivo/carpeta
for f in agents/*.md skills/*/SKILL.md; do
  fm=$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1{print}' "$f")
  name=$(sed -n 's/^name:[[:space:]]*//p' <<<"$fm" | tr -d "\"'")
  case "$f" in agents/*) want=$(basename "$f" .md) ;; *) want=$(basename "$(dirname "$f")") ;; esac
  [ "$name" = "$want" ] || { echo "❌ frontmatter: $f — name '$name', esperaba '$want'"; fail=1; }
  grep -q '^description:' <<<"$fm" || { echo "❌ frontmatter: $f — falta description"; fail=1; }
done

# settings/hooks.json: JSON válido y cada script referenciado existe y es ejecutable
jq -e . settings/hooks.json >/dev/null || { echo "❌ settings/hooks.json no es JSON válido"; fail=1; }
while read -r h; do
  [ -x "$h" ] || { echo "❌ settings/hooks.json referencia $h, que no existe o no es ejecutable"; fail=1; }
done < <(jq -r '.. | .command? // empty' settings/hooks.json | grep -oE '[~]/\.claude/hooks/[^ ]+' | sed 's|^[~]/\.claude/||')

[ "$fail" -eq 0 ] && echo "✅ tests del repo"
exit "$fail"
