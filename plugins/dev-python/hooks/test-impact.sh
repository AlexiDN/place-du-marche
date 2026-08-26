#!/bin/bash
# Runs after a rope move_symbol/rename_symbol call. Greps test files for the
# affected symbol's name and surfaces which ones likely need to be run, so
# Claude doesn't have to guess.
# ponytail: text-match on the symbol's name via grep, not a real reference
# graph — a hook can't call back into rope's MCP tools, only read
# tool_input/tool_response on stdin. Cheap heuristic, not exhaustive.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
symbol_name=$(jq -r '.tool_input.new_name // .tool_input.symbol_name // empty' <<<"$input") || exit 0

[[ -z "$symbol_name" ]] && exit 0

project_dir=$(jq -r '.cwd // "."' <<<"$input") || exit 0

cd "$project_dir" || exit 0

matches=$(grep -rlE "\b${symbol_name}\b" \
  --include='test_*.py' --include='*_test.py' \
  . 2>/dev/null | head -20)

[[ -z "$matches" ]] && exit 0

matches_list=$(echo "$matches" | sed 's/^/- /')
jq -n --arg symbol "$symbol_name" --arg list "$matches_list" '{
  systemMessage: ("Edited symbol \($symbol) is referenced in these test files — consider running them:\n\($list)")
}'
exit 0
