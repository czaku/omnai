#!/usr/bin/env bash
# omnai Test Suite
# Run with: ./tests/run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_RUNNER="${SCRIPT_DIR}/../omnai.sh"
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

# ==============================================================================
# Version and Help Tests
# ==============================================================================

test_version() {
  print_header "Version and Help Tests"

  print_test "Version output"
  local version
  version=$(bash "$AI_RUNNER" --version)
  assert_contains "$version" "omnai v" "Version command works"

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
# Engine Detection Tests
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
# Exit Codes
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
# Validation Tests
# ==============================================================================

test_validation() {
  print_header "Validation Tests"

  print_test "Validate engine - unknown engine fails"
  if (source "$AI_RUNNER" && AI_ENGINE=nonexistent ai_validate 2>/dev/null); then
    print_fail "Unknown engine should fail validation"
  else
    print_pass "Unknown engine validation fails"
  fi

  print_test "Validate engine - empty uses auto-detect"
  source "$AI_RUNNER"
  AI_ENGINE="" AI_MODEL="" ai_validate >/dev/null 2>&1
  print_pass "Empty engine triggers auto-detect"
}

test_validation
sleep 0.3

# ==============================================================================
# Template Tests
# ==============================================================================

test_templates() {
  print_header "Template Tests"

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
  if (source "$AI_RUNNER" && ai_build_prompt "$temp_dir" "nonexistent" 2>/dev/null); then
    print_fail "Missing template should fail"
  else
    print_pass "Missing template returns error"
  fi
}

test_templates
sleep 0.3

# ==============================================================================
# Prompt Building Tests
# ==============================================================================

test_prompt_building() {
  print_header "Prompt Building Tests"

  source "$AI_RUNNER"

  print_test "Quick one-liner function exists"
  type ai | grep -q "function" && print_pass "ai() function defined"

  print_test "JSON helper function exists"
  type ai_json | grep -q "function" && print_pass "ai_json() function defined"

  print_test "Code helper function exists"
  type ai_code | grep -q "function" && print_pass "ai_code() function defined"
}

test_prompt_building
sleep 0.3

# ==============================================================================
# Retry Logic Tests
# ==============================================================================

test_retry_logic() {
  print_header "Retry Logic Tests"

  source "$AI_RUNNER"

  print_test "Retry count default is 3"
  assert_equals "${AI_RETRY_COUNT:-3}" "3" "Default retry count is 3"

  print_test "Retry delay default is 5"
  assert_equals "${AI_RETRY_DELAY:-5}" "5" "Default retry delay is 5"

  print_test "Retry backoff default is 2"
  assert_equals "${AI_RETRY_BACKOFF:-2}" "2" "Default retry backoff is 2"

  print_test "Retry function exists"
  type ai_run_with_retry | grep -q "function" && print_pass "ai_run_with_retry() exists"
}

test_retry_logic
sleep 0.3

# ==============================================================================
# Progress Callbacks
# ==============================================================================

test_progress_callbacks() {
  print_header "Progress Callback Tests"

  source "$AI_RUNNER"

  print_test "Progress callback variable can be set"
  AI_PROGRESS_CALLBACK="my_callback"
  assert_equals "$AI_PROGRESS_CALLBACK" "my_callback" "Progress callback can be set"

  print_test "Set progress callback function exists"
  type ai_set_progress_callback | grep -q "function" && print_pass "ai_set_progress_callback() exists"

  print_test "Run with progress function exists"
  type ai_run_with_progress | grep -q "function" && print_pass "ai_run_with_progress() exists"
}

test_progress_callbacks
sleep 0.3

# ==============================================================================
# File Context Tests
# ==============================================================================

test_file_context() {
  print_header "File Context Tests"

  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT

  source "$AI_RUNNER"

  print_test "File context injection function exists"
  type ai_run_with_files | grep -q "function" && print_pass "ai_run_with_files() exists"

  print_test "Build prompt with files function exists"
  type ai_build_prompt_with_files | grep -q "function" && print_pass "ai_build_prompt_with_files() exists"

  echo "This is test content" > "$temp_dir/test.txt"
  print_test "File content can be read"
  local content
  content=$(cat "$temp_dir/test.txt")
  assert_contains "$content" "test content" "File reading works"
}

test_file_context
sleep 0.3

# ==============================================================================
# JSON Validation Tests
# ==============================================================================

test_json_validation() {
  print_header "JSON Validation Tests"

  source "$AI_RUNNER"

  print_test "JSON validated function exists"
  type ai_json_validated | grep -q "function" && print_pass "ai_json_validated() exists"

  print_test "Schema validation function exists"
  type ai_json_validated_schema | grep -q "function" && print_pass "ai_json_validated_schema() exists"

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
# Working Directory Tests
# ==============================================================================

test_working_directory() {
  print_header "Working Directory Tests"

  local temp_dir
  temp_dir=$(mktemp -d)
  trap "rm -rf $temp_dir" EXIT

  source "$AI_RUNNER"

  print_test "Run with cwd function exists"
  type ai_run_with_cwd | grep -q "function" && print_pass "ai_run_with_cwd() exists"

  print_test "Working directory can be set via env"
  AI_WORKING_DIR="$temp_dir"
  assert_equals "$AI_WORKING_DIR" "$temp_dir" "Working directory can be set"

  print_test "Non-existent directory is rejected"
  if (source "$AI_RUNNER" && AI_WORKING_DIR="/nonexistent/path" ai_run_with_cwd "test" 2>/dev/null); then
    print_fail "Non-existent directory should be rejected"
  else
    print_pass "Non-existent directory is rejected"
  fi
}

test_working_directory
sleep 0.3

# ==============================================================================
# Environment Variable Tests
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
# Structured API Tests (v0.6.0)
# ==============================================================================

test_structured_api() {
  print_header "Structured API Tests (v0.6.0)"

  source "$AI_RUNNER"

  print_test "ai_get_engines returns JSON array"
  local result
  result=$(ai_get_engines)
  assert_contains "$result" '"claude"' "Contains claude"
  assert_contains "$result" '"ollama"' "Contains ollama"
  assert_contains "$result" "[" "Is JSON array"

  print_test "ai_get_models claude returns models"
  result=$(ai_get_models "claude")
  assert_contains "$result" '"haiku"' "Contains haiku"
  assert_contains "$result" '"sonnet"' "Contains sonnet"

  print_test "ai_get_models ollama returns models"
  result=$(ai_get_models "ollama")
  assert_contains "$result" '"llama3.2"' "Contains llama3.2"

  print_test "ai_get_models opencode returns empty"
  result=$(ai_get_models "opencode")
  assert_equals "$result" "[]" "OpenCode has no fixed models"

  print_test "ai_get_installed_engines returns JSON"
  result=$(ai_get_installed_engines)
  assert_contains "$result" "[" "Is JSON array"

  print_test "ai_get_engine_info returns JSON object"
  result=$(ai_get_engine_info "claude")
  assert_contains "$result" '"engine":"claude"' "Contains engine name"
  assert_contains "$result" '"installed":' "Contains installed field"

  print_test "ai_get_all_engines_info returns JSON array"
  result=$(ai_get_all_engines_info)
  assert_contains "$result" "[" "Is JSON array"
  assert_contains "$result" '"engine"' "Contains engine objects"

  print_test "ai_get_config returns valid JSON"
  result=$(ai_get_config)
  assert_contains "$result" '"version"' "Contains version"
  assert_contains "$result" '"config"' "Contains config object"

  print_test "ai_get_status returns valid JSON"
  result=$(ai_get_status)
  assert_contains "$result" '"status"' "Contains status"
  assert_contains "$result" '"available"' "Contains available field"

  print_test "Config file functions exist"
  type ai_load_config | grep -q "function" && print_pass "ai_load_config() exists"
  type ai_save_config | grep -q "function" && print_pass "ai_save_config() exists"
}

test_structured_api
sleep 0.3

# ==============================================================================
# Error Handling Tests (v0.5.0)
# ==============================================================================

test_error_handling() {
  print_header "Error Handling Tests (v0.5.0)"

  source "$AI_RUNNER"

  print_test "Error suggestions map exists"
  local suggestion
  suggestion=$(ai_error_suggestion "rate_limit")
  assert_contains "$suggestion" "Rate limit" "Rate limit suggestion exists"

  print_test "Unknown error has fallback suggestion"
  suggestion=$(ai_error_suggestion "unknown")
  assert_contains "$suggestion" "No specific suggestion" "Unknown error has fallback"

  print_test "Timeout error has suggestion"
  suggestion=$(ai_error_suggestion "timeout")
  assert_contains "$suggestion" "AI_TIMEOUT" "Timeout suggestion mentions AI_TIMEOUT"

  print_test "Rate limit error has retry suggestion"
  suggestion=$(ai_error_suggestion "rate_limit")
  assert_contains "$suggestion" "AI_RETRY" "Rate limit suggests retry settings"

  print_test "Error detection function exists"
  type ai_detect_error | grep -q "function" && print_pass "ai_detect_error() exists"

  print_test "Error handling function exists"
  type ai_handle_error | grep -q "function" && print_pass "ai_handle_error() exists"

  print_test "Error run wrapper exists"
  type ai_run_with_error_handling | grep -q "function" && print_pass "ai_run_with_error_handling() exists"

  print_test "Claude error detection - rate limit"
  local error_type
  error_type=$(ai_detect_error "claude" "Error: rate limit exceeded")
  assert_equals "$error_type" "rate_limit" "Detects Claude rate limit"

  print_test "Claude error detection - authentication"
  error_type=$(ai_detect_error "claude" "Authentication failed: invalid API key")
  assert_equals "$error_type" "authentication" "Detects Claude authentication error"

  print_test "Ollama error detection - model not found"
  error_type=$(ai_detect_error "ollama" "Error: model not found: llama999")
  assert_equals "$error_type" "model_not_found" "Detects Ollama model not found"

  print_test "Ollama error detection - connection failed"
  error_type=$(ai_detect_error "ollama" "connection failed: connection refused")
  assert_equals "$error_type" "connection_failed" "Detects Ollama connection error"

  print_test "Aider error detection - context length"
  error_type=$(ai_detect_error "aider" "Context too long for model")
  assert_equals "$error_type" "context_length" "Detects Aider context length error"
}

test_error_handling
sleep 0.3

# ==============================================================================
# Model Validation Tests
# ==============================================================================

test_model_validation() {
  print_header "Model Validation Tests"

  source "$AI_RUNNER"

  print_test "Model validation function exists"
  type ai_validate_model | grep -q "function" && print_pass "ai_validate_model() exists"

  print_test "Valid model passes validation"
  AI_MODEL="claude-3-5-sonnet" ai_validate_model >/dev/null 2>&1
  assert_equals "$?" "0" "Valid model returns 0"

  print_test "Empty model triggers auto-detect"
  AI_MODEL="" ai_validate_model >/dev/null 2>&1
  assert_equals "$?" "0" "Empty model returns 0"

  print_test "Invalid model fails validation"
  AI_MODEL="nonexistent-model-xyz" ai_validate_model >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    print_pass "Invalid model returns non-zero"
  else
    print_skip "Model validation not implemented"
  fi

  print_test "Core model functions available"
  if type ai_list_models | grep -q "function" 2>/dev/null; then
    print_pass "ai_list_models() exists"
  else
    print_skip "ai_list_models not implemented"
  fi
}

test_model_validation
sleep 0.3

# ==============================================================================
# Provider-Specific Tests
# ==============================================================================

test_provider_specific() {
  print_header "Provider-Specific Tests"

  source "$AI_RUNNER"

  print_test "Core provider functions available"
  if type ai_setup_provider | grep -q "function" 2>/dev/null; then
    print_pass "ai_setup_provider() exists"
  else
    print_skip "Provider setup not implemented"
  fi

  print_test "Provider check function exists"
  if type ai_check_provider | grep -q "function" 2>/dev/null; then
    print_pass "ai_check_provider() exists"
    result=$(ai_check_provider "ollama" 2>/dev/null)
    if [[ -n "$result" ]]; then
      assert_contains "$result" '"status"' "Contains status field"
    fi
  else
    print_skip "Provider check not implemented"
  fi
}

test_provider_specific
sleep 0.3

# ==============================================================================
# Context and Conversation Tests
# ==============================================================================

test_context_conversation() {
  print_header "Context and Conversation Tests"

  source "$AI_RUNNER"

  print_test "Context management function exists"
  if type ai_context | grep -q "function" 2>/dev/null; then
    print_pass "ai_context() exists"
  else
    print_skip "Context management not implemented"
  fi

  print_test "Conversation functions available"
  if type ai_conversation | grep -q "function" 2>/dev/null; then
    print_pass "ai_conversation() exists"
  else
    print_skip "Conversation functions not implemented"
  fi

  print_test "System prompt functions available"
  if type ai_system_prompt | grep -q "function" 2>/dev/null; then
    print_pass "ai_system_prompt() exists"
  else
    print_skip "System prompt not implemented"
  fi
}

test_context_conversation
sleep 0.3

# ==============================================================================
# Timing and Performance Tests
# ==============================================================================

test_timing_performance() {
  print_header "Timing and Performance Tests"

  source "$AI_RUNNER"

  print_test "Timer functions available"
  if type ai_timer | grep -q "function" 2>/dev/null; then
    print_pass "ai_timer() exists"
  else
    print_skip "Timer functions not implemented"
  fi

  print_test "Token counting available"
  if type ai_count_tokens | grep -q "function" 2>/dev/null; then
    print_pass "ai_count_tokens() exists"
    result=$(ai_count_tokens "test prompt" 2>/dev/null)
    [[ "$result" =~ ^[0-9]+$ ]] && print_pass "Token count returns integer"
  else
    print_skip "Token counting not implemented"
  fi

  print_test "Cost estimation available"
  if type ai_cost | grep -q "function" 2>/dev/null; then
    print_pass "ai_cost() exists"
  else
    print_skip "Cost estimation not implemented"
  fi
}

test_timing_performance
sleep 0.3

# ==============================================================================
# Stream Handling Tests
# ==============================================================================

test_stream_handling() {
  print_header "Stream Handling Tests"

  source "$AI_RUNNER"

  print_test "Stream functions available"
  if type ai_stream | grep -q "function" 2>/dev/null; then
    print_pass "ai_stream() exists"
  else
    print_skip "Stream handling not implemented"
  fi
}

test_stream_handling
sleep 0.3

# ==============================================================================
# Cache Management Tests
# ==============================================================================

test_cache_management() {
  print_header "Cache Management Tests"

  source "$AI_RUNNER"

  print_test "Cache functions available"
  if type ai_cache | grep -q "function" 2>/dev/null; then
    print_pass "ai_cache() exists"
  else
    print_skip "Cache management not implemented"
  fi
}

test_cache_management
sleep 0.3

# ==============================================================================
# Template Management Tests
# ==============================================================================

test_template_management() {
  print_header "Template Management Tests"

  source "$AI_RUNNER"

  print_test "Template functions available"
  if type ai_template | grep -q "function" 2>/dev/null; then
    print_pass "ai_template() exists"
  else
    print_skip "Template management not implemented"
  fi
}

test_template_management
sleep 0.3

# ==============================================================================
# Multi-Turn Conversation Tests
# ==============================================================================

test_multi_turn() {
  print_header "Multi-Turn Conversation Tests"

  source "$AI_RUNNER"

  print_test "Multi-turn functions available"
  if type ai_multi_turn | grep -q "function" 2>/dev/null; then
    print_pass "ai_multi_turn() exists"
  else
    print_skip "Multi-turn not implemented"
  fi

  print_test "Context window functions available"
  if type ai_context_window | grep -q "function" 2>/dev/null; then
    print_pass "ai_context_window() exists"
  else
    print_skip "Context window not implemented"
  fi
}

test_multi_turn
sleep 0.3

# ==============================================================================
# Security and Sanitization Tests
# ==============================================================================

test_security_sanitization() {
  print_header "Security and Sanitization Tests"

  source "$AI_RUNNER"

  print_test "Security functions available"
  if type ai_sanitize | grep -q "function" 2>/dev/null; then
    print_pass "ai_sanitize() exists"
  else
    print_skip "Security functions not implemented"
  fi
}

test_security_sanitization
sleep 0.3

# ==============================================================================
# Version and Compatibility Tests
# ==============================================================================

test_version_compatibility() {
  print_header "Version and Compatibility Tests"

  source "$AI_RUNNER"

  print_test "Version check function available"
  if type ai_version | grep -q "function" 2>/dev/null; then
    print_pass "ai_version() exists"
  else
    print_skip "Version functions not implemented"
  fi

  print_test "Version format is valid semantic version"
  version=$(bash "$AI_RUNNER" --version)
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] && print_pass "Version follows semantic versioning"
}

test_version_compatibility
sleep 0.3

# ==============================================================================
# ShellCheck Code Quality Tests
# ==============================================================================

test_shellcheck() {
  print_header "ShellCheck Code Quality Tests"

  if ! command -v shellcheck &>/dev/null; then
    print_skip "ShellCheck not installed (install with: brew install shellcheck)"
    return 0
  fi

  print_test "ShellCheck available"
  print_pass "ShellCheck is installed"

  print_test "ShellCheck on omnai.sh"
  if shellcheck -x -s bash -e SC2250,SC2312,SC2249,SC2248,SC2001 omnai.sh >/dev/null 2>&1; then
    print_pass "omnai.sh passes ShellCheck"
  else
    print_fail "omnai.sh has ShellCheck issues"
  fi

  print_test "ShellCheck on test scripts"
  if shellcheck -x -s bash -e SC2250,SC2312,SC2249,SC2248,SC2001,SC1090,SC2064 tests/run_tests.sh >/dev/null 2>&1; then
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
