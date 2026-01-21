#!/usr/bin/env bash
# ai-runner.sh - Universal local AI agent runner
#
# A lightweight library for running prompts through various AI backends:
# - Claude CLI (claude / claude-code)
# - OpenCode CLI
# - Ollama (local)
# - Aider
# - Any custom backend
#
# Usage as library:
#   source ai-runner.sh
#   ai_run "Your prompt here"
#   ai_run_file /path/to/prompt.md
#
# Usage as CLI:
#   ./ai-runner.sh --engine claude --model sonnet "Your prompt"
#   ./ai-runner.sh --engine ollama --model llama3.2 --verbose "Your prompt"
#
# Configuration (environment variables):
#   AI_ENGINE     - Backend to use: claude, opencode, ollama, aider (auto-detected)
#   AI_MODEL      - Model name (backend-specific)
#   AI_VERBOSE    - Enable verbose logging (0, 1, or 2 for very verbose)
#   AI_TIMEOUT    - Timeout in seconds (default: 300)

AI_RUNNER_VERSION="0.1.0"

# Supported engines and their known models
declare -A AI_KNOWN_ENGINES=(
  [claude]="Claude CLI (Anthropic)"
  [opencode]="OpenCode CLI"
  [ollama]="Ollama (local LLMs)"
  [aider]="Aider (AI pair programming)"
)

declare -A AI_KNOWN_MODELS=(
  # Claude models
  [claude:haiku]="claude-3-5-haiku-latest"
  [claude:sonnet]="claude-sonnet-4-20250514"
  [claude:opus]="claude-opus-4-20250514"
  # Ollama models
  [ollama:llama3.2]="llama3.2"
  [ollama:llama3.1]="llama3.1"
  [ollama:mistral]="mistral"
  [ollama:codellama]="codellama"
  [ollama:deepseek-coder]="deepseek-coder"
)

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

# Colors (only when stderr is a TTY)
if [[ -t 2 ]]; then
  _AI_RED='\033[0;31m'
  _AI_GREEN='\033[0;32m'
  _AI_YELLOW='\033[1;33m'
  _AI_BLUE='\033[0;34m'
  _AI_CYAN='\033[0;36m'
  _AI_DIM='\033[2m'
  _AI_NC='\033[0m'
else
  _AI_RED='' _AI_GREEN='' _AI_YELLOW='' _AI_BLUE='' _AI_CYAN='' _AI_DIM='' _AI_NC=''
fi

ai_log_info() {
  echo -e "${_AI_BLUE}ℹ${_AI_NC} [ai-runner] $*" >&2
}

ai_log_success() {
  echo -e "${_AI_GREEN}✓${_AI_NC} [ai-runner] $*" >&2
}

ai_log_warning() {
  echo -e "${_AI_YELLOW}⚠${_AI_NC} [ai-runner] $*" >&2
}

ai_log_error() {
  echo -e "${_AI_RED}✗${_AI_NC} [ai-runner] ERROR: $*" >&2
}

ai_log_verbose() {
  if [[ "${AI_VERBOSE:-0}" -ge 1 ]]; then
    echo -e "${_AI_DIM}[ai-runner] $*${_AI_NC}" >&2
  fi
}

ai_log_debug() {
  if [[ "${AI_VERBOSE:-0}" -ge 2 ]]; then
    echo -e "${_AI_CYAN}[ai-runner:debug]${_AI_NC} $*" >&2
  fi
}

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------

# Check if engine is valid and installed
# Usage: ai_validate_engine "engine_name"
# Returns: 0 if valid and installed, 1 if unknown, 2 if not installed
ai_validate_engine() {
  local engine="$1"

  ai_log_debug "Validating engine: $engine"

  # Check if engine is known
  if [[ -z "${AI_KNOWN_ENGINES[$engine]:-}" ]]; then
    ai_log_error "Unknown engine: '$engine'"
    echo "" >&2
    echo "Supported engines:" >&2
    for eng in "${!AI_KNOWN_ENGINES[@]}"; do
      echo "  - $eng: ${AI_KNOWN_ENGINES[$eng]}" >&2
    done
    return 1
  fi

  # Check if engine command is installed
  local cmd="$engine"
  case "$engine" in
    claude) cmd="claude" ;;
    opencode) cmd="opencode" ;;
    ollama) cmd="ollama" ;;
    aider) cmd="aider" ;;
  esac

  if ! command -v "$cmd" &>/dev/null; then
    ai_log_error "Engine '$engine' is not installed (command '$cmd' not found)"
    echo "" >&2
    case "$engine" in
      claude)
        echo "Install Claude CLI: npm install -g @anthropic-ai/claude-code" >&2
        ;;
      opencode)
        echo "Install OpenCode: see opencode documentation" >&2
        ;;
      ollama)
        echo "Install Ollama: https://ollama.ai" >&2
        ;;
      aider)
        echo "Install Aider: pip install aider-chat" >&2
        ;;
    esac
    return 2
  fi

  ai_log_debug "Engine '$engine' is valid and installed"
  return 0
}

