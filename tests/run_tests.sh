#!/usr/bin/env bash
# ai-runner Test Suite
# Run with: ./tests/run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_RUNNER="${SCRIPT_DIR}/../ai-runner.sh"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test() {
  echo -e "\n${YELLOW}TEST:${NC} $1"
}

print_pass() {
  echo -e "${GREEN}✓ PASS:${NC} $1"
  ((TESTS_PASSED++)) || true
}

print_fail() {
  echo -e "${RED}✗ FAIL:${NC} $1"
  ((TESTS_FAILED++)) || true
}

print_skip() {
  echo -e "${YELLOW}⊘ SKIP:${NC} $1"
  ((TESTS_SKIPPED++)) || true
}

# Check if ShellCheck is available
shellcheck_available() {
  command -v shellcheck &>/dev/null
}

# Run ShellCheck on ai-runner.sh
test_shellcheck() {
  print_header "ShellCheck Code Quality Tests"

  if ! shellcheck_available; then
    print_skip "ShellCheck not installed (install with: brew install shellcheck)"
    return 0
  fi

  print_test "ShellCheck available"
  print_pass "ShellCheck is installed"

  print_test "ShellCheck on ai-runner.sh"
  local output
  output=$(shellcheck -x -s bash "$AI_RUNNER" 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_pass "ai-runner.sh passes ShellCheck"
  else
    # Count errors
    local error_count
    error_count=$(echo "$output" | grep -c "error" || echo "0")
    print_fail "ai-runner.sh has $error_count ShellCheck issues"

    if [[ "${AI_VERBOSE:-0}" -ge 2 ]]; then
      echo "$output" | head -20
    fi
  fi

  print_test "ShellCheck on test scripts"
  output=$(shellcheck -x -s bash tests/run_tests.sh 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_pass "tests/run_tests.sh passes ShellCheck"
  else
    print_fail "tests/run_tests.sh has ShellCheck issues"
  fi
}

test_shellcheck
sleep 0.3

# ==============================================================================
# Summary
# ==============================================================================

print_header "Test Summary"

total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
echo ""
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
echo -e "Total:  $total"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
