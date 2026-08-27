---
name: python-idioms
description: Use when writing or reviewing Python code — design/architecture rules ruff and a type checker can't enforce (mutable default args, broad exceptions, god objects/functions, dataclasses vs. raw dict/tuple state, context managers for resource cleanup, Protocol vs. ABC). Applies while writing new code, not just as a post-hoc review pass. For any external library's API, resolve current usage via the Context7 MCP tools (resolve-library-id, query-docs — server named context7, from the dev-tools plugin) instead of guessing from training data.
---

# Python design idioms

`ruff-gate.sh` and `type-check-gate.sh` (this plugin's Stop hooks) catch
syntax/style/type issues mechanically. They can't catch design problems —
a function doing five unrelated things still type-checks. This skill covers
that gap: apply these while writing code, not just when asked to "review".

## Rules

**Mutable default arguments** — never `def f(x, items=[])` / `items={}`.
The default is created once at function definition, so every call without
`items` shares the same list. Use `items: list | None = None` and
`items = items if items is not None else []` inside.

**Exception scope** — catch the narrowest exception the call can actually
raise (`except (KeyError, ValueError):`), never a bare `except:` or
`except Exception:` unless re-raising or logging-then-re-raising. A silent
`except Exception: pass` hides real bugs, it doesn't handle them.

**God object / god function** — if a class has more than ~7 public
methods, or a function mixes I/O + business logic + formatting in one body,
split by responsibility. A function you can't summarize in one sentence
without "and" is a sign to split it.

**Structured state → `dataclass`, not `dict`/`tuple`** — if a piece of data
has a fixed, known shape (coordinates, a config bundle, a parsed result),
use `@dataclass` (or `NamedTuple` if immutable) instead of a dict with
string keys or a positional tuple. Typos in a dict key fail silently at
runtime; a dataclass field typo fails immediately and the type checker
catches it.

**Resource cleanup → context manager, not manual try/finally** — file
handles, locks, connections, temp state: use `with` (or write a small
`@contextmanager` if the cleanup is custom) instead of hand-written
`try/finally`. Prefer whatever context manager the library already exposes
before writing a new one.

**`Protocol` over `ABC` for structural typing** — if you're defining an
interface purely to type-check "anything with this method", use
`typing.Protocol` (duck typing, no inheritance required). Reach for `ABC`
only when you also need shared implementation or enforced instantiation
checks, not just a type shape.

**Composition over inheritance** — reach for inheritance only for a true
is-a relationship with shared behavior. If you're inheriting just to reuse
a couple of methods, pass the dependency in instead (a parameter, not a base
class).

## External library APIs: verify, don't guess

Before writing code against a library you didn't just read the source of in
this project, resolve its current API via Context7 — call the `context7`
server's `resolve-library-id` tool (tool names show up as
`mcp__context7__resolve-library-id` once `dev-tools` is installed normally,
or `mcp__plugin_dev-tools_context7__resolve-library-id` when running with
`--plugin-dir` directly) with the library name, then `query-docs` with the
returned library ID — rather than relying on training data. Library APIs
change between versions and a plausible-looking call that doesn't exist in
the installed version is a common source of silent bugs. Skip this for
stdlib and for APIs you've already confirmed by reading the installed
package's source in this session.

If no `context7` MCP tool is available (`dev-tools` not installed), fall
back to reading the installed package's source/`--help`/docstrings directly
rather than guessing.
