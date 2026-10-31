# oh-my-headless

Thin **spec + collection** for headless agent tooling (CLI / skill / MCP / other).  
Like **oh-my-zsh** or a **Homebrew tap**: conventions + discoverable entries + a meta skill — **not** a dump of tool source code.

## Canonical vs public

| Layer | Where | Role |
| --- | --- | --- |
| **Canonical (author)** | This tree under **llmwiki** (Google Drive sync) | Full collection, private/machine notes, daily edits |
| **Open mirror** | Standalone GitHub repo | Public SPEC, schema, example entries, meta skill, `install.sh` |

**Upstream of truth for the author is llmwiki Drive.** The public repo mirrors only the public slice. See [BOUNDARY.md](./BOUNDARY.md).

Public mirror (placeholder until first push): `https://github.com/guileen/oh-my-headless`

## Minimal layout

```
oh-my-headless/
  README.md
  BOUNDARY.md
  SPEC.md
  install.sh
  registry/          # manifests only (no vendored tool code)
  skills/omh-meta/   # capability discovery / auto-config / usage
  local/             # private; gitignored — machine paths, install hints
```

## Quick install (discovery hooks)

From this directory (or a clone of the public mirror):

```sh
./install.sh
```

Hooks discovery symlinks for `~/.agents/skills` (and optionally Codex). Does **not** replace llmwiki skillloaders; meta skill is also symlinked into `~/llmwiki/skills/omh-meta` when that tree exists.

## Add a tool

1. Copy a registry stub under `registry/<id>.yaml` (or `.json`).
2. Fill fields from [SPEC.md](./SPEC.md) — install URL / commands only, no source dump.
3. Optional: `skills/<id>/SKILL.md` for agent usage.
4. Run `./install.sh` and the check command from the manifest.
5. Ask the agent to load **omh-meta** to discover / configure / use.

## Not in scope

- Vendoring Playwright, Moli, Crawl4AI, or any tool binary/source
- Secrets, personal machine absolute paths in the public slice
- Replacing existing `~/llmwiki/skills/_loaders/*`
