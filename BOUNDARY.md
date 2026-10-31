# Boundary

## Tracked

- Spec, registry schema, public manifests
- `bin/omh`, `install.sh`, `skills/omh-meta` (+ optional public tool skills)
- Docs with no private workspace layout

## Not tracked

- Secrets / tokens / cookies  
- Personal absolute paths, hostnames, LAN details  
- Tool source or vendored binaries  
- `local/` and `.private/` (gitignored)

`omh install` may symlink `omh` and `omh-meta` into dirs you opt into via env/defaults. It must not require a private wiki or personal path layout.
