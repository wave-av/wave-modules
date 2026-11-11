#!/usr/bin/env bash
# Independent verification for content-policy ignore-file handling.
# Synthetic BLOCK strings only. Nothing here is a live credential.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/scripts/public-repo-guard/content-policy.sh"
command -v rg >/dev/null 2>&1 || { echo "FAIL: ripgrep (rg) required"; exit 2; }
[[ -x "$SCRIPT" || -f "$SCRIPT" ]] || { echo "FAIL: missing $SCRIPT"; exit 2; }

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/content-policy-test.XXXXXX")"
OUT="$WORKDIR/stdout.txt"
ERR="$WORKDIR/stderr.txt"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

# Fake Cloudflare account_id shape (32 hex chars). Not a live account.
PAYLOAD='account_id: "0123456789abcdef0123456789abcdef"'
printf '%s\n' "$PAYLOAD" > "$WORKDIR/notes.txt"

run_policy() {
  # Unset so this test does not depend on CI private-repo injection.
  env -u GUARD_PRIVATE_REPOS bash "$SCRIPT" "$WORKDIR"
}

expect_block() {
  local label="$1"
  local rc=0
  run_policy >"$OUT" 2>"$ERR" || rc=$?
  if (( rc == 0 )); then
    echo "FAIL: $label: content-policy exited 0 (expected BLOCK)"
    cat "$OUT" "$ERR"
    exit 1
  fi
  if (( rc == 2 )); then
    echo "FAIL: $label: content-policy exited 2 (scanner error)"
    cat "$OUT" "$ERR"
    exit 1
  fi
  echo "PASS: $label (exit $rc)"
}

expect_ok() {
  local label="$1"
  local rc=0
  run_policy >"$OUT" 2>"$ERR" || rc=$?
  if (( rc != 0 )); then
    echo "FAIL: $label: content-policy exited $rc (expected 0)"
    cat "$OUT" "$ERR"
    exit 1
  fi
  echo "PASS: $label"
}

expect_block "baseline leak without ignore files"

printf '*\n' > "$WORKDIR/.rgignore"
expect_block ".rgignore must not hide BLOCK hits"

rm -f "$WORKDIR/.rgignore"
printf '*\n' > "$WORKDIR/.ignore"
expect_block ".ignore must not hide BLOCK hits"

rm -f "$WORKDIR/.ignore"
printf '*\n' > "$WORKDIR/.fdignore"
expect_block ".fdignore must not hide BLOCK hits"

rm -f "$WORKDIR/.fdignore"
printf 'notes.txt\n' > "$WORKDIR/.guardignore"
expect_ok "documented .guardignore still excludes a named path"

echo "content-policy.test.sh: all checks passed"
