# dev-python

Project-wide Python refactoring for Claude Code, built around
[rope](https://github.com/python-rope/rope) — the refactoring engine behind
PyCharm's and VS Code's Python "rename"/"move" commands — via the
[rope-mcp-server](https://github.com/krystofbe/rope-mcp-server) MCP. Move a
class/function to another file, rename a symbol project-wide, extract a
method, or inline a variable in one call, with every import and reference
updated automatically — instead of Claude reading the whole file and every
call site just to copy text around by hand.

## Install

```
/plugin marketplace add https://gitlab.autonhomeserver.com/ai/claude-code/place-du-marche.git
/plugin install dev-python@place-du-marche
```

## Dependencies

| Dependency | Required? | Used for | If missing |
| --- | --- | --- | --- |
| [`uv`](https://docs.astral.sh/uv/) (`uvx` on `PATH`) | **Required** | Runs `rope-mcp-server` (`uvx rope-mcp-server`), no manual install needed. | The `rope-refactor` MCP server fails to start — the plugin's core functionality (move/rename/extract) is unavailable. |
| [`ruff`](https://docs.astral.sh/ruff/) on `PATH` | Optional | The `ruff-gate.sh` `Stop` hook: auto-fix + format + report remaining lint issues. | The hook is a no-op (fails open, no error, no message) — it never installs or requires ruff itself. Bring your own if you want this hook to do anything. |
| `jq` on `PATH` | **Required** | Parses hook input/builds hook output JSON in both hooks. | Hooks error out instead of running (the MCP server and skill still work). |

No `npx`/Docker/other runtime is used by this plugin.

## Why rope instead of an LSP/Serena-style server?

An earlier version of this plugin used [Serena](https://github.com/oraios/serena)
(an LSP-backed semantic search/edit MCP) for both exploration and editing.
It was dropped: Serena has open issues around memory leaks (up to ~30GB RSS),
zombie child processes, and occasional language-server crashes — too fragile
to depend on by default. See
[oraios/serena#944](https://github.com/oraios/serena/issues/944),
[#1488](https://github.com/oraios/serena/issues/1488).

This plugin now targets a narrower, more reliable problem instead: **rope**
is a mature (15+ year old), Python-only, non-LSP refactoring library that
performs the same move/rename operations directly via AST-level analysis, no
language-server subprocess involved. It doesn't do semantic search or
"read only the relevant part of a file" the way an LSP-backed tool would —
for that, use normal `Read`/`Grep`/`Glob`. It only does structural,
project-wide refactors correctly and updates every affected file for you.

Worth revisiting if Serena (or a similar LSP-backed tool) stabilizes — that
would still be complementary to rope, not a replacement, since it solves a
different problem (semantic exploration vs. mechanical refactor).

## Components

- **MCP server** (`rope-refactor`): started via `uvx rope-mcp-server`.
  Exposes `list_symbols`, `move_symbol`, `move_module`,
  `move_and_rename_module`, `convert_module_to_init`,
  `convert_module_to_package`, `rename_symbol`, `extract_method`,
  `inline_variable`, `close_rope_project`.
- **Skill** (`rope-refactor`): maps refactor-shaped tasks (move, rename,
  extract, inline, split-into-package) to the matching MCP tool instead of
  manual `Read`+`Edit`.
- **Hook** (`hooks/ruff-gate.sh`, `Stop`): once the agent finishes, runs
  `ruff check --fix` and `ruff format` over the whole project, then reports
  any remaining (non-auto-fixable) issues back as a message — informational
  only, never blocks. Fails open: if `ruff` is missing, or check/format
  errors out for any reason (bad config, no `pyproject.toml`, version
  mismatch), it exits silently rather than surfacing a spurious error.
- **Hook** (`hooks/test-impact.sh`, `PostToolUse` on rope's
  `move_symbol`/`rename_symbol`): greps `test_*.py`/`*_test.py` files for the
  affected symbol's name and lists which ones likely need a re-run. A cheap
  text-match heuristic, not a real reference graph.

## Known limitations

- `rope-mcp-server` itself is a small, young project (reviewed for safety
  before adopting: no network calls, no `eval`/`exec`, MIT-licensed, only
  depends on `fastmcp` and `rope`) — functionally solid since it's a thin
  wrapper over the mature `rope` library, but not battle-tested at scale.
  If it stalls, the fallback is a direct wrapper around `rope` itself (the
  library, not this server).
- rope can't see string-based references (`mock.patch("old.module.path")`,
  dynamic `importlib.import_module(...)` calls) — `move_symbol` and friends
  report these as `warning_string_references` for manual follow-up rather
  than silently missing them.
- Python only (rope's own limitation).

## Ideas not included (yet)

- **Semantic search/exploration layer**: revisit Serena (or a plain LSP MCP)
  once it's more stable — orthogonal to rope, would cover "find/understand"
  rather than "move/rename".
- **Non-Python language parity**: rope is Python-only; other languages would
  need a different refactor engine entirely.
- **mypy/pyright type-check gate**: same shape as `ruff-gate.sh` but for
  type errors — not added since ruff already covers lint+format and adding
  a second tool dependency wasn't asked for.
