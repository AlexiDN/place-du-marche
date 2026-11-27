# tiles-statusline

A colored, self-updating status line for Claude Code, under the prompt.

```
🤖 Opus 5.5 │ 🧠 context ██▏░░░░░░░ 22% │ ⏳ session ████████░░ 81% ↻ 2h10m │ 📅 week ██▎░░░░░░░ 23% ↻ 3d11h │ ⚡ cache █████████▉ 59:46
                                   📘 my-skill  🔧 gitlab › get_pipeline
                                                         🧩 plugins dev-tools · tiles-statusline │ 🔌 mcp github · gitlab
```

- **Left**: the model, the context window fill, the 5-hour session and weekly rate limits (with the time left
  before each resets) and a prompt cache countdown.
- **Center, live**: the MCP call running right now, and the skills used in the current turn.
- **Right**: the plugins enabled in your settings and the MCP servers whose tools are loaded in the session.

Every gauge changes color as it gets worse: green, yellow, orange, then red. The cache timer turns red as it nears
expiry and shows `cache cold` once it expired, after a `/compact` or after a model switch (the next request rebuilds
the cache either way). The line refreshes every second and wraps to two rows when the terminal is too narrow.

## Install

At the prompt of a terminal session:

```
/plugin install tiles-statusline --marketplace AlexiDN/place-du-marche
```

From a shell:

```
claude plugin install tiles-statusline --marketplace AlexiDN/place-du-marche
```

Answer `y` to add the marketplace, then pick a scope (user scope to have it in every session).

If your settings already name a `statusLine` command, remove it: this plugin draws the status line itself, and the
command would keep running for nothing.

## Requirements

- `bash`, `jq` and GNU `date` (Linux; on macOS install `coreutils` and `jq`).
- A terminal with truecolor support.
- For the `powerline` style, a [Nerd Font](https://www.nerdfonts.com/) (otherwise the rounded tile edges show as boxes).

## Settings

Everything is set from `/config`, under the `Status line …` entries; a change applies at once.

| Entry | Values | Default |
|---|---|---|
| Status line style | `plain` (colored text) or `powerline` (rounded tiles colored by health) | `plain` |
| Status line bars | `none`, `smooth`, `blocks`, `dots` | `smooth` |
| Status line bar width | cells per bar | `10` |
| Status line emoji icons | emoji in front of each segment | on |
| Status line reset countdowns | `↻` time before the session and week limits reset | on |
| Status line spacing | blank lines above the line and between its rows | `1` |
| Status line quiet right tiles | dimmer plugin and MCP tiles, so the gauges stand out | on |
| Status line left / center / right segments | which segments each zone shows, in order: `model context session week cache` / `active` / `plugins mcp` | all |
| Status line cache lifetime (s) | `3600` (1 h) or `300` (5 min) | `3600` |

## How it works

A hooks module calls `statusline.sh` every second with the same JSON a `statusLine` command receives (model, context
window, rate limits, transcript path) and draws its output as the status line. The cache countdown starts from the last
assistant reply in the transcript; the live activity and the loaded MCP servers are read from the transcript too.

## License

MIT
