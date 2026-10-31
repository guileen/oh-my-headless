# Boundary

## In this repository (tracked)

- Spec, registry schema, and **public** example manifests
- Meta skill (`skills/omh-meta`)
- `install.sh` for optional local discovery hooks
- Docs that describe the product, not a particular author’s private workspace

## Not in this repository

- Secrets, tokens, cookies, API keys
- Personal absolute paths, hostnames, or LAN details in tracked files
- Private install notes or machine-specific layouts
- Tool source code or vendored binaries
- Contents of `local/` or `.private/` (gitignored)

## Local-only areas

Use `local/` or `.private/` for machine-specific hints if needed. Those directories are ignored by git and must not be committed.

## What `install.sh` may do on a machine

- Symlink `skills/omh-meta` into skill-discovery directories you opt into via defaults or env
- Leave upstream tools untouched (install those via each manifest’s `install` field)

It must not embed or require any particular private wiki, workstation layout, or personal path.
