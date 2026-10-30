#!/usr/bin/env bash
# PreToolUse Bash: niega comandos destructivos sin autorización explícita.
#  1. git push forzado: --force, --force-with-lease, -f (también agrupado, ej. -uf) o refspec con + (origin +main)
#  2. bucle for con rm -rf / git reset --hard / git clean -f
c=$(jq -r '.tool_input.command // empty')

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

if grep -qE '(^|[;&|[:space:]])git[[:space:]]+push([[:space:]]|$)' <<<"$c"; then
  push=$(grep -oE 'git[[:space:]]+push[^;&|]*' <<<"$c")
  if grep -qE '[[:space:]](--force[a-z-]*|-[a-zA-Z]*f[a-zA-Z]*)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]' <<<"$push"; then
    deny "git push forzado bloqueado — pide autorización explícita"
  fi
fi

if grep -qE '(^|[;&|[:space:]])for\b' <<<"$c" \
  && grep -qE 'rm[[:space:]]+-rf|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-f' <<<"$c"; then
  deny "for-loop con comando peligroso (rm -rf / git reset --hard / git clean -f) bloqueado — pide autorización explícita"
fi

echo '{}'
