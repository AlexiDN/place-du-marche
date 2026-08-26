#!/bin/bash
# Runs on Stop: auto-fixes and formats every .py file in the project with
# ruff, then reports any remaining (non-auto-fixable) issues back to Claude
# as context. Never blocks — informational only.
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

jq -n --arg remaining "$remaining_output" '{
  systemMessage: ("ruff found issues it could not auto-fix after formatting:\n" + $remaining)
}'
exit 0
