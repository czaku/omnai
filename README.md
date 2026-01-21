# ai-runner

Universal local AI agent runner for bash scripts. A lightweight library for running prompts through various AI backends with retries, error handling, and progress callbacks.

## Supported Backends

| Backend | Command | Description |
|---------|---------|-------------|
| Claude CLI | `claude` / `claude-code` | Anthropic's CLI tool |
| OpenCode | `opencode` | Alternative AI coding assistant |
| Ollama | `ollama` | Local LLMs (llama3.2, mistral, etc.) |
| Aider | `aider` | AI pair programming |

## Installation

```bash
# Clone to your dev folder
git clone git@github.com:czaku/ai-runner.git ~/dev/ai-runner

# Or just copy the single file
curl -O https://raw.githubusercontent.com/czaku/ai-runner/main/ai-runner.sh
chmod +x ai-runner.sh
```

## Quick Start

### CLI Usage

```bash
# Run a prompt directly
./ai-runner.sh "What is 2+2?"

# Specify engine and model
./ai-runner.sh --engine claude --model sonnet "Explain quantum computing"
./ai-runner.sh --engine ollama --model llama3.2 "Write a haiku"

# Verbose mode (use twice for debug)
./ai-runner.sh -v -v "Debug this"

# List all installed engines and models
./ai-runner.sh --list

# Show help
./ai-runner.sh --help
```

### Library Usage

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

# Simple prompt
result=$(ai_run "What is 2+2?")
echo "$result"

# Interactive session
ai_run_interactive "Help me write a bash script"

# From file
ai_run_file /path/to/prompt.md

# Background task
pid=$(ai_run_background "Long running task..." output.txt)
# ... do other work ...
ai_wait "$pid"
cat output.txt
```

## Configuration

Set via environment variables or config file:

### Environment Variables

```bash
# Choose backend (auto-detected if not set)
export AI_ENGINE=claude      # or: opencode, ollama, aider

# Set model
export AI_MODEL=sonnet       # claude models: haiku, sonnet, opus
export AI_MODEL=llama3.2     # ollama models

# Enable verbose logging (0, 1, or 2)
export AI_VERBOSE=1

# Set timeout in seconds (default: 300)
export AI_TIMEOUT=600

# Working directory for execution
export AI_WORKING_DIR=/path/to/worktree

# Retry configuration
export AI_RETRY_COUNT=3
export AI_RETRY_DELAY=5
export AI_RETRY_BACKOFF=2

# Progress callback function name
export AI_PROGRESS_CALLBACK=my_progress_handler
```

## Structured API

Query engines and models programmatically:

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

# Get all available engines as JSON
ai_get_engines
# Output: ["claude","opencode","ollama","aider"]

# Get models for a specific engine
ai_get_models "claude"
# Output: ["haiku","sonnet","opus"]

ai_get_models "ollama"
# Output: ["llama3.2","llama3.1","mistral","codellama","deepseek-coder"]

# Get installed engines
ai_get_installed_engines
# Output: ["claude","ollama"]

# Get detailed engine info
ai_get_engine_info "ollama"
# Output: {"engine":"ollama","installed":true,"version":"ollama version 0.1.0","models":["llama3.2",...]}

# Get all engines info
ai_get_all_engines_info
# Output: [{"engine":"claude",...},{"engine":"ollama",...},...]

# Get current configuration
ai_get_config
# Output: {"version":"0.5.0","config":{"engine":"","model":"",...}}

# Get full status
ai_get_status
# Output: {"status":{"available":true,"installed_engines":[...],"config":...}}
```

### Config File

Create `~/.ai-runner.conf`:

```bash
# ai-runner configuration
export AI_ENGINE=claude
export AI_MODEL=sonnet
export AI_VERBOSE=0
export AI_TIMEOUT=300
export AI_RETRY_COUNT=3
export AI_RETRY_DELAY=5
export AI_RETRY_BACKOFF=2
```

CLI commands:
```bash
# Save current config
ai-runner --save-config

# Reload config
ai-runner --load-config
```

Or load in your script:
```bash
source ~/dev/ai-runner/ai-runner.sh
ai_load_config  # Config is auto-loaded on source
```

## API Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `ai_run "prompt"` | Run prompt, return output |
| `ai_run_file "/path/to/prompt.md"` | Run prompt from file |
| `ai_run_interactive "prompt"` | Start interactive session |
| `ai_run_background "prompt" output.txt` | Run in background, return PID |
| `ai_wait $pid` | Wait for background task |
| `ai_run_with_cwd "prompt"` | Run in specific directory |
| `ai_run_with_retry "prompt"` | Run with automatic retry |
| `ai_run_with_files "prompt" file1.md file2.md` | Run with file context |
| `ai_run_with_error_handling "prompt"` | Run with error handling |

### Helper Functions

| Function | Description |
|----------|-------------|
| `ai "prompt"` | Quick one-liner |
| `ai_json "prompt" '{"schema":""}'` | Get JSON response |
| `ai_json_validated "prompt" schema` | Get validated JSON |
| `ai_code "request" "language"` | Generate code |
| `ai_build_prompt dir name VAR=val` | Build from template |
| `ai_build_prompt_with_files dir name VAR=val file1 file2` | Build with files |
| `ai_stream` | Read prompt from stdin |

### Utility Functions

| Function | Description |
|----------|-------------|
| `ai_detect_engine` | Get active backend |
| `ai_available` | Check if AI is available |
| `ai_info` | Print backend info |
| `ai_validate` | Validate configuration |
| `ai_list` | List all engines and models |
| `ai_test` | Run self-test |
| `ai_exit_code_name <code>` | Get exit code name |
| `ai_set_progress_callback func` | Set progress handler |

