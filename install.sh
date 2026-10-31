#!/usr/bin/env bash
# oh-my-headless — optional skill discovery symlinks. Idempotent.
# Does not install upstream tools. Does not require any private workspace layout.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
META="$ROOT/skills/omh-meta"

# Colon-separated skill dirs to receive an omh-meta symlink.
# Override to match your agent host. Empty entries skipped.
# Default: create/use $HOME/.agents/skills when unset.
DEFAULT_SKILL_DIRS="${HOME}/.agents/skills"
SKILL_DIRS="${OH_MY_HEADLESS_SKILL_DIRS:-$DEFAULT_SKILL_DIRS}"

log() { printf 'omh: %s\n' "$*"; }

link_dir() {
  local target="$1" linkpath="$2"
  mkdir -p "$(dirname "$linkpath")"
  if [[ -L "$linkpath" ]]; then
    local cur
    cur="$(readlink "$linkpath")"
    if [[ "$cur" == "$target" ]]; then
      log "ok $linkpath -> $target"
      return 0
    fi
    log "replace symlink $linkpath ($cur -> $target)"
    rm -f "$linkpath"
  elif [[ -e "$linkpath" ]]; then
    log "skip existing non-symlink $linkpath"
    return 0
  fi
  ln -s "$target" "$linkpath"
  log "linked $linkpath -> $target"
}

main() {
  if [[ ! -f "$META/SKILL.md" ]]; then
    log "missing $META/SKILL.md" >&2
    exit 1
  fi

  IFS=':' read -r -a dirs <<< "$SKILL_DIRS"
  local d
  for d in "${dirs[@]}"; do
    [[ -z "$d" ]] && continue
    mkdir -p "$d"
    link_dir "$META" "$d/omh-meta"
  done

  log "collection root: $ROOT"
  log "registry entries:"
  # shellcheck disable=SC2012
  ls -1 "$ROOT/registry"/*.yaml 2>/dev/null | while read -r f; do
    log "  - $(basename "$f" .yaml)"
  done || true
  log "done. Load skill omh-meta for discover/configure/use."
  log "tip: OH_MY_HEADLESS_SKILL_DIRS='dir1:dir2' ./install.sh"
}

main "$@"
