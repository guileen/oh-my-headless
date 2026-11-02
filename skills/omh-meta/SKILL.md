---
name: omh-meta
description: oh-my-headless meta — when discovering headless CLI/skill/MCP capabilities, checking install/init/login status, or updating the collection → run `omh`. Must-have registry entries (must:true, e.g. RTK) first.
---

# omh-meta

**When/what → run `omh`.** That CLI prints the capability map + status and self-describing `NEXT` lines.

```bash
omh            # map + status (default)
omh doctor     # same + fix hints for every failure
omh update     # pull collection, then status
omh install    # link `omh` + this skill
omh complexity-audit   # text complexity gate (alias: omh audit-complexity)
```

Resolve collection root: `OH_MY_HEADLESS_ROOT` if set, else the checkout that provides `omh` / this skill (`../..`).

## Rules

1. Discover only via `omh` / `registry/*.yaml` — do not invent tools.
2. `must: true` first (RTK). Follow `NEXT` install/init/login lines.
3. No vendoring upstream tool source. No secrets or personal paths in tracked files ([BOUNDARY.md](../../BOUNDARY.md)). `omh complexity-audit` is built-in orchestration under `libexec/omh/`, not a registry id.
