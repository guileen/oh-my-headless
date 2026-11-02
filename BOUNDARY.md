# Boundary

## Tracked

- Spec, registry schema, public manifests
- `bin/omh`, `libexec/omh/` (built-in orchestration), `install.sh`, `skills/omh-meta` (+ optional public tool skills)
- Docs with no private workspace layout, including rule specs cited by built-ins

## Not tracked

- Secrets / tokens / cookies  
- Personal absolute paths, hostnames, LAN details  
- Upstream tool checkouts or vendored binaries (omh-owned scripts under `libexec/omh/` are tracked)
- Target-repo grandfather lists (the audited repo's `docs/complexity-exemptions.txt`)
- `local/` and `.private/` (gitignored)

`omh install` may symlink `omh` and `omh-meta` into dirs you opt into via env/defaults. It must not require a private wiki or personal path layout.
