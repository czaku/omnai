#!/usr/bin/env bash
# context-health.sh - Context rot detection and health tracking for AI sessions
# Part of omnai - Universal local AI agent runner
#
# Implements: repetition detection, hallucination detection, scope creep,
# forgetting detection, quality scoring, and token utilization tracking.
#
# Usage as library:
#   source context-health.sh
#   context_health_init "session-id"
#   context_check_repetition "$output"
#   context_calculate_score
#
# Configuration (environment variables):
#   AI_STATE_DIR           - State directory (default: .ai-state)
#   AI_SESSION_STATE_FILE  - Session state filename (default: SESSION-STATE.md)
#   AI_SESSION_PLAN_FILE   - Session plan filename (default: SESSION-PLAN.md)
#   CONTEXT_MAX_TOKENS     - Max context tokens (default: 200000)
#   CONTEXT_WARNING_THRESHOLD   - Warning threshold % (default: 70)
#   CONTEXT_CRITICAL_THRESHOLD  - Critical threshold % (default: 85)

set -euo pipefail

CONTEXT_HEALTH_VERSION="1.0.0"

# Configuration
CONTEXT_MAX_TOKENS=${CONTEXT_MAX_TOKENS:-200000}
CONTEXT_WARNING_THRESHOLD=${CONTEXT_WARNING_THRESHOLD:-70}    # 70%
CONTEXT_CRITICAL_THRESHOLD=${CONTEXT_CRITICAL_THRESHOLD:-85}  # 85%
CONTEXT_CHARS_PER_TOKEN=${CONTEXT_CHARS_PER_TOKEN:-4}

# Rot signal weights for quality score
WEIGHT_REPETITION=15
WEIGHT_CONTRADICTION=20
WEIGHT_FORGETTING=15
WEIGHT_HALLUCINATION=25
WEIGHT_SCOPE_CREEP=5

# State directory - configurable for different tools
# Tools can override: AI_STATE_DIR=".myapp" or AI_STATE_DIR=".ralfie"
CONTEXT_STATE_DIR="${AI_STATE_DIR:-.ai-state}"

# Session state file - configurable for different naming conventions
# e.g., BAKE-STATE.md, SESSION-STATE.md, etc.
AI_SESSION_STATE_FILE="${AI_SESSION_STATE_FILE:-SESSION-STATE.md}"
AI_SESSION_PLAN_FILE="${AI_SESSION_PLAN_FILE:-SESSION-PLAN.md}"

# Initialize context health tracking
context_health_init() {
  local session_id="${1:-$(date +%Y%m%d-%H%M%S)}"

  mkdir -p "$CONTEXT_STATE_DIR"

  # Initialize health file if doesn't exist
  if [[ ! -f "$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json" ]]; then
    cat > "$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json" << EOF
{
  "session_id": "$session_id",
  "started": "$(date -Iseconds)",
  "last_check": "$(date -Iseconds)",
  "token_tracking": {
    "estimated_input": 0,
    "estimated_output": 0,
    "utilization": 0,
    "method": "char_estimate"
  },
  "rot_signals": {
    "repetition": {
      "count": 0,
      "last_hashes": []
    },
    "contradiction": {
      "count": 0,
      "detected": []
    },
    "forgetting": {
      "count": 0,
      "instances": []
    },
    "hallucination": {
      "count": 0,
      "instances": []
    },
    "scope_creep": {
      "count": 0,
      "files": []
    }
  },
  "quality_score": 100,
  "status": "HEALTHY",
  "recommendation": "Continue normally",
  "checkpoints": []
}
EOF
  fi

  # Initialize hash log
  touch "$CONTEXT_STATE_DIR/output-hashes.log"

  # Initialize scope file (will be updated by caller)
  if [[ ! -f "$CONTEXT_STATE_DIR/task-scope.txt" ]]; then
    echo "# Task scope - files allowed to be modified" > "$CONTEXT_STATE_DIR/task-scope.txt"
  fi

  echo "$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"
}

# Estimate tokens from character count
context_estimate_tokens() {
  local chars="$1"
  echo $(( chars / CONTEXT_CHARS_PER_TOKEN ))
}

