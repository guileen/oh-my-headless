---
name: rtk
description: RTK (Rust Token Killer) — compress bash/CLI output for coding agents. Use when installing/wiring RTK, measuring savings, or bypassing condensed output.
---

# RTK

Intercepts agent shell commands and returns compact output (often far fewer tokens). Do not vendor source; install upstream only.

## When

- High bash-noise / token cost in agent sessions
- Need host hooks so agents get filtered output without calling `rtk` by hand

## Install + wire

```bash
brew install rtk-ai/tap/rtk
# or: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
rtk --version && rtk gain   # must be the AI package, not crates.io rtk
rtk init -g --codex         # Codex; also --gemini, --agent cursor|omp|pi, …
# restart the agent host after init
```

## Daily

```bash
rtk gain                    # savings dashboard
rtk bypass <cmd>            # one unfiltered run when condensed output is unusable
RTK_DISABLED=1 <cmd>        # disable for a process
```

Hooks cover Bash/shell tools only — not built-in Read/Grep/Glob. Prefer `rtk read` / `rtk rg` when those paths matter. Details: `registry/rtk.yaml`, https://www.rtk-ai.app
