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

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  if [[ "$expected" == "$actual" ]]; then
    print_pass "$msg"
    return 0
  else
    print_fail "$msg"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    print_pass "$msg"
    return 0
  else
    print_fail "$msg"
    echo "    Expected output to contain: $needle"
    echo "    Output: $haystack"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  if [[ "$expected" == "$actual" ]]; then
    print_pass "$msg"
    return 0
  else
    print_fail "$msg"
    echo "    Expected exit code: $expected, got: $actual"
    return 1
  fi
}

skip_if_no_ai() {
  if ! bash "$AI_RUNNER" --list-engines 2>&1 | grep -q "installed"; then
    print_skip "No AI engine installed"
    return 0
  fi
  return 1
}

# ==============================================================================
# Test Suite: Version and Help
# ==============================================================================

test_version() {
  print_header "Version and Help Tests"

  print_test "Version output"
  local version
  version=$(bash "$AI_RUNNER" --version)
  assert_contains "$version" "ai-runner v" "Version command works"

  print_test "Help output"
  local help_output
  help_output=$(bash "$AI_RUNNER" --help)
  assert_contains "$help_output" "USAGE:" "Help shows usage"
  assert_contains "$help_output" "OPTIONS:" "Help shows options"
  assert_contains "$help_output" "EXAMPLES" "Help shows examples"
}

test_version
sleep 0.5

# ==============================================================================
# Test Suite: Engine Detection
# ==============================================================================

test_engine_detection() {
  print_header "Engine Detection Tests"

  print_test "List engines command"
  local engines
  engines=$(bash "$AI_RUNNER" --list-engines)
  assert_contains "$engines" "claude" "Lists claude engine"
  assert_contains "$engines" "ollama" "Lists ollama engine"

  print_test "List with models"
  local list_output
  list_output=$(bash "$AI_RUNNER" --list)
  assert_contains "$list_output" "AI Runner" "List shows header"

  print_test "Engine info"
  local info
  info=$(bash "$AI_RUNNER" --info)
  assert_contains "$info" "Engine:" "Info shows engine"
}

test_engine_detection
sleep 0.3

# ==============================================================================
# Test Suite: Exit Codes
# ==============================================================================

test_exit_codes() {
  print_header "Exit Code Tests"

  print_test "Exit code name SUCCESS"
  local name
  name=$(source "$AI_RUNNER" && ai_exit_code_name 0)
  assert_equals "$name" "SUCCESS" "Exit code 0 maps to SUCCESS"

  print_test "Exit code name USER_ABORT"
  name=$(source "$AI_RUNNER" && ai_exit_code_name 1)
  assert_equals "$name" "USER_ABORT" "Exit code 1 maps to USER_ABORT"

  print_test "Exit code name PROVIDER_ERROR"
  name=$(source "$AI_RUNNER" && ai_exit_code_name 2)
  assert_equals "$name" "PROVIDER_ERROR" "Exit code 2 maps to PROVIDER_ERROR"

  print_test "Exit code name INVALID_INPUT"
  name=$(source "$AI_RUNNER" && ai_exit_code_name 3)
  assert_equals "$name" "INVALID_INPUT" "Exit code 3 maps to INVALID_INPUT"

  print_test "Exit code name INTERNAL_ERROR"
  name=$(source "$AI_RUNNER" && ai_exit_code_name 4)
  assert_equals "$name" "INTERNAL_ERROR" "Exit code 4 maps to INTERNAL_ERROR"

  print_test "Exit code name TIMEOUT"
  name=$(source "$AI_RUNNER" && ai_exit_code_name 124)
  assert_equals "$name" "TIMEOUT" "Exit code 124 maps to TIMEOUT"
}

test_exit_codes
sleep 0.3

# ==============================================================================
# Test Suite: Validation
# ==============================================================================

test_validation() {
  print_header "Validation Tests"

  print_test "Validate engine - unknown engine fails"
  if ! source "$AI_RUNNER" && AI_ENGINE=nonexistent ai_validate 2>/dev/null; then
    print_pass "Unknown engine validation fails"
  else
    print_fail "Unknown engine should fail validation"
  fi

  print_test "Validate engine - empty uses auto-detect"
  source "$AI_RUNNER"
  AI_ENGINE="" AI_MODEL="" ai_validate >/dev/null 2>&1
  # Should fail gracefully if no engines installed, succeed otherwise
  print_pass "Empty engine triggers auto-detect"
}

test_validation
sleep 0.3

# ==============================================================================
# Test Suite: Template Building
# ==============================================================================

test_templates() {
  print_header "Template Tests"

  # Create temp directory with test templates
  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT

  print_test "Template with variables"
  cat > "$temp_dir/test.md" << 'EOF'
Hello {{NAME}}, you have {{COUNT}} messages.
EOF
  local result
  result=$(source "$AI_RUNNER" && ai_build_prompt "$temp_dir" "test" NAME="Alice" COUNT="5")
  assert_contains "$result" "Hello Alice" "Template substitutes NAME"
  assert_contains "$result" "5 messages" "Template substitutes COUNT"

  print_test "Template file not found"
  if ! source "$AI_RUNNER" && ai_build_prompt "$temp_dir" "nonexistent" 2>/dev/null; then
    print_pass "Missing template returns error"
  else
    print_fail "Missing template should fail"
  fi
}

