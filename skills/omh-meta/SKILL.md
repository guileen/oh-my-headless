---
name: omh-meta
description: oh-my-headless (OMH) meta — load when setting up headless agent tooling, discovering CLI/skill/MCP capabilities, cutting token-heavy shell noise (must-have RTK), or checking/updating OMH itself. Use before ad-hoc installs; treat registry must:true as required.
---

# oh-my-headless meta

Collection root: `OH_MY_HEADLESS_ROOT` if set, else this skill’s `../..` (the oh-my-headless checkout).

Skill load = follow this when/what. CLI and status lines must be **self-describing**: each failure or next step states the exact command to run.

## Hard steps (do in order)

1. **Resolve root** — `root="${OH_MY_HEADLESS_ROOT:-…}"`. Prefer `./install.sh --status` from root (prints healthy/degraded + next instruction).
2. **Discover** — read `registry/*.yaml` (skip `_schema.json`, `README.md`). For each entry note `id`, `kind`, `what`, `must`, `check`, `skill`.
3. **Must-haves first** — every entry with `must: true` is **required** (today: **RTK**). For each: run `check`. If it fails → run upstream `install`, then host `init` from that entry’s skill (e.g. `rtk init -g --codex`), then re-`check`. Do not skip musts for optional tools.
4. **Optionals** — match the user task to non-must `id`s. Prefer bins whose `check` already passes. If missing: show `install`, ask unless user already authorized; then `check`.
5. **Attach** — if `skill` is set and the file exists, read it; else use `what` + `homepage`. Config: only key **names** under `config` (never secrets).
6. **OMH self** — manage the collection, not only tools:
   - Status: `./install.sh --status` → report `healthy` or `degraded` and follow its next line.
   - Update (when user wants latest public collection): `./install.sh --update` (git pull of this checkout) then `--status` again.
   - If omh-meta is not discoverable by the host: `./install.sh` to (re)link skills.

## CLI contract

- Prefer commands whose output ends with a **next instruction** for the agent.
- On missing must/tool: print the install/init/`check` lines, not a vague error.
- Do not invent tools outside the registry.

## Rules

- Spec + manifests only — do not vendor tool source.
- [BOUNDARY.md](../../BOUNDARY.md): no secrets or personal paths in tracked files.
- Additive to the host skill loader; do not replace it.

## Quick

```bash
root="${OH_MY_HEADLESS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$root" && ./install.sh --status
```
