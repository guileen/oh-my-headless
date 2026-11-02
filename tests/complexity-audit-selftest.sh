#!/usr/bin/env bash
# Unit-style check for the built-in complexity gate.
# Runs `omh complexity-audit --selftest` (the script's own cases) plus help/dispatch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMH="$ROOT/bin/omh"

fail() { printf 'complexity-audit-selftest: %s\n' "$*" >&2; exit 1; }

[[ -x "$OMH" ]] || fail "missing executable $OMH"
[[ -x "$ROOT/libexec/omh/complexity-audit.sh" ]] || fail "missing executable libexec/omh/complexity-audit.sh"
[[ -f "$ROOT/docs/complexity-budget-spec-2026-09-26.md" ]] || fail "missing budget spec"
[[ ! -e "$ROOT/docs/complexity-exemptions.txt" ]] || fail "this repo must not ship a project exemption list"

help_out="$("$OMH" help)"
grep -q 'complexity-audit' <<<"$help_out" || fail "omh help missing complexity-audit"
grep -q 'audit-complexity' <<<"$help_out" || fail "omh help missing audit-complexity alias"

map_out="$("$OMH" status || true)"
grep -q 'builtins: complexity-audit' <<<"$map_out" || fail "capability map missing complexity-audit"

gate_help="$("$OMH" complexity-audit --help)"
grep -q -- '--selftest' <<<"$gate_help" || fail "gate --help missing --selftest"
grep -q 'docs/complexity-budget-spec-2026-09-26.md' <<<"$gate_help" || fail "gate --help missing rule-doc path"

"$OMH" audit-complexity --help >/dev/null

if "$OMH" audit-complexity --not-a-real-flag >/dev/null 2>&1; then
  fail "unknown flag was accepted"
fi

printf 'complexity-audit-selftest: dispatch ok, running --selftest\n'
"$OMH" complexity-audit --selftest