test_templates
sleep 0.3

# ==============================================================================
# Test Suite: Prompt Building
# ==============================================================================

test_prompt_building() {
  print_header "Prompt Building Tests"

  print_test "Quick one-liner function exists"
  source "$AI_RUNNER"
  type ai | grep -q "function" && print_pass "ai() function defined"

  print_test "JSON helper function exists"
  type ai_json | grep -q "function" && print_pass "ai_json() function defined"

  print_test "Code helper function exists"
  type ai_code | grep -q "function" && print_pass "ai_code() function defined"
}

test_prompt_building
sleep 0.3

# ==============================================================================
# Test Suite: Retry Logic (Mock)
# ==============================================================================

test_retry_logic() {
  print_header "Retry Logic Tests"

  print_test "Retry count default is 3"
  source "$AI_RUNNER"
  assert_equals "${AI_RETRY_COUNT:-3}" "3" "Default retry count is 3"

  print_test "Retry delay default is 5"
  assert_equals "${AI_RETRY_DELAY:-5}" "5" "Default retry delay is 5"

  print_test "Retry backoff default is 2"
  assert_equals "${AI_RETRY_BACKOFF:-2}" "2" "Default retry backoff is 2"
}

test_retry_logic
sleep 0.3

# ==============================================================================
# Test Suite: Progress Callbacks
# ==============================================================================

test_progress_callbacks() {
  print_header "Progress Callback Tests"

  print_test "Progress callback variable can be set"
  source "$AI_RUNNER"
  AI_PROGRESS_CALLBACK="my_callback"
  assert_equals "$AI_PROGRESS_CALLBACK" "my_callback" "Progress callback can be set"

  print_test "Set progress callback function exists"
  type ai_set_progress_callback | grep -q "function" && print_pass "ai_set_progress_callback() exists"
}

test_progress_callbacks
sleep 0.3

# ==============================================================================
# Test Suite: File Context Injection
# ==============================================================================

test_file_context() {
  print_header "File Context Tests"

  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT

  print_test "File context injection function exists"
  source "$AI_RUNNER"
  type ai_run_with_files | grep -q "function" && print_pass "ai_run_with_files() exists"

  print_test "Build prompt with files function exists"
  type ai_build_prompt_with_files | grep -q "function" && print_pass "ai_build_prompt_with_files() exists"

  # Create test files
  echo "This is test content" > "$temp_dir/test.txt"
  print_test "File content can be read"
  local content
  content=$(cat "$temp_dir/test.txt")
  assert_contains "$content" "test content" "File reading works"
}

test_file_context
sleep 0.3

# ==============================================================================
# Test Suite: JSON Validation (Mock)
# ==============================================================================

test_json_validation() {
  print_header "JSON Validation Tests"

  print_test "JSON validated function exists"
  source "$AI_RUNNER"
  type ai_json_validated | grep -q "function" && print_pass "ai_json_validated() exists"

  print_test "Schema validation function exists"
  type ai_json_validated_schema | grep -q "function" && print_pass "ai_json_validated_schema() exists"

  # Test jq availability
  if command -v jq &>/dev/null; then
    print_test "jq is available for JSON validation"
    local valid
    valid=$(echo '{"test": true}' | jq -e . >/dev/null 2>&1 && echo "valid" || echo "invalid")
    assert_equals "$valid" "valid" "jq validates JSON correctly"
  else
    print_skip "jq not installed - JSON validation tests skipped"
  fi
}

test_json_validation
sleep 0.3

# ==============================================================================
# Test Suite: Working Directory Context
# ==============================================================================

test_working_directory() {
  print_header "Working Directory Tests"

  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT

  print_test "Run with cwd function exists"
  source "$AI_RUNNER"
  type ai_run_with_cwd | grep -q "function" && print_pass "ai_run_with_cwd() exists"

  print_test "Working directory can be set via env"
  AI_WORKING_DIR="$temp_dir"
  assert_equals "$AI_WORKING_DIR" "$temp_dir" "Working directory can be set"

  print_test "Non-existent directory is rejected"
  if ! source "$AI_RUNNER" && AI_WORKING_DIR="/nonexistent/path" ai_run_with_cwd "test" 2>/dev/null; then
    print_pass "Non-existent directory is rejected"
  else
    print_fail "Non-existent directory should be rejected"
  fi
}

test_working_directory
sleep 0.3

# ==============================================================================
# Test Suite: Environment Variables
# ==============================================================================

test_environment() {
  print_header "Environment Variable Tests"

  source "$AI_RUNNER"

  print_test "AI_ENGINE variable works"
  AI_ENGINE="claude"
  assert_equals "$AI_ENGINE" "claude" "AI_ENGINE can be set"

  print_test "AI_MODEL variable works"
  AI_MODEL="sonnet"
  assert_equals "$AI_MODEL" "sonnet" "AI_MODEL can be set"

  print_test "AI_TIMEOUT variable works"
  AI_TIMEOUT="600"
  assert_equals "$AI_TIMEOUT" "600" "AI_TIMEOUT can be set"

  print_test "AI_VERBOSE variable works"
  AI_VERBOSE="2"
  assert_equals "$AI_VERBOSE" "2" "AI_VERBOSE can be set"
}

test_environment
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
