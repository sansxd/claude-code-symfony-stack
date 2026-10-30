#!/usr/bin/env bash
# Gate CRAP: falla si algún método cambiado en src/ tiene CRAP >= umbral.
# CRAP = complejidad² × (1 − cobertura)³ + complejidad.
# Corre solo los tests relacionados (<Clase>Test por cada archivo cambiado + tests cambiados),
# así que la cobertura es conservadora: un método cubierto solo por tests lejanos puede salir alto.
# Uso: crap-gate.sh [umbral=10]  (desde la raíz del proyecto; CRAP_BASE=<ref> fuerza la base)
set -euo pipefail

MAX="${1:-10}"
DIR="$(dirname "$0")"
BASE=${CRAP_BASE:-$("$DIR"/base-ref.sh)} || { echo "❌ CRAP — sin rama base para comparar"; exit 1; }

OUT=var/crap-gate
mkdir -p "$OUT" && rm -f "$OUT/clover.xml"
"$DIR"/changed-lines.sh "$BASE" > "$OUT/changed.tsv"
mapfile -t SRC < <(cut -f1 "$OUT/changed.tsv" | sort -u)
[ ${#SRC[@]} -eq 0 ] && { echo "✅ CRAP — sin .php cambiados en src/"; exit 0; }

mapfile -t TESTS < <({ printf '%s\n' "${SRC[@]}" | xargs -n1 basename | sed 's/\.php$/Test/'; \
  { git diff --name-only --diff-filter=d "$BASE" -- 'tests/*Test.php'; git ls-files --others --exclude-standard -- 'tests/*Test.php'; } | xargs -r -n1 basename | sed 's/\.php$//'; } \
  | sort -u)
EXISTING=$(printf '%s\n' "${TESTS[@]}" | while read -r t; do find tests -name "$t.php" -print -quit 2>/dev/null; done | xargs -r -n1 basename | sed 's/\.php$//' | sort -u | paste -sd'|')
[ -z "$EXISTING" ] && { echo "⚠ CRAP — ningún test relacionado con: ${SRC[*]}"; exit 0; }

# Driver de cobertura: pcov o Xdebug si están cargados; si no, carga Xdebug solo para este proceso
DRIVER=()
php -m | grep -q -i -E '^(pcov|xdebug)$' || DRIVER=(-d zend_extension=xdebug.so)

PHPUNIT=$( [ -x vendor/bin/phpunit ] && echo vendor/bin/phpunit || echo bin/phpunit )
XDEBUG_MODE=coverage timeout 580 php "${DRIVER[@]}" -d memory_limit=1G "$PHPUNIT" \
  --filter "/($EXISTING)/" --coverage-clover "$OUT/clover.xml" > "$OUT/phpunit.log" 2>&1 \
  || echo "⚠ CRAP — hay tests en rojo (lo bloquea el paso phpunit, no este); ver $OUT/phpunit.log"
[ -s "$OUT/clover.xml" ] || { echo "❌ CRAP — no se generó $OUT/clover.xml"; tail -20 "$OUT/phpunit.log"; exit 1; }

# Solo cuentan los métodos con alguna línea cambiada (el legacy intacto no se reporta).
# Un método va desde su línea de declaración hasta la anterior al siguiente método.
php -r '
[, $clover, $max, $tsv] = $argv; $max = (float) $max;
$root = getcwd() . "/"; $bad = []; $seen = []; $ranges = [];
foreach (file($tsv, FILE_IGNORE_NEW_LINES) as $row) { [$f, $a, $b] = explode("\t", $row); $ranges[$f][] = [(int) $a, (int) $b]; }
foreach (simplexml_load_file($clover)->xpath("//file") as $f) {
    $rel = str_replace($root, "", (string) $f["name"]);
    if (!isset($ranges[$rel])) continue;
    $seen[] = $rel;
    $methods = $f->xpath("line[@type=\"method\"]");
    foreach ($methods as $i => $m) {
        $from = (int) $m["num"]; $to = isset($methods[$i + 1]) ? (int) $methods[$i + 1]["num"] - 1 : PHP_INT_MAX;
        $touched = array_filter($ranges[$rel], fn ($r) => $r[0] <= $to && $r[1] >= $from);
        if ($touched && (float) $m["crap"] >= $max)
            $bad[] = sprintf("%7.1f  %s::%s (línea %d, complejidad %s)", $m["crap"], $rel, $m["name"], $from, $m["complexity"]);
    }
}
foreach (array_diff(array_keys($ranges), $seen) as $p) fwrite(STDERR, "⚠ sin cobertura de tests relacionados: $p\n");
if ($bad) { rsort($bad, SORT_NUMERIC); echo "❌ CRAP — métodos cambiados con CRAP >= $max:\n", implode("\n", $bad), "\n"; exit(1); }
echo "✅ CRAP — todos los métodos cambiados bajo $max\n";
' "$OUT/clover.xml" "$MAX" "$OUT/changed.tsv"
