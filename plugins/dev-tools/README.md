# dev-tools

General-purpose developer tools plugin: GitLab, GitHub, and Context7 MCP
servers, plus a hook that enforces
[Conventional Commits](https://www.conventionalcommits.org/) on every
`git commit`.

## Install

```
/plugin marketplace add https://github.com/AlexiDN/place-du-marche.git
/plugin install dev-tools@place-du-marche
```

## Dependencies

| Dependency | Required? | Used for | If missing |
| --- | --- | --- | --- |
| Node.js (`npx` on `PATH`) | **Required** | Runs the `gitlab` MCP server (`@zereight/mcp-gitlab`). | The `gitlab` MCP server fails to start; `github` and the commit hook still work. |
| Docker on `PATH` | **Required** | Runs the `github` MCP server (`ghcr.io/github/github-mcp-server`). | The `github` MCP server fails to start; `gitlab` and the commit hook still work. |
| Node.js (`npx` on `PATH`) | **Required** | Runs the `context7` MCP server (`@upstash/context7-mcp`). | The `context7` MCP server fails to start; `gitlab`, `github`, and the commit hook still work. |
| `jq` on `PATH` | **Required** | Parses hook input in `check-conventional-commit.sh`. | The commit hook errors out instead of validating messages. |

## MCP servers

Both servers are configured in `.mcp.json` and read their credentials from
environment variables — set these before starting Claude Code (e.g. in your
shell profile or a `.env` loaded by it):

### GitLab (`@zereight/mcp-gitlab`, via `npx`)

| Variable | Description |
| --- | --- |
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab personal access token with API scope |
| `GITLAB_API_URL` | Base API URL of your GitLab instance (e.g. `https://gitlab.example.com/api/v4`) |

### GitHub (`ghcr.io/github/github-mcp-server`, via Docker)

| Variable | Description |
| --- | --- |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub personal access token |

### Context7 (`@upstash/context7-mcp`, via `npx`)

Fetches current, version-specific documentation and code examples for a
library on request, instead of relying on the model's training data (which
goes stale as libraries release new versions). Exposes
`resolve-library-id` and `get-library-docs` — used by `dev-python`'s
`python-idioms` skill before writing code against an external library's API,
and usable directly for any other language too.

| Variable | Description |
| --- | --- |
| `CONTEXT7_API_KEY` | Optional. Works without one at a lower rate limit; get a free key at [context7.com](https://context7.com) if you hit it. |

## Hooks

`hooks/check-conventional-commit.sh` runs on `PreToolUse` for `Bash` and
inspects any `git commit -m "..."` command. If the message doesn't match
`<type>(<scope>): <subject>` (types: `feat`, `fix`, `docs`, `style`,
`refactor`, `perf`, `test`, `chore`, `ci`, `build`, `revert`), the commit is
blocked and Claude is shown the expected format.

Known limitation: only `-m "..."` / `-m msg` commits are checked; a
`-F <file>` or editor-based commit is not validated.
