#!/bin/bash
# Runs on Stop: auto-fixes and formats every .py file in the project with
# ruff, then blocks Stop if issues remain that ruff couldn't auto-fix, so
# Claude has to address them before the turn ends.
# Bypass: set DEV_PYTHON_NO_GATE=1 to make this (and type-check-gate.sh)
# informational-only again — for when you want to stop anyway with known
# issues outstanding.
# ponytail: shells out to `ruff` on PATH; if it's missing, or a project's
# ruff config disables check/format, or either subcommand errors out for
# any reason (bad config, no pyproject.toml, incompatible ruff version),
# fail open — skip silently rather than breaking Stop for an optional
# quality-of-life gate. Only genuine lint findings (a clean run of `ruff
# check`) are ever surfaced.

command -v ruff >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
project_dir=$(jq -r '.cwd // "."' <<<"$input") || exit 0
stop_hook_active=$(jq -r '.stop_hook_active // false' <<<"$input") || exit 0

# Already forced a continuation once this turn — don't loop forever.
[[ "$stop_hook_active" == "true" ]] && exit 0

cd "$project_dir" 2>/dev/null || exit 0

ruff check --fix --quiet . >/dev/null 2>&1
ruff format --quiet . >/dev/null 2>&1

remaining_output=$(ruff check --quiet . 2>/dev/null)
remaining_status=$?

# Exit 1 = lint findings (expected); anything else (0, or >1 for a usage/
# config error) means there's nothing actionable to report.
if [[ $remaining_status -ne 1 || -z "$remaining_output" ]]; then
  exit 0
fi

if [[ "$DEV_PYTHON_NO_GATE" == "1" ]]; then
  jq -n --arg remaining "$remaining_output" '{
    systemMessage: ("ruff found issues it could not auto-fix after formatting:\n" + $remaining)
  }'
  exit 0
fi

echo "ruff found issues it could not auto-fix after formatting — fix them, or set DEV_PYTHON_NO_GATE=1 to bypass:
$remaining_output" >&2
exit 2
