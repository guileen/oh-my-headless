# oh-my-headless

Thin **spec + collection** for headless agent tooling (CLI / skill / MCP / other).  
Like **oh-my-zsh** or a **Homebrew tap**: conventions + discoverable registry entries + a meta skill — **not** a dump of tool source code.

## Layout

```
oh-my-headless/
  README.md
  BOUNDARY.md
  SPEC.md
  install.sh
  registry/          # manifests only (no vendored tool code)
  skills/omh-meta/   # capability discovery / configure / use
  local/             # optional machine-local notes (gitignored)
```

## Install (discovery hooks)

```sh
git clone https://github.com/guileen/oh-my-headless.git
cd oh-my-headless
./install.sh
```

`install.sh` optionally symlinks the **omh-meta** skill into agent skill-discovery directories you configure (see script / env). It does not install upstream tools and does not vendor binaries.

## Add a tool

1. Add `registry/<id>.yaml` using fields in [SPEC.md](./SPEC.md).
2. Point `install` at **upstream** docs or installers only — no source dump.
3. Optionally add `skills/<id>/SKILL.md`.
4. Run `./install.sh`, then the manifest `check` command.
5. Load **omh-meta** to discover / configure / use.

## Not in scope

- Vendoring tool binaries or source trees
- Secrets or personal machine paths in tracked files
- Replacing a host’s existing skill-loader setup

See [BOUNDARY.md](./BOUNDARY.md).
