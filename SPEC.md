# SPEC — registry entry (manifest only)

No tool source in this collection.

## Required

| Field | Meaning |
| --- | --- |
| `id` | Stable slug |
| `kind` | `cli` \| `skill` \| `mcp` \| `service` \| `other` |
| `what` | One-liner for discovery |
| `install` | Upstream install (string or `{macos,linux,windows,docs}`) |
| `bin` or `entry` | Binary / MCP / skill key |
| `checks.installed` or `check` | Shell proof of install |

## Optional

| Field | Meaning |
| --- | --- |
| `must` | `true` → required baseline (RTK) |
| `init` / `login` | Commands; printed in `omh` NEXT when needed |
| `checks.initialized` / `checks.logged_in` | Status probes when applicable |
| `skill` | Path to `skills/<id>/SKILL.md` |
| `config` | Env/config **names** only — never secrets |
| `deps` / `homepage` / `platforms` / `notes` | As needed |

## Process

1. Add `registry/<id>.yaml`.
2. Upstream `install` only; set `checks` (+ `init`/`login` if relevant).
3. `omh` → map+status. Meta skill runs `omh`.

## Anti-patterns

- Vendoring tool repos/binaries  
- Personal absolute paths or secrets in tracked files  