# Check if model is valid for engine
# Usage: ai_validate_model "engine" "model"
ai_validate_model() {
  local engine="$1"
  local model="$2"

  ai_log_debug "Validating model: $model for engine: $engine"

  # If model is empty, use default
  if [[ -z "$model" ]]; then
    ai_log_verbose "No model specified, will use engine default"
    return 0
  fi

  # For ollama, check if model is pulled
  if [[ "$engine" == "ollama" ]]; then
    if ! ollama list 2>/dev/null | grep -q "^${model}"; then
      ai_log_warning "Ollama model '$model' may not be pulled"
      ai_log_verbose "Pull with: ollama pull $model"
      # Don't fail - ollama will pull automatically or show error
    fi
  fi

  # For claude, validate model names
  if [[ "$engine" == "claude" ]]; then
    case "$model" in
      haiku|sonnet|opus|claude-3-*|claude-sonnet-*|claude-opus-*)
        ai_log_debug "Claude model '$model' recognized"
        ;;
      *)
        ai_log_warning "Claude model '$model' not recognized (may still work)"
        ai_log_verbose "Known models: haiku, sonnet, opus"
        ;;
    esac
  fi

  return 0
}

# Validate engine and model together
ai_validate() {
  local engine="${AI_ENGINE:-}"
  local model="${AI_MODEL:-}"

  # If no engine specified, try to detect
  if [[ -z "$engine" ]]; then
    engine=$(ai_detect_engine)
    if [[ "$engine" == "none" ]]; then
      ai_log_error "No AI engine available and none specified"
      echo "" >&2
      echo "Either install one of: claude, opencode, ollama, aider" >&2
      echo "Or specify with: --engine <name>" >&2
      return 1
    fi
    ai_log_verbose "Auto-detected engine: $engine"
  fi

  # Validate engine
  if ! ai_validate_engine "$engine"; then
    return 1
  fi

  # Validate model
  if ! ai_validate_model "$engine" "$model"; then
    return 1
  fi

  return 0
}

#------------------------------------------------------------------------------
# Configuration & Detection
#------------------------------------------------------------------------------

# Detect available AI engine
ai_detect_engine() {
  # Use explicit setting if provided
  if [[ -n "${AI_ENGINE:-}" ]]; then
    echo "$AI_ENGINE"
    return
  fi

  ai_log_debug "Auto-detecting AI engine..."

  # Auto-detect based on available commands (priority order)
  if command -v claude &>/dev/null; then
    ai_log_debug "Found: claude"
    echo "claude"
  elif command -v opencode &>/dev/null; then
    ai_log_debug "Found: opencode"
    echo "opencode"
  elif command -v aider &>/dev/null; then
    ai_log_debug "Found: aider"
    echo "aider"
  elif command -v ollama &>/dev/null; then
    ai_log_debug "Found: ollama"
    echo "ollama"
  else
    ai_log_debug "No AI engine found"
    echo "none"
  fi
}

# Check if any AI backend is available
ai_available() {
  local engine
  engine=$(ai_detect_engine)
  [[ "$engine" != "none" ]]
}

# Get engine info
ai_info() {
  local engine
  engine=$(ai_detect_engine)

  echo "AI Runner v${AI_RUNNER_VERSION}"
  echo ""
  echo "Current Configuration:"
  echo "  Engine:  ${AI_ENGINE:-auto} (detected: $engine)"
  echo "  Model:   ${AI_MODEL:-default}"
  echo "  Timeout: ${AI_TIMEOUT:-300}s"
  echo "  Verbose: ${AI_VERBOSE:-0}"
  echo ""

  if [[ "$engine" == "none" ]]; then
    echo "Status: No AI backend detected"
    echo ""
    echo "Install one of:"
    for eng in "${!AI_KNOWN_ENGINES[@]}"; do
      echo "  - $eng: ${AI_KNOWN_ENGINES[$eng]}"
    done
  else
    echo "Status: Ready"
    echo ""
    echo "Backend Details:"
    case "$engine" in
      claude)
        echo "  $(claude --version 2>/dev/null || echo 'Claude CLI')"
        ;;
      opencode)
        echo "  $(opencode --version 2>/dev/null || echo 'OpenCode CLI')"
        ;;
      ollama)
        echo "  $(ollama --version 2>/dev/null || echo 'Ollama')"
        echo ""
        echo "Available models:"
        ollama list 2>/dev/null | head -10 || echo "  (run 'ollama list')"
        ;;
      aider)
        echo "  $(aider --version 2>/dev/null || echo 'Aider')"
        ;;
    esac
  fi
}