### Error Handling Functions

| Function | Description |
|----------|-------------|
| `ai_detect_error "provider" "output"` | Detect error type from output |
| `ai_error_suggestion "error_type"` | Get recovery suggestion |
| `ai_handle_error "provider" code "output"` | Handle error with suggestion |

## Exit Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Completed successfully |
| 1 | USER_ABORT | User cancelled (Ctrl+C) |
| 2 | PROVIDER_ERROR | Provider error (rate limit, API error) |
| 3 | INVALID_INPUT | Bad prompt or configuration |
| 4 | INTERNAL_ERROR | ai-runner bug |
| 124 | TIMEOUT | Timed out |

### Get Exit Code Name

```bash
source ai-runner.sh
ai_exit_code_name 0  # Returns: SUCCESS
ai_exit_code_name 124  # Returns: TIMEOUT
```

## Template Format

Templates are markdown files with `{{VARIABLE}}` placeholders:

```markdown
# prompts/code-review.md

Review this {{LANGUAGE}} code:

```{{LANGUAGE}}
{{CODE}}
```

Focus on:
- Security issues
- Performance
- Best practices
```

Usage:
```bash
source ai-runner.sh
prompt=$(ai_build_prompt "./prompts" "code-review" \
  "CODE=$code" \
  "LANGUAGE=python")
result=$(ai_run "$prompt")
```

## Progress Callbacks

Monitor AI operations in real-time:

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

my_progress_handler() {
  local event="$1"  # started, streaming, completed, error
  local data="$2"

  case "$event" in
    started)
      echo "[Progress] Started at $(date)"
      ;;
    streaming)
      echo "[Progress] Streaming..."
      ;;
    completed)
      echo "[Progress] Completed!"
      ;;
    error)
      echo "[Progress] Error: $data"
      ;;
  esac
}

export AI_PROGRESS_CALLBACK=my_progress_handler
ai_run "Long running task..."
```

## Error Handling

Get intelligent error recovery suggestions:

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

# Run with automatic error handling
result=$(ai_run_with_error_handling "Your prompt here")
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  echo "Error occurred, check messages above"
fi

# Manual error detection
output=$(ai_run "prompt" 2>&1)
exit_code=$?

if [[ $exit_code -ne 0 ]]; then
  error_type=$(ai_detect_error "ollama" "$output")
  suggestion=$(ai_error_suggestion "$error_type")
  echo "Error type: $error_type"
  echo "Suggestion: $suggestion"
fi
```

### Supported Error Types

| Error Type | Suggestion |
|------------|------------|
| `rate_limit` | Reduce request frequency, upgrade plan |
| `quota_exceeded` | Check usage, increase quota |
| `authentication` | Check API key or credentials |
| `permission_denied` | Verify access rights |
| `not_found` | Check identifier or path |
| `invalid_request` | Review prompt and parameters |
| `model_not_found` | Pull model: `ollama pull <name>` |
| `connection_failed` | Check network or server status |
| `timeout` | Increase AI_TIMEOUT |
| `context_length` | Shorten prompt, reduce files |

## Retry with Backoff

Automatically retry failed requests:

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

# Configure retry
export AI_RETRY_COUNT=5
export AI_RETRY_DELAY=10
export AI_RETRY_BACKOFF=2

# Run with retry (exponential backoff: 10s, 20s, 40s...)
ai_run_with_retry "Your prompt here"
```

## File Context Injection

Attach files to prompts:

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

# Attach multiple files
ai_run_with_files "Implement this feature" \
  docs/prds/feature.json \
  RULES.md \
  tests/similar-feature.test.ts
```

## Integration Examples

### With ralfiepretzel

```bash
source ~/dev/ai-runner/ai-runner.sh

execute_prd_in_worktree() {
  local prd="$1"
  local worktree="$2"

  AI_WORKING_DIR="$worktree" \
  AI_RETRY_COUNT=3 \
  AI_PROGRESS_CALLBACK=update_dashboard \
    ai_run_with_files "Implement this PRD" \
      "$prd" \
      "$RALFIE_ROOT/RULES.md"
}
```

### With aixam (Quiz Assistant)

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

analyze_quiz_question() {
  local question="$1"
  local options="$2"
  local docs="$3"

  AI_ENGINE="${AI_ENGINE:-auto}" \
  AI_RETRY_COUNT=3 \
  AI_RETRY_DELAY=5 \
    ai_run_with_files "Answer this quiz. Paraphrase, don't copy word-for-word." \
      "$question" \
      "$options" \
      "$docs"
}
```

### With rec.ai (Recording Analysis)

```bash
#!/usr/bin/env bash
source ~/dev/ai-runner/ai-runner.sh

analyze_recording() {
  local transcript="$1"

  AI_ENGINE=ollama \
  AI_MODEL=llama3.2 \
    ai_json_validated "Extract action items" \
      '{"actionItems": [{"task": "string", "assignee": "string"}]}'
}
```

## Testing

```bash
# Run all tests (52+ tests)
bash tests/run_tests.sh

# Run integration tests (requires AI backend)
python3 tests/test_integration.py

# ShellCheck (requires shellcheck)
shellcheck -x -s bash ai-runner.sh

# Enable bash completion
source ~/dev/ai-runner/completion.bash
```

## Version History

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.

## License

MIT

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feat/feature-name`
3. Make changes with tests
4. Ensure ShellCheck passes: `shellcheck ai-runner.sh`
5. Run tests: `bash tests/run_tests.sh`
6. Submit PR
