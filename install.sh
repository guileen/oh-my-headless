#!/usr/bin/env bash
# oh-my-headless — skill discovery links + self status/update.
# Does not install upstream tools. Does not require any private workspace layout.
# Usage: ./install.sh [--status|--update|--help]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
META="$ROOT/skills/omh-meta"
CMD="${1:-install}"

DEFAULT_SKILL_DIRS="${HOME}/.agents/skills"
SKILL_DIRS="${OH_MY_HEADLESS_SKILL_DIRS:-$DEFAULT_SKILL_DIRS}"

log() { printf 'omh: %s\n' "$*"; }
next() { printf 'omh: NEXT: %s\n' "$*"; }

usage() {
  cat <<'U'
omh: oh-my-headless installer / self-manager
omh:   ./install.sh           link omh-meta into skill dirs; list registry
omh:   ./install.sh --status  version, must-checks, healthy|degraded + NEXT
omh:   ./install.sh --update  git pull this checkout (if .git), then --status
omh:   ./install.sh --help    this text
omh: Env: OH_MY_HEADLESS_ROOT, OH_MY_HEADLESS_SKILL_DIRS (colon-separated)
U
  next "Load skill omh-meta, or from collection root: ./install.sh --status"
}

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

omh_version() {
  if [[ -d "$ROOT/.git" ]] && command -v git >/dev/null 2>&1; then
    git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "nogit"
  else
    echo "nogit"
  fi
}

# Extract a top-level YAML scalar or presence of must: true (no full parser).
yaml_field() {
  local file="$1" key="$2"
  # shellcheck disable=SC2002
  awk -v k="$key" '
    $0 ~ "^"k":[[:space:]]*" {
      sub("^[^:]+:[[:space:]]*", "", $0)
      gsub(/[[:space:]]+#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print
      exit
    }
  ' "$file"
}

yaml_must() {
  local file="$1" v
  v="$(yaml_field "$file" must)"
  [[ "$v" == "true" ]]
}

run_check() {
  local check="$1"
  [[ -z "$check" ]] && return 1
  # shellcheck disable=SC2086
  bash -c "$check" >/dev/null 2>&1
}

do_status() {
  local ver degraded=0 must_fail=0 meta_ok=0
  ver="$(omh_version)"
  log "status collection=$ROOT version=$ver"

  if [[ -f "$META/SKILL.md" ]]; then
    log "meta: present skills/omh-meta"
  else
    log "meta: MISSING skills/omh-meta/SKILL.md"
    degraded=1
  fi

  # skill symlink visibility (best-effort)
  IFS=':' read -r -a dirs <<< "$SKILL_DIRS"
  local d
  for d in "${dirs[@]}"; do
    [[ -z "$d" ]] && continue
    if [[ -L "$d/omh-meta" ]] || [[ -d "$d/omh-meta" ]]; then
      log "discoverable: $d/omh-meta"
      meta_ok=1
    else
      log "not linked: $d/omh-meta"
    fi
  done
  if [[ "$meta_ok" -eq 0 ]]; then
    degraded=1
  fi

  log "registry:"
  local f id what must_flag check st
  shopt -s nullglob
  for f in "$ROOT/registry"/*.yaml; do
    id="$(basename "$f" .yaml)"
    what="$(yaml_field "$f" what)"
    check="$(yaml_field "$f" check)"
    must_flag="optional"
    yaml_must "$f" && must_flag="MUST"
    if run_check "$check"; then
      st="ok"
    else
      st="FAIL"
      degraded=1
      [[ "$must_flag" == "MUST" ]] && must_fail=1
    fi
    log "  - $id [$must_flag] check=$st — ${what:-(no what)}"
    if [[ "$st" == "FAIL" ]]; then
      if [[ "$must_flag" == "MUST" ]]; then
        next "MUST $id failed. Read registry/$id.yaml + skills/$id/SKILL.md; install upstream; run check: $check"
      else
        next "optional $id failed check. Install only if needed: see registry/$id.yaml (check: $check)"
      fi
    fi
  done
  shopt -u nullglob

  if [[ "$degraded" -eq 0 ]]; then
    log "health=healthy"
    next "Load omh-meta for discover/use. Optional refresh: ./install.sh --update"
    return 0
  fi
  log "health=degraded"
  if [[ "$must_fail" -eq 1 ]]; then
    next "Fix MUST failures first (install+init+check), then re-run: ./install.sh --status"
  elif [[ "$meta_ok" -eq 0 ]]; then
    next "Link discovery: ./install.sh   then ./install.sh --status"
  else
    next "Repair failed checks or update collection: ./install.sh --update && ./install.sh --status"
  fi
  return 1
}

do_update() {
  if [[ ! -d "$ROOT/.git" ]]; then
    log "update: no .git in this checkout — pull/sync the public clone, then re-run status"
    next "In a git clone of oh-my-headless: git pull && ./install.sh --status"
    return 1
  fi
  if ! command -v git >/dev/null 2>&1; then
    log "update: git not on PATH"
    next "Install git, then: cd \"$ROOT\" && ./install.sh --update"
    return 1
  fi
  log "update: git -C $ROOT pull --ff-only"
  if git -C "$ROOT" pull --ff-only; then
    log "update: ok version=$(omh_version)"
  else
    log "update: pull failed"
    next "Resolve git state in $ROOT, then ./install.sh --update"
    return 1
  fi
  do_status || true
}

do_install() {
  if [[ ! -f "$META/SKILL.md" ]]; then
    log "missing $META/SKILL.md" >&2
    next "Restore skills/omh-meta/SKILL.md from the oh-my-headless repo"
    exit 1
  fi

  IFS=':' read -r -a dirs <<< "$SKILL_DIRS"
  local d
  for d in "${dirs[@]}"; do
    [[ -z "$d" ]] && continue
    mkdir -p "$d"
    link_dir "$META" "$d/omh-meta"
  done

  log "collection root: $ROOT version=$(omh_version)"
  log "registry entries:"
  local f
  shopt -s nullglob
  for f in "$ROOT/registry"/*.yaml; do
    local id must_flag
    id="$(basename "$f" .yaml)"
    must_flag=""
    yaml_must "$f" && must_flag=" [MUST]"
    log "  - ${id}${must_flag}"
  done
  shopt -u nullglob
  log "done. Load skill omh-meta for discover/configure/use."
  next "Verify: ./install.sh --status   Update collection: ./install.sh --update"
}

case "$CMD" in
  --help|-h|help) usage ;;
  --status|status) do_status ;;
  --update|update) do_update ;;
  install|--install|"") do_install ;;
  *)
    log "unknown arg: $CMD"
    usage
    exit 2
    ;;
esac
