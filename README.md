# oh-my-headless

Thin **spec + registry + `omh` CLI** for headless agent tooling (CLI / skill / MCP).  
Conventions + discoverable manifests — **not** vendored tool source.

## Quick

```sh
git clone https://github.com/guileen/oh-my-headless.git
cd oh-my-headless
./install.sh          # links bin/omh + omh-meta skill
omh                   # capability map + status
```

Meta skill **omh-meta**: when/what → run `omh`.

## Layout

```
bin/omh              # map+status | status | update | doctor | install
registry/*.yaml      # manifests (checks: installed/initialized/logged_in)
skills/omh-meta/     # → run omh
skills/<id>/         # optional per-tool skills
install.sh           # thin → omh install
SPEC.md BOUNDARY.md
local/               # gitignored machine notes
```

## Add a tool

1. `registry/<id>.yaml` per [SPEC.md](./SPEC.md).
2. `install` → upstream only. Optional `init` / `login` + `checks.*`.
3. Optional `skills/<id>/SKILL.md`. Mark baselines `must: true` (RTK).
4. `omh` to verify.

See [BOUNDARY.md](./BOUNDARY.md).