# List available engines and their status
ai_list_engines() {
  echo "Available Engines:"
  echo ""
  for engine in claude opencode ollama aider; do
    local status="not installed"
    local cmd="$engine"

    if command -v "$cmd" &>/dev/null; then
      status="${_AI_GREEN}installed${_AI_NC}"
    else
      status="${_AI_DIM}not installed${_AI_NC}"
    fi

    printf "  %-10s %s  %b\n" "$engine" "${AI_KNOWN_ENGINES[$engine]}" "$status"
  done
}

# List all installed engines with their available models
# Usage: ai_list [--json]
ai_list() {
  local json_output=false
  [[ "${1:-}" == "--json" ]] && json_output=true

  local installed_engines=()
  local engine_data=()

  echo -e "${_AI_BLUE}AI Runner v${AI_RUNNER_VERSION}${_AI_NC}"
  echo ""
  echo -e "${_AI_CYAN}Installed Engines & Models:${_AI_NC}"
  echo ""

  # Check each engine
  for engine in claude opencode ollama aider; do
    if command -v "$engine" &>/dev/null; then
      installed_engines+=("$engine")

      echo -e "  ${_AI_GREEN}●${_AI_NC} ${_AI_YELLOW}${engine}${_AI_NC} - ${AI_KNOWN_ENGINES[$engine]}"

      # Get version
      local version=""
      case "$engine" in
        claude)
          version=$(claude --version 2>/dev/null | head -1 || echo "")
          [[ -n "$version" ]] && echo -e "    ${_AI_DIM}Version: $version${_AI_NC}"
          echo -e "    ${_AI_DIM}Models:${_AI_NC}"
          echo "      - haiku   (fast, efficient)"
          echo "      - sonnet  (balanced)"
          echo "      - opus    (most capable)"
          ;;
        opencode)
          version=$(opencode --version 2>/dev/null | head -1 || echo "")
          [[ -n "$version" ]] && echo -e "    ${_AI_DIM}Version: $version${_AI_NC}"
          echo -e "    ${_AI_DIM}Models: (depends on provider config)${_AI_NC}"
          ;;
        ollama)
          version=$(ollama --version 2>/dev/null | head -1 || echo "")
          [[ -n "$version" ]] && echo -e "    ${_AI_DIM}Version: $version${_AI_NC}"

          # Get pulled models
          local models
          models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")
          if [[ -n "$models" ]]; then
            echo -e "    ${_AI_DIM}Pulled Models:${_AI_NC}"
            echo "$models" | while read -r model; do
              # Get model size if available
              local size
              size=$(ollama list 2>/dev/null | grep "^$model" | awk '{print $3}' || echo "")
              if [[ -n "$size" ]]; then
                echo "      - $model ($size)"
              else
                echo "      - $model"
              fi
            done
          else
            echo -e "    ${_AI_DIM}No models pulled. Run: ollama pull <model>${_AI_NC}"
          fi

          echo ""
          echo -e "    ${_AI_DIM}Popular models to pull:${_AI_NC}"
          echo "      ollama pull llama3.2"
          echo "      ollama pull mistral"
          echo "      ollama pull codellama"
          echo "      ollama pull deepseek-coder"
          ;;
        aider)
          version=$(aider --version 2>/dev/null | head -1 || echo "")
          [[ -n "$version" ]] && echo -e "    ${_AI_DIM}Version: $version${_AI_NC}"
          echo -e "    ${_AI_DIM}Models: (configured via .aider.conf.yml or flags)${_AI_NC}"
          echo "      - Uses Claude, GPT-4, or local models"
          ;;
      esac
      echo ""
    fi
  done

  # Show not installed
  local has_missing=false
  for engine in claude opencode ollama aider; do
    if ! command -v "$engine" &>/dev/null; then
      if [[ "$has_missing" == false ]]; then
        echo -e "${_AI_DIM}Not Installed:${_AI_NC}"
        has_missing=true
      fi
      echo -e "  ${_AI_DIM}○ $engine - ${AI_KNOWN_ENGINES[$engine]}${_AI_NC}"
    fi
  done

  if [[ "$has_missing" == true ]]; then
    echo ""
  fi

  # Summary
  if [[ ${#installed_engines[@]} -eq 0 ]]; then
    echo -e "${_AI_RED}No AI engines installed!${_AI_NC}"
    echo ""
    echo "Install one of:"
    echo "  claude:   npm install -g @anthropic-ai/claude-code"
    echo "  ollama:   https://ollama.ai"
    echo "  aider:    pip install aider-chat"
    return 1
  else
    echo -e "${_AI_DIM}─────────────────────────────────────${_AI_NC}"
    echo -e "Total: ${_AI_GREEN}${#installed_engines[@]}${_AI_NC} engine(s) installed"
    echo -e "Active: ${_AI_YELLOW}${AI_ENGINE:-auto-detect}${_AI_NC}"
  fi
}

#------------------------------------------------------------------------------
# Core Functions
#------------------------------------------------------------------------------

# Run a prompt and get output (non-interactive)
# Usage: ai_run "prompt" [--json]
# Returns: AI response to stdout, exit code indicates success
ai_run() {
  local prompt="$1"
  local output_format="${2:-}"

  # Validate configuration
  if ! ai_validate; then
    return 1
  fi

  local engine
  engine=$(ai_detect_engine)

  ai_log_verbose "Running prompt via $engine"
  ai_log_debug "Prompt length: ${#prompt} chars"

  case "$engine" in
    claude)
      _ai_run_claude "$prompt" "$output_format"
      ;;
    opencode)
      _ai_run_opencode "$prompt" "$output_format"
      ;;
    ollama)
      _ai_run_ollama "$prompt" "$output_format"
      ;;
    aider)
      _ai_run_aider "$prompt" "$output_format"
      ;;
    none)
      ai_log_error "No AI backend available"
      return 1
      ;;
    *)
      ai_log_error "Unknown engine: $engine"
      return 1
      ;;
  esac
}

