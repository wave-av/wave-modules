#!/usr/bin/env bash
# Independent verification: foundation-gate secret-scan must not re-leak match
# bodies into stdout/stderr (public Actions logs). Synthetic tokens only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/ci/secret-scan.sh"
WORKFLOW="$ROOT/.github/workflows/_checks.yml"

[[ -f "$SCRIPT" ]] || { echo "FAIL: missing $SCRIPT"; exit 2; }
[[ -f "$WORKFLOW" ]] || { echo "FAIL: missing $WORKFLOW"; exit 2; }

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/secret-scan-test.XXXXXX")"
OUT="$WORKDIR/stdout.txt"
ERR="$WORKDIR/stderr.txt"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# Build a pattern-matching token at runtime so the committed test file cannot
# itself trip the live-tree scan.
SYNTH_TOKEN="sk-$(printf 'A%.0s' {1..20})"
printf 'note=%s\n' "$SYNTH_TOKEN" > "$WORKDIR/leak.txt"

run_scan() {
  bash "$SCRIPT" "$WORKDIR"
}

if grep -qE 'echo "\$HITS"' "$WORKFLOW"; then
  echo "FAIL: _checks.yml still echoes unredacted match bodies"
  exit 1
fi

if ! grep -q 'scripts/ci/secret-scan.sh' "$WORKFLOW"; then
  echo "FAIL: _checks.yml does not invoke scripts/ci/secret-scan.sh"
  exit 1
fi

rc=0
run_scan >"$OUT" 2>"$ERR" || rc=$?
if (( rc == 0 )); then
  echo "FAIL: secret-scan exited 0 on a synthetic hit (expected 1)"
  exit 1
fi
if (( rc == 2 )); then
  echo "FAIL: secret-scan exited 2 (scanner error)"
  exit 1
fi

COMBINED="$(cat "$OUT" "$ERR")"
if printf '%s' "$COMBINED" | grep -Fq "$SYNTH_TOKEN"; then
  echo "FAIL: synthetic match body present in scanner output (would leak in public Actions logs)"
  exit 1
fi
if ! printf '%s' "$COMBINED" | grep -q 'match redacted'; then
  echo "FAIL: expected redacted file:line output, none found"
  exit 1
fi
if ! printf '%s' "$COMBINED" | grep -q 'leak.txt:1'; then
  echo "FAIL: expected leak.txt:1 in redacted output"
  exit 1
fi
echo "PASS: synthetic hit is blocked and redacted"

EMPTY="$(mktemp -d "${TMPDIR:-/tmp}/secret-scan-empty.XXXXXX")"
trap 'rm -rf "$WORKDIR" "$EMPTY"' EXIT
rc=0
bash "$SCRIPT" "$EMPTY" >"$OUT" 2>"$ERR" || rc=$?
if (( rc != 0 )); then
  echo "FAIL: clean tree exited $rc (expected 0)"
  exit 1
fi
if ! grep -q 'secret-scan clean' "$OUT"; then
  echo "FAIL: clean tree did not print secret-scan clean"
  exit 1
fi
echo "PASS: clean tree"

echo "secret-scan.test.sh: all checks passed"
