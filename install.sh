#!/usr/bin/env bash
# Instala el stack de Claude Code para Symfony.
#   ./install.sh                  global: ~/CLAUDE.md + ~/.claude/{agents,rules,skills,hooks,scripts} + hooks en ~/.claude/settings.json
#   ./install.sh --project <dir>  por proyecto: <dir>/CLAUDE.md + <dir>/.claude/{agents,rules,skills,scripts} (sin hooks)
# Sobrescribe los archivos del stack con la versión del repo; los que difieren se respaldan como <archivo>.bak-<fecha>.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
stamp=$(date +%Y%m%d-%H%M%S)

# copia src/<rel> a <dest>/<rel>, respaldando el destino si existe y es distinto
put() {
  local rel=$1 dest=$2
  mkdir -p "$(dirname "$dest/$rel")"
  if [ -f "$dest/$rel" ] && ! cmp -s "$src/$rel" "$dest/$rel"; then
    cp "$dest/$rel" "$dest/$rel.bak-$stamp"
    echo "  respaldo: $dest/$rel.bak-$stamp"
  fi
  cp "$src/$rel" "$dest/$rel"
}

# copia todos los archivos versionados bajo los directorios dados
put_dirs() {
  local dest=$1; shift
  (cd "$src" && git ls-files -- "$@") | while IFS= read -r rel; do put "$rel" "$dest"; done
}

if [ "${1:-}" = "--project" ]; then
  dir=$(cd "${2:?uso: ./install.sh --project <dir>}" && pwd)
  echo "Instalando por proyecto en $dir"
  put CLAUDE.md "$dir"
  put_dirs "$dir/.claude" agents rules skills scripts
  chmod +x "$dir"/.claude/scripts/*.sh
  echo "Listo. Los hooks son globales: córrelo sin --project para instalarlos en ~/.claude."
  exit 0
fi

command -v jq >/dev/null || { echo "Falta jq (lo usan los hooks y la fusión de settings.json)" >&2; exit 1; }

echo "Instalando global en ~/.claude"
put CLAUDE.md "$HOME"
put_dirs "$HOME/.claude" agents rules skills hooks scripts
chmod +x "$HOME"/.claude/hooks/*.sh "$HOME"/.claude/scripts/*.sh

# fusiona settings/hooks.json: reemplaza la lista de cada evento que define el repo, conserva el resto de settings.json
settings="$HOME/.claude/settings.json"
[ -f "$settings" ] || echo '{}' > "$settings"
cp "$settings" "$settings.bak-$stamp"
tmp=$(mktemp)
jq -s '.[0] * {hooks: ((.[0].hooks // {}) + .[1].hooks)}' "$settings" "$src/settings/hooks.json" > "$tmp"
mv "$tmp" "$settings"
echo "  hooks fusionados en $settings (respaldo: $settings.bak-$stamp)"

echo "Listo. Requiere el plugin superpowers: claude plugin install superpowers"