# Run a prompt from a file
# Usage: ai_run_file /path/to/prompt.md
ai_run_file() {
  local file="$1"
  shift

  if [[ ! -f "$file" ]]; then
    ai_log_error "Prompt file not found: $file"
    return 1
  fi

  ai_log_verbose "Loading prompt from: $file"

  local prompt
  prompt=$(cat "$file")

  ai_log_debug "Loaded ${#prompt} chars from file"

  ai_run "$prompt" "$@"
}

# Run interactively (opens conversation)
# Usage: ai_run_interactive "initial prompt"
ai_run_interactive() {
  local prompt="${1:-}"

  if ! ai_validate; then
    return 1
  fi

  local engine
  engine=$(ai_detect_engine)

  ai_log_verbose "Starting interactive session via $engine"

  case "$engine" in
    claude)
      if [[ -n "$prompt" ]]; then
        claude --prompt "$prompt"
      else
        claude
      fi
      ;;
    opencode)
      if [[ -n "$prompt" ]]; then
        opencode --prompt "$prompt"
      else
        opencode
      fi
      ;;
    ollama)
      if [[ -n "$prompt" ]]; then
        echo "$prompt" | ollama run "${AI_MODEL:-llama3.2}"
      else
        ollama run "${AI_MODEL:-llama3.2}"
      fi
      ;;
    aider)
      aider ${prompt:+--message "$prompt"}
      ;;
    none)
      ai_log_error "No AI backend available"
      return 1
      ;;
  esac
}

# Run in background and return PID
# Usage: ai_run_background "prompt" output_file
ai_run_background() {
  local prompt="$1"
  local output_file="$2"

  if ! ai_validate; then
    return 1
  fi

  local engine
  engine=$(ai_detect_engine)

  ai_log_verbose "Starting background task via $engine -> $output_file"

  case "$engine" in
    claude)
      claude --print --prompt "$prompt" > "$output_file" 2>&1 &
      ;;
    opencode)
      opencode --non-interactive --prompt "$prompt" > "$output_file" 2>&1 &
      ;;
    ollama)
      echo "$prompt" | ollama run "${AI_MODEL:-llama3.2}" > "$output_file" 2>&1 &
      ;;
    aider)
      aider --yes --message "$prompt" > "$output_file" 2>&1 &
      ;;
    none)
      ai_log_error "No AI backend available"
      return 1
      ;;
  esac

  local pid=$!
  ai_log_verbose "Background task started with PID: $pid"
  echo $pid
}

