#!/usr/bin/env bash
# Gate de duplicación: reporta los clones (jscpd) en los que participa alguna línea cambiada en src/.
# El escaneo es sobre todo src/ para detectar copias de código existente, pero solo se reportan
# los clones que tocan líneas de la rama (la duplicación legacy no se reporta).
# Uso: jscpd-gate.sh [min-tokens=50]  (desde la raíz del proyecto; JSCPD_BASE=<ref> fuerza la base)
set -euo pipefail

MIN_TOKENS="${1:-50}"
DIR="$(dirname "$0")"
BASE=${JSCPD_BASE:-$("$DIR"/base-ref.sh)} || { echo "❌ duplicación — sin rama base para comparar"; exit 1; }

OUT=var/jscpd-gate
mkdir -p "$OUT" && rm -f "$OUT/jscpd-report.json"
"$DIR"/changed-lines.sh "$BASE" > "$OUT/changed.tsv"
[ -s "$OUT/changed.tsv" ] || { echo "✅ duplicación — sin .php cambiados en src/"; exit 0; }

timeout 300 npx --yes jscpd@4.3.0 --format php --min-tokens "$MIN_TOKENS" \
  --reporters json --output "$OUT" --silent src/ > "$OUT/jscpd.log" 2>&1 \
  || { echo "❌ duplicación — jscpd falló, ver $OUT/jscpd.log"; tail -10 "$OUT/jscpd.log"; exit 1; }

php -r '
[, $report, $tsv] = $argv; $ranges = []; $hits = [];
foreach (file($tsv, FILE_IGNORE_NEW_LINES) as $row) { [$f, $a, $b] = explode("\t", $row); $ranges[$f][] = [(int) $a, (int) $b]; }
$touches = fn (array $s) => array_filter($ranges[$s["name"]] ?? [], fn ($r) => $r[0] <= $s["end"] && $r[1] >= $s["start"]);
foreach (json_decode(file_get_contents($report), true)["duplicates"] ?? [] as $d) {
    [$a, $b] = [$d["firstFile"], $d["secondFile"]];
    if ($touches($a) || $touches($b))
        $hits[] = sprintf("%4d líneas  %s:%d-%d  ≈  %s:%d-%d", $d["lines"], $a["name"], $a["start"], $a["end"], $b["name"], $b["start"], $b["end"]);
}
if ($hits) { echo "❌ duplicación — clones que tocan líneas cambiadas:\n", implode("\n", array_unique($hits)), "\n"; exit(1); }
echo "✅ duplicación — sin clones en las líneas cambiadas\n";
' "$OUT/jscpd-report.json" "$OUT/changed.tsv"
