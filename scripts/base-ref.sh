#!/usr/bin/env bash
# Imprime el commit desde donde nació la rama actual: el merge-base más cercano entre
# develop/main/master. Así una rama que nació de un tag de main (besrc) no arrastra
# los tickets de develop que no son suyos.
set -euo pipefail

BEST=999999; BASE=
for b in develop main master; do
  MB=$(git merge-base HEAD "$b" 2>/dev/null) || continue
  N=$(git rev-list --count "$MB"..HEAD)
  [ "$N" -lt "$BEST" ] && { BEST=$N; BASE=$MB; }
done
[ -n "$BASE" ] || { echo "base-ref: no encontré develop/main/master" >&2; exit 1; }
echo "$BASE"
