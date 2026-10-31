---
name: omh-meta
description: Discover, configure, and use headless tools registered in oh-my-headless (CLI/skill/MCP). Use when the user asks what headless capabilities exist, how to install or wire one, or which tool fits browser/fetch/automation work—before inventing ad-hoc installs.
---

# oh-my-headless meta

Collection root: `OH_MY_HEADLESS_ROOT` if set, otherwise the directory that contains this skill’s `../../` (the clone or checkout of oh-my-headless).

## Goals

1. **Discover** — list registry entries and say what each is for.
2. **Configure** — apply install + config **key names** from the manifest (never invent secrets).
3. **Use** — point at `bin`/`entry` and optional per-tool `SKILL.md`; run `check`.

## Workflow

1. Resolve collection root as above.
2. Read `registry/*.yaml` (skip `_schema.json`, `README.md`). Summarize `id`, `kind`, `what`, `check`.
3. Match the user task to one or more `id`s. Prefer existing installed bins when `check` already passes.
4. If missing: show the manifest `install` command(s) and ask before running network installs unless the user already authorized install.
5. After install, run `check`. Wire discovery with collection `./install.sh` if skills are not visible to the agent host.
6. If `skill` is set and the file exists, read that SKILL for usage; otherwise use `what` + upstream `homepage`.
7. For config: only set or request values for keys listed under `config`. Do not write secrets into the registry.

## Rules

- This collection is **spec + manifests**, not a toolkit dump. Do not vendor tool source into the collection.
- Respect [BOUNDARY.md](../../BOUNDARY.md): no secrets or personal paths in tracked files.
- Do not replace the host’s existing skill-loader conventions; omh-meta is an additive discovery skill.

## Quick checks

```bash
root="${OH_MY_HEADLESS_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
ls "$root/registry"/*.yaml 2>/dev/null
```
