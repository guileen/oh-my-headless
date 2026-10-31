#!/usr/bin/env bash
# oh-my-headless — hook discovery symlinks (Codex / omp / .agents)
# Does not replace ~/llmwiki/skills/_loaders. Idempotent.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
META="$ROOT/skills/omh-meta"
AGENTS_SKILLS="${OH_MY_HEADLESS_AGENTS_SKILLS:-$HOME/.agents/skills}"
CODEX_SKILLS="${OH_MY_HEADLESS_CODEX_SKILLS:-$HOME/.codex/skills}"
LLMWIKI_SKILLS="${OH_MY_HEADLESS_LLMWIKI_SKILLS:-$HOME/llmwiki/skills}"

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

  # Primary agent discovery root (skillloader convention on this workstation)
  if [[ -d "$AGENTS_SKILLS" || ! -e "$AGENTS_SKILLS" ]]; then
    mkdir -p "$AGENTS_SKILLS"
    link_dir "$META" "$AGENTS_SKILLS/omh-meta"
  fi

  # Canonical llmwiki skills tree: keep body under oh-my-headless, discover via symlink
  if [[ -d "$LLMWIKI_SKILLS" ]]; then
    link_dir "$META" "$LLMWIKI_SKILLS/omh-meta"
  else
    log "no $LLMWIKI_SKILLS — skip llmwiki skills symlink"
  fi

  # Optional Codex skills discovery (same pattern as moli-* links)
  if [[ -d "$CODEX_SKILLS" ]]; then
    link_dir "$META" "$CODEX_SKILLS/omh-meta"
  else
    log "no $CODEX_SKILLS — skip Codex symlink (create dir later if needed)"
  fi

  # omp: if ~/.omp exists, document-only unless a skills dir is present
  if [[ -d "$HOME/.omp" ]]; then
    local omp_skills=""
    for cand in "$HOME/.omp/skills" "$HOME/.omp/agent/skills"; do
      if [[ -d "$cand" ]]; then
        omp_skills="$cand"
        break
      fi
    done
    if [[ -n "$omp_skills" ]]; then
      link_dir "$META" "$omp_skills/omh-meta"
    else
      log "omp present; no skills dir found — meta skill still via .agents / llmwiki"
    fi
  fi

  log "collection root: $ROOT"
  log "registry entries:"
  # shellcheck disable=SC2012
  ls -1 "$ROOT/registry"/*.yaml 2>/dev/null | while read -r f; do
    log "  - $(basename "$f" .yaml)"
  done || true
  log "done. Load skill omh-meta for discover/configure/use."
}

main "$@"