# Wait for background task
ai_wait() {
  local pid="$1"
  ai_log_verbose "Waiting for PID: $pid"
  wait "$pid"
}

#------------------------------------------------------------------------------
# Backend Implementations
#------------------------------------------------------------------------------

_ai_run_claude() {
  local prompt="$1"
  local output_format="$2"

  local args=("--print")

  # Add model if specified
  if [[ -n "${AI_MODEL:-}" ]]; then
    args+=("--model" "$AI_MODEL")
    ai_log_debug "Using model: $AI_MODEL"
  fi

  # Add prompt
  args+=("--prompt" "$prompt")

  ai_log_debug "Executing: claude ${args[*]:0:50}..."

  local result exit_code
  local start_time=$SECONDS

  if result=$(timeout "${AI_TIMEOUT:-300}" claude "${args[@]}" 2>&1); then
    exit_code=0
  else
    exit_code=$?
  fi

  local elapsed=$((SECONDS - start_time))
  ai_log_debug "Completed in ${elapsed}s with exit code: $exit_code"

  if [[ $exit_code -eq 124 ]]; then
    ai_log_error "Timeout after ${AI_TIMEOUT:-300}s"
  fi

  echo "$result"
  return $exit_code
}

_ai_run_opencode() {
  local prompt="$1"
  local output_format="$2"

  local args=("--non-interactive")

  if [[ -n "${AI_MODEL:-}" ]]; then
    args+=("--model" "$AI_MODEL")
    ai_log_debug "Using model: $AI_MODEL"
  fi

  args+=("--prompt" "$prompt")

  ai_log_debug "Executing: opencode ${args[*]:0:50}..."

  timeout "${AI_TIMEOUT:-300}" opencode "${args[@]}"
}

_ai_run_ollama() {
  local prompt="$1"
  local output_format="$2"
  local model="${AI_MODEL:-llama3.2}"

  ai_log_debug "Executing: ollama run $model"

  local start_time=$SECONDS
  echo "$prompt" | timeout "${AI_TIMEOUT:-300}" ollama run "$model"
  local exit_code=$?
  local elapsed=$((SECONDS - start_time))

  ai_log_debug "Completed in ${elapsed}s with exit code: $exit_code"
  return $exit_code
}

_ai_run_aider() {
  local prompt="$1"
  local output_format="$2"

  local args=("--yes" "--no-git")

  if [[ -n "${AI_MODEL:-}" ]]; then
    args+=("--model" "$AI_MODEL")
    ai_log_debug "Using model: $AI_MODEL"
  fi

  args+=("--message" "$prompt")

  ai_log_debug "Executing: aider ${args[*]:0:50}..."

  timeout "${AI_TIMEOUT:-300}" aider "${args[@]}"
}

#------------------------------------------------------------------------------
# Template Helpers
#------------------------------------------------------------------------------

# Build prompt from template with variable substitution
# Usage: ai_build_prompt "template_dir" "template_name" VAR1=value1 VAR2=value2
ai_build_prompt() {
  local template_dir="$1"
  local template_name="$2"
  shift 2

  local template_file="${template_dir}/${template_name}.md"
  if [[ ! -f "$template_file" ]]; then
    ai_log_error "Template not found: $template_file"
    return 1
  fi

  ai_log_debug "Loading template: $template_file"

  local prompt
  prompt=$(cat "$template_file")

  # Substitute {{VAR}} placeholders
  for arg in "$@"; do
    local key="${arg%%=*}"
    local value="${arg#*=}"
    ai_log_debug "Substituting {{$key}}"
    # Escape special characters in value for sed
    value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
    prompt=$(echo "$prompt" | sed "s/{{${key}}}/${value}/g")
  done

  echo "$prompt"
}

# Stream prompt from stdin (for piping)
# Usage: cat prompt.md | ai_stream
ai_stream() {
  local prompt
  prompt=$(cat)
  ai_run "$prompt"
}

#------------------------------------------------------------------------------
# Convenience Functions
#------------------------------------------------------------------------------

# Quick one-liner
# Usage: ai "What is 2+2?"
ai() {
  ai_run "$*"
}

