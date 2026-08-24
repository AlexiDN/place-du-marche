# dev-tools

General-purpose developer tools plugin: GitLab and GitHub MCP servers, plus
a hook that enforces [Conventional Commits](https://www.conventionalcommits.org/)
on every `git commit`.

## Install

```
/plugin marketplace add https://gitlab.autonhomeserver.com/ai/claude-code/place-du-marche.git
/plugin install dev-tools@place-du-marche
```

## MCP servers

Both servers are configured in `.mcp.json` and read their credentials from
environment variables — set these before starting Claude Code (e.g. in your
shell profile or a `.env` loaded by it):

### GitLab (`@zereight/mcp-gitlab`, via `npx`)

| Variable | Description |
| --- | --- |
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab personal access token with API scope |
| `GITLAB_API_URL` | Base API URL of your GitLab instance (e.g. `https://gitlab.example.com/api/v4`) |

Requires Node.js (`npx`) available on `PATH`.

### GitHub (`ghcr.io/github/github-mcp-server`, via Docker)

| Variable | Description |
| --- | --- |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub personal access token |

Requires Docker available on `PATH`.

## Hooks

`hooks/check-conventional-commit.sh` runs on `PreToolUse` for `Bash` and
inspects any `git commit -m "..."` command. If the message doesn't match
`<type>(<scope>): <subject>` (types: `feat`, `fix`, `docs`, `style`,
`refactor`, `perf`, `test`, `chore`, `ci`, `build`, `revert`), the commit is
blocked and Claude is shown the expected format.

Known limitation: only `-m "..."` / `-m msg` commits are checked; a
`-F <file>` or editor-based commit is not validated.
