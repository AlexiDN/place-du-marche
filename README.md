# Place du Marché

<div align="center">
  <h2>High-quality Claude Code plugins with French flair.</h2>
  <img src="images/baguette.gif" width="400" height="400" alt="Baguette" />
</div>

## Why Place du Marché?

Quality-focused Claude Code plugins, tested and benchmarked. No hype — just verified improvements to your workflow.

## Quality Assurance

All plugins in this marketplace are AI-assisted and thoroughly tested. Every plugin is benchmarked against our test suite to verify the promised benefits. Benchmark code is available in our [benchmark repository](https://github.com/AlexiDN/benchmark) — results will be published here soon.

## Installation

In Claude Code:

```
/plugin marketplace add https://github.com/AlexiDN/place-du-marche.git
/plugin install dev-tools@place-du-marche
```

## Plugins

- **[dev-tools](plugins/dev-tools)** — Generic development utilities (MCP servers, Git hooks, conventions)
- **[dev-python](plugins/dev-python)** — Python-focused development tools (refactoring, linting, idioms)

See each plugin's README for installation, dependencies, and full documentation.

## Adding a plugin

1. `mkdir -p plugins/<plugin-name>/.claude-plugin`
2. Add `plugins/<plugin-name>/.claude-plugin/plugin.json` with at least
   `name`, `description`, `version`.
3. Add the plugin's components (`skills/`, `commands/`, `agents/`,
   `hooks/hooks.json`, `.mcp.json`) at the plugin root as needed.
4. Add a matching entry to `.claude-plugin/marketplace.json`.
5. Test locally with `claude --plugin-dir ./plugins/<plugin-name>` before
   committing.
