#!/bin/bash
# Runs on Stop: runs whichever Python type checker is available (pyrefly,
# pyright, then mypy — first one found on PATH wins) and blocks Stop if it
# reports errors, so Claude has to address them before the turn ends.
# Bypass: set DEV_PYTHON_NO_GATE=1 to make this (and ruff-gate.sh)
# informational-only again — for when you want to stop anyway with known
# issues outstanding.
# ponytail: none of pyrefly/pyright/mypy are required dependencies — most
# projects have none of them installed, so skip silently rather than
# nagging. Only the first tool found on PATH runs; no attempt to merge
# output from multiple type checkers.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
project_dir=$(jq -r '.cwd // "."' <<<"$input") || exit 0
stop_hook_active=$(jq -r '.stop_hook_active // false' <<<"$input") || exit 0

# Already forced a continuation once this turn — don't loop forever.
[[ "$stop_hook_active" == "true" ]] && exit 0

cd "$project_dir" 2>/dev/null || exit 0

if command -v pyrefly >/dev/null 2>&1; then
  tool=pyrefly
  output=$(pyrefly check . 2>&1)
  status=$?
elif command -v pyright >/dev/null 2>&1; then
  tool=pyright
  output=$(pyright . 2>&1)
  status=$?
elif command -v mypy >/dev/null 2>&1; then
  tool=mypy
  output=$(mypy . 2>&1)
  status=$?
else
  exit 0
fi

# Exit 0 = no errors; anything else with no output means a config/usage
# error, not a real finding — nothing actionable to report either way.
if [[ $status -eq 0 || -z "$output" ]]; then
  exit 0
fi

if [[ "$DEV_PYTHON_NO_GATE" == "1" ]]; then
  jq -n --arg tool "$tool" --arg output "$output" '{
    systemMessage: ("\($tool) found type errors:\n" + $output)
  }'
  exit 0
fi

echo "$tool found type errors — fix them, or set DEV_PYTHON_NO_GATE=1 to bypass:
$output" >&2
exit 2
