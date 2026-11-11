#!/usr/bin/env bash
# Fail-closed secret scan used by foundation-gate (_checks.yml).
#
# Public GitHub Actions logs are world-readable. Never print match bodies —
# file:line only, same redaction as scripts/public-repo-guard/content-policy.sh.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT" || { echo "::error::secret-scan: cannot cd to $ROOT"; exit 2; }

# Real-secret patterns. Lines tagged "pragma: allowlist secret" (e.g. test
# fixtures / regex definitions) are skipped. pragma: allowlist secret
PATTERN='(sk-[A-Za-z0-9]{20}|sk_(live|test)_[A-Za-z0-9]{20}|npm_[A-Za-z0-9]{30}|sbp_[a-f0-9]{40}|github_pat_[A-Za-z0-9_]{40}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30}|AIzaSy[A-Za-z0-9_-]{20}|xai-[A-Za-z0-9]{40}|xoxb-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY)'

HITS=$(grep -rIEn "$PATTERN" \
    --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist . \
    | grep -v 'allowlist secret' \
    | { [ -f .github/.secret-allowlist ] && grep -vFf .github/.secret-allowlist || cat; } || true)

if [ -n "$HITS" ]; then
  echo "::error::secret-like pattern found — do not commit credentials"
  # Print only file:line — NEVER the matched content.
  printf '%s\n' "$HITS" | sed -E 's/^([^:]+:[0-9]+):.*/\1: «match redacted — open this location to view»/'
  exit 1
fi
echo "secret-scan clean"