# Ask a question and get JSON response
# Usage: ai_json "List 3 colors" '{"colors": ["red", "green", "blue"]}'
ai_json() {
  local question="$1"
  local schema="${2:-}"

  local prompt="$question

Respond with valid JSON only, no markdown, no explanation."

  if [[ -n "$schema" ]]; then
    prompt+="

Expected format:
$schema"
  fi

  ai_run "$prompt"
}

# Code generation helper
# Usage: ai_code "Write a bash function that..."
ai_code() {
  local request="$1"
  local language="${2:-bash}"

  local prompt="Write $language code for the following:

$request

Output only the code, no explanation, no markdown code blocks."

  ai_run "$prompt"
}

#------------------------------------------------------------------------------
# Self-test
#------------------------------------------------------------------------------

ai_test() {
  echo "AI Runner Self-Test"
  echo "==================="
  echo ""

  ai_info
  echo ""

  if ai_available; then
    echo "Testing simple prompt..."
    local result
    result=$(ai_run "Say 'Hello from AI Runner' and nothing else.")
    echo "Response: $result"
    echo ""
    ai_log_success "AI Runner is working"
  else
    ai_log_error "No AI backend available"
    return 1
  fi
}

#------------------------------------------------------------------------------
# CLI Interface
#------------------------------------------------------------------------------

_ai_cli_usage() {
  cat << 'EOF'
ai-runner - Universal local AI agent runner

USAGE:
  ai-runner [OPTIONS] "prompt"
  ai-runner [OPTIONS] --file /path/to/prompt.md
  source ai-runner.sh  # Use as library

OPTIONS:
  -e, --engine <name>    AI engine: claude, opencode, ollama, aider
  -m, --model <name>     Model name (engine-specific)
  -v, --verbose          Verbose output (use twice for debug)
  -t, --timeout <secs>   Timeout in seconds (default: 300)
  --file <path>          Read prompt from file
  --interactive          Start interactive session
  --test                 Run self-test
  --info                 Show configuration info
  -l, --list             List installed engines with all models
  --list-engines         List engine status only
  -h, --help             Show this help
  --version              Show version

EXAMPLES:
  # Auto-detect engine
  ai-runner "What is 2+2?"

  # Specify engine and model
  ai-runner --engine claude --model sonnet "Explain quantum computing"
  ai-runner --engine ollama --model llama3.2 "Write a haiku"

  # Very verbose mode
  ai-runner -v -v --engine claude "Debug this"

  # From file
  ai-runner --file prompt.md --engine ollama

  # Interactive session
  ai-runner --interactive --engine claude

ENVIRONMENT VARIABLES:
  AI_ENGINE     Default engine
  AI_MODEL      Default model
  AI_VERBOSE    Verbose level (0, 1, 2)
  AI_TIMEOUT    Timeout in seconds
EOF
}

_ai_cli_main() {
  local prompt=""
  local file=""
  local interactive=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--engine)
        export AI_ENGINE="$2"
        shift 2
        ;;
      -m|--model)
        export AI_MODEL="$2"
        shift 2
        ;;
      -v|--verbose)
        AI_VERBOSE=$((${AI_VERBOSE:-0} + 1))
        export AI_VERBOSE
        shift
        ;;
      -t|--timeout)
        export AI_TIMEOUT="$2"
        shift 2
        ;;
      --file)
        file="$2"
        shift 2
        ;;
      --interactive)
        interactive=true
        shift
        ;;
      --test)
        ai_test
        exit $?
        ;;
      --info)
        ai_info
        exit 0
        ;;
      --list-engines)
        ai_list_engines
        exit 0
        ;;
      --list|-l)
        ai_list
        exit 0
        ;;
      -h|--help)
        _ai_cli_usage
        exit 0
        ;;
      --version)
        echo "ai-runner v${AI_RUNNER_VERSION}"
        exit 0
        ;;
      -*)
        ai_log_error "Unknown option: $1"
        echo ""
        _ai_cli_usage
        exit 1
        ;;
      *)
        prompt="$1"
        shift
        ;;
    esac
  done

  # Handle different modes
  if [[ "$interactive" == true ]]; then
    ai_run_interactive "$prompt"
  elif [[ -n "$file" ]]; then
    ai_run_file "$file"
  elif [[ -n "$prompt" ]]; then
    ai_run "$prompt"
  else
    ai_log_error "No prompt provided"
    echo ""
    _ai_cli_usage
    exit 1
  fi
}

# If run directly (not sourced), use CLI
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _ai_cli_main "$@"
fi
