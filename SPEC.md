# SPEC — registry entry (manifest only)

Registry entries are manifests only. No upstream tool source in this collection.

Built-in omh orchestration — gates this CLI owns — lives under `libexec/omh/` and is dispatched by `bin/omh`. That is not a registry entry. Do not add a YAML whose install path is a personal absolute path for the same gate.

| Command | Script | Rules |
| --- | --- | --- |
| `omh complexity-audit` (alias `omh audit-complexity`) | `libexec/omh/complexity-audit.sh` | `docs/complexity-budget-spec-2026-09-26.md` |

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
- A registry YAML that stands in for an omh-owned gate (`libexec/omh/` instead)  
