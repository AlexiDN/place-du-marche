---
name: rope-refactor
description: Use when moving a class/function to another file, renaming a symbol project-wide, extracting a method, inlining a variable, or splitting a module into a package in Python code — including as one step of a larger task, not just when the whole request is a refactor. Prefer the rope-mcp-server MCP tools over reading the whole file and hand-editing it and every import site.
---

# rope-based Python refactoring

This project has the `rope-refactor` MCP server available
(`mcp__rope-refactor__*` tools). It wraps the [rope](https://github.com/python-rope/rope)
library — the same refactoring engine behind PyCharm's and VS Code's Python
refactor commands — and performs the edit plus every import/reference update
project-wide in one call.

**Rule: for any move/rename/extract/inline, call the `mcp__rope-refactor__*`
tool. Do not use `Read`+`Edit` for this, even if it looks faster by hand.**
This still applies when the move/rename is embedded inside a bigger request
(e.g. "move X into its own file and add a new endpoint for it") — do the
structural part with `move_symbol`/`rename_symbol` first, then build the rest
on top, rather than reading everything by hand because the request wasn't
*only* a refactor. A hand-done move on anything past a trivial single-file
case reliably misses an import site rope would have caught automatically —
imports buried inside a multi-name `from x import (a, b, c)` line are the
easiest to miss by eye and the easiest for rope to catch.

**Moving more than one symbol? Move leaf dependencies first.** If B's
definition references A (e.g. `ItemsPublic` has a field typed `list[ItemPublic]`),
call `move_symbol` for A before B. Moving B first leaves A undefined in the
destination file until A's move lands, breaking the import in between calls.
When in order is unclear, call `list_symbols` and move in the order symbols
reference each other, innermost first.

## When to reach for it

| Task | Instead of... | Use... |
| --- | --- | --- |
| Move a class/function to another file | `Read` the source file, `Edit` it out, `Edit` the destination file in, `Grep` for every import site and fix each by hand | `move_symbol` |
| Rename a function/class/variable used elsewhere | `Grep` for the name, `Edit` every call site one by one | `rename_symbol` |
| Split a module into a package | Manually create files and rewrite imports | `convert_module_to_init` / `convert_module_to_package` / `move_and_rename_module` |
| Pull a code block into its own method | Hand-write the new method, replace the block, hope you got every variable right | `extract_method` |
| Inline a variable at its use sites | `Grep` + manual substitution | `inline_variable` |
| See what's in a file before deciding how to edit it | `Read` the whole file | `list_symbols` first |

The reason this matters: a hand-done move/rename requires reading the full
symbol body plus every referencing file just to copy text around and patch
imports — exactly the token-heavy "read everything to do a copy-paste" that
these tools exist to avoid. rope computes the new import graph itself and
only reports back which files changed, not their full contents.

## Workflow

1. Call `list_symbols` on the file to see what's there, if unsure of exact
   names/locations.
2. Pick the matching tool from the table above instead of `Read`+`Edit`.
3. Check the tool's `changed_files` (and `warning_string_references`, for
   moves — rope can't see string-based references like `mock.patch("...")`
   or dynamic `importlib` paths, so those need a manual follow-up check).
4. For anything that isn't a structural move/rename/extract/inline (a
   one-line tweak inside a function, a non-Python file), just use plain
   `Read`/`Edit` — rope only helps with the operations it's built for.

## What this plugin does NOT do

There's no semantic *search*/*read* layer here (no LSP-backed find-definition
or find-references for exploration) — only refactor operations. Use normal
`Read`/`Grep`/`Glob` to explore and understand code; reach for
`mcp__rope-refactor__*` only when the task is one of the structural edits
above.
