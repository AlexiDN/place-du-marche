#!/bin/bash
# Blocks `git commit` when the message doesn't follow Conventional Commits.
# ponytail: only handles `-m "..."` / `-m msg`; a `-F file` or heredoc commit is not checked.

input=$(cat)
command=$(jq -r '.tool_input.command' <<<"$input")

if [[ "$command" != *"git commit"* ]]; then
  exit 0
fi

if [[ "$command" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
  message="${BASH_REMATCH[1]}"
elif [[ "$command" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
  message="${BASH_REMATCH[1]}"
elif [[ "$command" =~ -m[[:space:]]+([^[:space:]]+) ]]; then
  message="${BASH_REMATCH[1]}"
else
  exit 0
fi

pattern='^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([^)]+\))?!?:[[:space:]].+'
if ! [[ "$message" =~ $pattern ]]; then
  echo "Commit message does not follow Conventional Commits format." >&2
  echo "Expected: <type>(<scope>): <subject>  (types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert)" >&2
  echo "Example: feat(auth): add login validation" >&2
  echo "Received: $message" >&2
  exit 2
fi

exit 0
