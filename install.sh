#!/usr/bin/env bash
# Thin wrapper → bin/omh install (or status/update/doctor passthrough).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OMH="$ROOT/bin/omh"
case "${1:-}" in
  --help|-h|help) exec "$OMH" help ;;
  --status|status) exec "$OMH" status ;;
  --update|update) exec "$OMH" update ;;
  --doctor|doctor) exec "$OMH" doctor ;;
  ""|install|--install) exec "$OMH" install ;;
  *)
    printf 'omh: unknown arg: %s (use ./install.sh or omh help)\n' "$1" >&2
    exec "$OMH" help
    ;;
esac