# Add to token budget
context_add_tokens() {
  local input_chars="${1:-0}"
  local output_chars="${2:-0}"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"

  [[ ! -f "$health_file" ]] && context_health_init

  local input_tokens=$(context_estimate_tokens "$input_chars")
  local output_tokens=$(context_estimate_tokens "$output_chars")

  # Update token counts
  local current_input current_output
  current_input=$(jq '.token_tracking.estimated_input' "$health_file")
  current_output=$(jq '.token_tracking.estimated_output' "$health_file")

  local new_input=$((current_input + input_tokens))
  local new_output=$((current_output + output_tokens))
  local total=$((new_input + new_output))
  local utilization=$(echo "scale=2; $total / $CONTEXT_MAX_TOKENS" | bc)

  jq --argjson input "$new_input" \
     --argjson output "$new_output" \
     --arg util "$utilization" \
     '.token_tracking.estimated_input = $input |
      .token_tracking.estimated_output = $output |
      .token_tracking.utilization = ($util | tonumber) |
      .last_check = now | todate' \
     "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

  echo "$utilization"
}

# Check for repetition (same output hash 3+ times)
context_check_repetition() {
  local output="$1"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"
  local hash_log="$CONTEXT_STATE_DIR/output-hashes.log"

  [[ ! -f "$health_file" ]] && context_health_init

  # Skip if output is too short (likely not meaningful)
  if [[ ${#output} -lt 50 ]]; then
    return 0
  fi

  # Hash the output (first 500 chars to avoid huge outputs)
  local output_sample="${output:0:500}"
  local hash
  hash=$(echo "$output_sample" | sha256sum | cut -c1-16)

  # Add to log
  echo "$hash" >> "$hash_log"

  # Count occurrences
  local count
  count=$(grep -c "^${hash}$" "$hash_log" 2>/dev/null || echo "0")

  if [[ "$count" -ge 3 ]]; then
    # Repetition detected!
    jq --arg hash "$hash" \
       '.rot_signals.repetition.count += 1 |
        .rot_signals.repetition.last_hashes = (.rot_signals.repetition.last_hashes[-9:] + [$hash])' \
       "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

    echo "REPETITION_DETECTED:$hash:$count"
    return 1
  fi

  # Update last hashes anyway (for monitoring)
  jq --arg hash "$hash" \
     '.rot_signals.repetition.last_hashes = (.rot_signals.repetition.last_hashes[-9:] + [$hash])' \
     "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

  return 0
}

# Check for hallucination (file doesn't exist)
context_check_hallucination() {
  local file_path="$1"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"

  [[ ! -f "$health_file" ]] && context_health_init

  # Skip if it's a new file being created
  if [[ "$2" == "write" ]]; then
    return 0
  fi

  if [[ ! -e "$file_path" ]]; then
    # Hallucination detected!
    jq --arg file "$file_path" \
       --arg time "$(date -Iseconds)" \
       '.rot_signals.hallucination.count += 1 |
        .rot_signals.hallucination.instances += [{"file": $file, "time": $time}]' \
       "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

    echo "HALLUCINATION_DETECTED:$file_path"
    return 1
  fi

  return 0
}

# Check for scope creep (modifying files outside task scope)
context_check_scope_creep() {
  local file_path="$1"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"
  local scope_file="$CONTEXT_STATE_DIR/task-scope.txt"

  [[ ! -f "$health_file" ]] && context_health_init

  # If no scope defined, skip check
  if [[ ! -f "$scope_file" ]] || [[ ! -s "$scope_file" ]]; then
    return 0
  fi

  # Normalize the file path
  local normalized_path
  normalized_path=$(realpath --relative-to="$(pwd)" "$file_path" 2>/dev/null || echo "$file_path")

  # Check if file is in scope (supports glob patterns)
  local in_scope=0
  while IFS= read -r pattern; do
    # Skip comments and empty lines
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue

    # Check if file matches pattern
    if [[ "$normalized_path" == $pattern ]] || [[ "$normalized_path" =~ $pattern ]]; then
      in_scope=1
      break
    fi
  done < "$scope_file"

  if [[ $in_scope -eq 0 ]]; then
    # Scope creep detected!
    jq --arg file "$normalized_path" \
       --arg time "$(date -Iseconds)" \
       '.rot_signals.scope_creep.count += 1 |
        .rot_signals.scope_creep.files += [$file] |
        .rot_signals.scope_creep.files = (.rot_signals.scope_creep.files | unique)' \
       "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

    echo "SCOPE_CREEP_DETECTED:$normalized_path"
    return 1
  fi

  return 0
}

# Check for forgetting (re-asking already answered questions)
context_check_forgetting() {
  local question="$1"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"
  local state_file="$CONTEXT_STATE_DIR/$AI_SESSION_STATE_FILE"

  [[ ! -f "$health_file" ]] && context_health_init
  [[ ! -f "$state_file" ]] && return 0

  # Normalize question (lowercase, remove punctuation)
  local normalized_q
  normalized_q=$(echo "$question" | tr '[:upper:]' '[:lower:]' | tr -d '?!.,')

  # Check if similar question was already asked in state
  if grep -qi "$normalized_q" "$state_file" 2>/dev/null; then
    # Forgetting detected!
    jq --arg question "$question" \
       --arg time "$(date -Iseconds)" \
       '.rot_signals.forgetting.count += 1 |
        .rot_signals.forgetting.instances += [{"question": $question, "time": $time}]' \
       "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

    echo "FORGETTING_DETECTED:$question"
    return 1
  fi

  return 0
}

# Record a decision (for contradiction detection)
context_record_decision() {
  local decision="$1"
  local state_file="$CONTEXT_STATE_DIR/$AI_SESSION_STATE_FILE"

  # Append to state file
  echo "- **Decision:** $decision ($(date -Iseconds))" >> "$state_file"
}

# Calculate quality score
context_calculate_score() {
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"

  [[ ! -f "$health_file" ]] && context_health_init

  # Get rot signal counts
  local rep con fgt hal scp
  rep=$(jq '.rot_signals.repetition.count' "$health_file")
  con=$(jq '.rot_signals.contradiction.count' "$health_file")
  fgt=$(jq '.rot_signals.forgetting.count' "$health_file")
  hal=$(jq '.rot_signals.hallucination.count' "$health_file")
  scp=$(jq '.rot_signals.scope_creep.count' "$health_file")

  # Calculate score
  local score=$((100 - rep*WEIGHT_REPETITION - con*WEIGHT_CONTRADICTION - fgt*WEIGHT_FORGETTING - hal*WEIGHT_HALLUCINATION - scp*WEIGHT_SCOPE_CREEP))
  [[ $score -lt 0 ]] && score=0

  # Determine status
  local status recommendation
  if [[ $score -ge 80 ]]; then
    status="HEALTHY"
    recommendation="Continue normally"
  elif [[ $score -ge 60 ]]; then
    status="DEGRADED"
    recommendation="Monitor closely, consider checkpoint after current task"
  elif [[ $score -ge 40 ]]; then
    status="CRITICAL"
    recommendation="Checkpoint immediately, start fresh session"
  else
    status="ABORT"
    recommendation="Stop execution, human review required"
  fi

  # Check token utilization
  local utilization
  utilization=$(jq '.token_tracking.utilization' "$health_file")
  local util_percent
  util_percent=$(echo "$utilization * 100" | bc | cut -d. -f1)

  if [[ "${util_percent:-0}" -ge "$CONTEXT_CRITICAL_THRESHOLD" ]]; then
    status="CRITICAL"
    recommendation="Token budget critical ($util_percent%), checkpoint immediately"
    score=$((score - 30))
  elif [[ "${util_percent:-0}" -ge "$CONTEXT_WARNING_THRESHOLD" ]]; then
    if [[ "$status" == "HEALTHY" ]]; then
      status="DEGRADED"
      recommendation="Token budget at $util_percent%, plan checkpoint soon"
    fi
    score=$((score - 15))
  fi

  [[ $score -lt 0 ]] && score=0

  # Update health file
  jq --argjson score "$score" \
     --arg status "$status" \
     --arg rec "$recommendation" \
     --arg time "$(date -Iseconds)" \
     '.quality_score = $score | .status = $status | .recommendation = $rec | .last_check = $time' \
     "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

  echo "$score:$status:$recommendation"
}

# Get current health status
context_get_status() {
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"

  [[ ! -f "$health_file" ]] && echo "100:HEALTHY:Not initialized" && return

  local score status rec
  score=$(jq '.quality_score' "$health_file")
  status=$(jq -r '.status' "$health_file")
  rec=$(jq -r '.recommendation' "$health_file")

  echo "$score:$status:$rec"
}

# Create a checkpoint
context_create_checkpoint() {
  local reason="${1:-manual}"
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"
  local checkpoint_dir="$CONTEXT_STATE_DIR/checkpoints"

  [[ ! -f "$health_file" ]] && context_health_init

  mkdir -p "$checkpoint_dir"

  local checkpoint_id="CP-$(date +%Y%m%d-%H%M%S)"
  local checkpoint_file="$checkpoint_dir/$checkpoint_id.json"

  # Get current score
  local score
  score=$(jq '.quality_score' "$health_file")

  # Create checkpoint
  cat > "$checkpoint_file" << EOF
{
  "checkpoint_id": "$checkpoint_id",
  "timestamp": "$(date -Iseconds)",
  "reason": "$reason",
  "score_at_checkpoint": $score,
  "state_snapshot": {
    "session_state": "$(cat "$CONTEXT_STATE_DIR/$AI_SESSION_STATE_FILE" 2>/dev/null | base64 -w0 || echo "")",
    "session_plan": "$(cat "$CONTEXT_STATE_DIR/$AI_SESSION_PLAN_FILE" 2>/dev/null | base64 -w0 || echo "")"
  },
  "resumable": true
}
EOF

  # Record checkpoint in health file
  jq --arg id "$checkpoint_id" \
     --arg reason "$reason" \
     --argjson score "$score" \
     --arg time "$(date -Iseconds)" \
     '.checkpoints += [{"id": $id, "timestamp": $time, "reason": $reason, "score": $score}]' \
     "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

  # Reset some counters for fresh start
  jq '.rot_signals.repetition.count = 0 |
      .rot_signals.repetition.last_hashes = [] |
      .quality_score = 100 |
      .status = "HEALTHY"' \
     "$health_file" > "$health_file.tmp" && mv "$health_file.tmp" "$health_file"

  # Clear hash log for fresh session
  > "$CONTEXT_STATE_DIR/output-hashes.log"

  echo "$checkpoint_id"
}

# Set task scope (called before task execution)
context_set_scope() {
  local scope_patterns="$1"  # Newline-separated patterns
  local scope_file="$CONTEXT_STATE_DIR/task-scope.txt"

  mkdir -p "$CONTEXT_STATE_DIR"

  echo "# Task scope - files allowed to be modified" > "$scope_file"
  echo "# Generated: $(date -Iseconds)" >> "$scope_file"
  echo "" >> "$scope_file"
  echo "$scope_patterns" >> "$scope_file"
}

# Print health report
context_health_report() {
  local health_file="$CONTEXT_STATE_DIR/CONTEXT-HEALTH.json"

  [[ ! -f "$health_file" ]] && echo "No health data available" && return

  local score status utilization
  score=$(jq '.quality_score' "$health_file")
  status=$(jq -r '.status' "$health_file")
  utilization=$(jq '.token_tracking.utilization' "$health_file")

  local rep hal scp fgt
  rep=$(jq '.rot_signals.repetition.count' "$health_file")
  hal=$(jq '.rot_signals.hallucination.count' "$health_file")
  scp=$(jq '.rot_signals.scope_creep.count' "$health_file")
  fgt=$(jq '.rot_signals.forgetting.count' "$health_file")

  cat << EOF
╭────────────────────────────────────────────────╮
│           CONTEXT HEALTH REPORT                │
├────────────────────────────────────────────────┤
│  Quality Score: $score/100
│  Status: $status
│  Token Utilization: $(echo "$utilization * 100" | bc | cut -d. -f1)%
├────────────────────────────────────────────────┤
│  Rot Signals:                                  │
│    Repetition:    $rep
│    Hallucination: $hal
│    Scope Creep:   $scp
│    Forgetting:    $fgt
╰────────────────────────────────────────────────╯
EOF
}

# Main entry point for hook calls
context_health_hook() {
  local event="$1"
  local data="${2:-}"

  case "$event" in
    init)
      context_health_init "$data"
      ;;
    check_repetition)
      context_check_repetition "$data"
      ;;
    check_hallucination)
      context_check_hallucination "$data" "${3:-read}"
      ;;
    check_scope)
      context_check_scope_creep "$data"
      ;;
    check_forgetting)
      context_check_forgetting "$data"
      ;;
    add_tokens)
      context_add_tokens "$data" "${3:-0}"
      ;;
    calculate)
      context_calculate_score
      ;;
    status)
      context_get_status
      ;;
    checkpoint)
      context_create_checkpoint "$data"
      ;;
    set_scope)
      context_set_scope "$data"
      ;;
    report)
      context_health_report
      ;;
    version)
      echo "context-health v${CONTEXT_HEALTH_VERSION}"
      ;;
    *)
      echo "Unknown event: $event" >&2
      return 1
      ;;
  esac
}

# If sourced, export functions; if run directly, handle as hook
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  context_health_hook "$@"
fi
