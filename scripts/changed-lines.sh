#!/usr/bin/env bash
# Rangos de líneas cambiadas en src/*.php vs la base de la rama (incluye sin commitear y nuevos).
# Salida: "<archivo>\t<desde>\t<hasta>" por rango; un archivo nuevo sale como 1..999999.
# Uso: changed-lines.sh [base]   (sin base usa base-ref.sh)
set -euo pipefail

BASE=${1:-$("$(dirname "$0")"/base-ref.sh)}
EXCLUDE='^src/(Migrations|DataFixtures)/|^src/Kernel\.php$'

git diff -U0 --diff-filter=d "$BASE" -- 'src/*.php' | awk '
  /^\+\+\+ b\// { file = substr($0, 7); next }
  /^@@/ { split($3, a, ","); s = substr(a[1], 2); n = (a[2] == "" ? 1 : a[2]);
          if (n > 0) printf "%s\t%d\t%d\n", file, s, s + n - 1 }' | grep -v -E "$EXCLUDE" || true
git ls-files --others --exclude-standard -- 'src/*.php' | grep -v -E "$EXCLUDE" | sed 's/$/\t1\t999999/' || true
