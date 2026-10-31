# SPEC — add a headless tool (manifest only)

Each tool is a **registry entry**, not a fork of the tool. No tool source code in this collection.

## Required fields

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Stable slug (`moli`, `playwright-cli`) |
| `kind` | enum | `cli` \| `skill` \| `mcp` \| `other` |
| `what` | string | One-liner for discovery (what an agent should know) |
| `install` | string \| object | Official install: curl / brew / npm / uv / docs URL. Commands only. |
| `bin` or `entry` | string | Binary name, MCP entry, or skill path key |
| `check` | string | Shell check that proves install (e.g. `moli --version`) |

## Optional fields

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Display name if different from `id` |
| `skill` | string | Path to optional `skills/<id>/SKILL.md` relative to collection root |
| `config` | string[] \| object | **Names** of env/config keys only — never secret values |
| `deps` | string[] | Other registry `id`s this entry needs |
| `homepage` | string | Upstream project URL |
| `platforms` | string[] | e.g. `macos`, `linux` |
| `notes` | string | Short public caveats |

## Process

1. Add `registry/<id>.yaml` (preferred) or `.json`.
2. Fill required fields; keep `install` pointing at **upstream** releases.
3. Optionally add `skills/<id>/SKILL.md` for agent workflow.
4. `./install.sh` → discovery links; run `check`.
5. Use meta skill **omh-meta** to discover / configure / attach.

## Anti-patterns

- Copying tool repos into this tree
- Baking personal absolute paths into tracked manifests
- Storing API keys in `config` values
