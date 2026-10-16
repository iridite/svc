#!/usr/bin/env bash
# Test suite for svc
set -euo pipefail

PASS=0
FAIL=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local desc="$3"
  if [[ "${expected}" == "${actual}" ]]; then
    echo "  ✓ ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${desc}: expected '${expected}', got '${actual}'"
    FAIL=$((FAIL + 1))
  fi
}

assert_match() {
  local pattern="$1"
  local actual="$2"
  local desc="$3"
  if [[ "${actual}" =~ ${pattern} ]]; then
    echo "  ✓ ${desc}"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${desc}: '${actual}' did not match pattern '${pattern}'"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Running svc test suite ==="

# 1. Version test
OUT="$(svc version)"
assert_match "svc version" "${OUT}" "svc version returns version string"

# 2. List test
OUT="$(svc list)"
assert_match "hapi.runner" "${OUT}" "svc list shows hapi.runner"
assert_match "openalice.relay" "${OUT}" "svc list shows openalice.relay"

# 3. JSON list test
OUT="$(svc list --json)"
assert_match '"label": "com.hapi.runner"' "${OUT}" "svc list --json includes hapi label"
assert_match '"label": "com.openalice.relay"' "${OUT}" "svc list --json includes relay label"

# 4. Which command
OUT="$(svc which relay)"
assert_match "Label:  com.openalice.relay" "${OUT}" "svc which relay resolves correct label"

# 5. Status command
OUT="$(svc status relay)"
assert_match "com.openalice.relay" "${OUT}" "svc status relay outputs label"

# 6. Status JSON
OUT="$(svc status relay --json)"
assert_match '"label": "com.openalice.relay"' "${OUT}" "svc status relay --json has valid label"
assert_match '"keepalive": false' "${OUT}" "svc status relay --json correctly detects KeepAlive=false"

# 7. Start and verify
svc start relay >/dev/null
OUT="$(svc status relay --json)"
assert_match '"running": 1' "${OUT}" "svc start relay puts service into running state"

# 8. Stop and verify
svc stop relay >/dev/null
OUT="$(svc status relay --json)"
assert_match '"running": 0' "${OUT}" "svc stop relay puts service into stopped state"

# 9. Enable / Disable lifecycle test
svc disable relay >/dev/null
OUT="$(svc status relay --json)"
assert_match '"disabled": 1' "${OUT}" "svc disable relay marks service disabled in json"

svc enable relay >/dev/null
OUT="$(svc status relay --json)"
assert_match '"disabled": 0' "${OUT}" "svc enable relay restores service enabled in json"

echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]] || exit 1
