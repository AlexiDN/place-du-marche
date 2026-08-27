# Place du Marché

A Claude Code plugin marketplace.

## Installation

In Claude Code:

```
/plugin marketplace add https://github.com/AlexiDN/place-du-marche.git
/plugin install dev-tools@place-du-marche
```

## Plugins

| Plugin | Description |
| --- | --- |
| [dev-tools](plugins/dev-tools) | GitLab, GitHub, and Context7 MCP servers, plus a Conventional Commits enforcement hook |
| [dev-python](plugins/dev-python) | Python refactoring via rope (move/rename/extract with automatic import updates), blocking ruff/type-check `Stop` hooks, and a python-idioms skill |

See each plugin's README for install commands, dependencies, and details.

## Adding a plugin

1. `mkdir -p plugins/<plugin-name>/.claude-plugin`
2. Add `plugins/<plugin-name>/.claude-plugin/plugin.json` with at least
   `name`, `description`, `version`.
3. Add the plugin's components (`skills/`, `commands/`, `agents/`,
   `hooks/hooks.json`, `.mcp.json`) at the plugin root as needed.
4. Add a matching entry to `.claude-plugin/marketplace.json`.
5. Test locally with `claude --plugin-dir ./plugins/<plugin-name>` before
   committing.
