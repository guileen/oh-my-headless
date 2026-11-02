# oh-my-headless

Thin **spec + registry + `omh` CLI** for headless agent tooling (CLI / skill / MCP).  
Conventions + discoverable manifests — **not** vendored upstream tool source.  
Gates that `omh` itself runs live under `libexec/omh/` (built-in orchestration, not registry entries).

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
bin/omh              # map+status | status | update | doctor | install | complexity-audit
libexec/omh/         # built-in orchestration (complexity-audit); not registry tools
docs/                # rule specs those built-ins cite
registry/*.yaml      # manifests (checks: installed/initialized/logged_in)
skills/omh-meta/     # → run omh
skills/<id>/         # optional per-tool skills
tests/               # small checks (complexity-audit --selftest)
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

## Built-in: complexity-audit

`omh complexity-audit` (alias `omh audit-complexity`) is this CLI's text-file complexity gate. It is **not** a `registry/*.yaml` tool and does not point at a personal checkout. Rules: [docs/complexity-budget-spec-2026-09-26.md](docs/complexity-budget-spec-2026-09-26.md). Exemptions stay in the **target** repo (`docs/complexity-exemptions.txt`); this collection does not ship a grandfather list.

```sh
omh complexity-audit --help
omh complexity-audit --selftest
bash tests/complexity-audit-selftest.sh
```
