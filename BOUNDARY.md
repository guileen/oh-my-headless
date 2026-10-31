# Boundary: llmwiki (canonical) vs open-source mirror

## In llmwiki (private / canonical)

Allowed and expected:

- Full registry collection (public + private entries)
- Machine notes, private install hints
- Local absolute paths **only** under `local/` or `.private/` (both ignored for public mirror)
- Cross-links to other llmwiki docs (`skills/`, `agent-headless-tools/`, workstation notes)
- Drafts not yet ready to open-source

Drive sync is the author’s source of truth. Git is optional here.

## In open-source repo (public)

Ship only:

- `README.md`, `BOUNDARY.md`, `SPEC.md`
- `registry/` schema + **example/public** entries (install URLs / check commands; no secrets)
- `skills/omh-meta/` meta skill
- `install.sh`
- Public `.gitignore`

**Must not include:**

- Secrets, tokens, cookies, API keys
- Personal machine paths (`/Users/…`, hostnames, LAN IPs) in tracked files
- Private Drive-only docs or research dumps
- Tool source code or vendored binaries
- Contents of `local/` or `.private/`

## Sync practice

1. Edit freely in llmwiki.
2. When publishing: copy the public file set into `~/miniworks/oh-my-headless` (or `git` remote), review for path/secret leakage, commit, push.
3. README in the public repo must state: **upstream of truth for the author is llmwiki Drive; this repo is the open mirror.**
