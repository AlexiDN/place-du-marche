# Place du Marché

A Claude Code plugin marketplace. The marketplace manifest lives at
`.claude-plugin/marketplace.json` and lists every plugin under `plugins/`.

## Language

Write everything in English: file contents, JSON field values (`description`,
`displayName`, etc.), commit messages, code comments. This applies even when
the user writes to you in French. Exception: proper nouns that are part of
the project's identity (e.g. the README title "Place du Marché") stay as-is.

## Plugin docs are the source of truth

Before creating or editing a plugin or the marketplace manifest, check the
current official docs rather than relying on memory — the schema changes
across Claude Code versions:

- Creating plugins: https://code.claude.com/docs/en/plugins
- Marketplace / marketplace.json schema: https://code.claude.com/docs/en/plugin-marketplaces
- Full technical reference: https://code.claude.com/docs/en/plugins-reference

If a doc fetch fails or leaves the schema ambiguous, ask the user rather than
guessing at field names or structure.

## Repo layout

```
place-du-marche/
├── .claude-plugin/
│   └── marketplace.json      # lists every plugin below
└── plugins/
    └── <plugin-name>/
        ├── .claude-plugin/
        │   └── plugin.json   # ONLY plugin.json goes here
        ├── skills/           # <name>/SKILL.md (preferred for new skills)
        ├── commands/         # flat .md skills (legacy layout)
        ├── agents/
        ├── hooks/hooks.json
        └── .mcp.json
```

Rules that keep tripping people up:

- `commands/`, `agents/`, `skills/`, `hooks/` live at the **plugin root**,
  never inside `.claude-plugin/`. Only `plugin.json` goes inside
  `.claude-plugin/`.
- Every plugin added under `plugins/` must also get an entry in
  `.claude-plugin/marketplace.json`'s `plugins` array, with a `source`
  pointing at `./plugins/<plugin-name>`.
- Plugin and marketplace `name` fields are kebab-case, no spaces.

## Adding a plugin

1. `mkdir -p plugins/<plugin-name>/.claude-plugin`
2. Add `plugins/<plugin-name>/.claude-plugin/plugin.json` with at least
   `name`, `description`, `version`.
3. Add the plugin's components (`skills/`, `commands/`, `agents/`,
   `hooks/hooks.json`, `.mcp.json`) at the plugin root as needed.
4. Add a matching entry to `.claude-plugin/marketplace.json`.
5. Test locally with `claude --plugin-dir ./plugins/<plugin-name>` before
   committing.
