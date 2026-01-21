# ai-runner Roadmap

**Version:** 0.5.0 → 1.0.0
**Status:** Active Development
**Last Updated:** January 2026

---

## Vision

ai-runner is a **universal bash library** for running prompts through local AI agents. It provides a consistent interface across multiple backends (Claude CLI, OpenCode, Ollama, Aider) so that higher-level tools can focus on their domain logic rather than AI provider details.

### Design Principles

1. **Single Responsibility** - ai-runner handles AI communication; nothing else
2. **Provider Agnostic** - Same API regardless of backend
3. **Library First** - Designed to be sourced, not just run as CLI
4. **Zero Dependencies** - Pure bash (except for the AI backends themselves)
5. **Fail Gracefully** - Clear errors, sensible defaults, retry logic

---

## Current State (v0.5.0)

### Working Features

| Feature | Function | Status |
|---------|----------|--------|
| Multi-backend support | claude, opencode, ollama, aider | ✅ Complete |
| Engine auto-detection | `ai_detect_engine` | ✅ Complete |
| Basic prompt execution | `ai_run "prompt"` | ✅ Complete |
| File-based prompts | `ai_run_file prompt.md` | ✅ Complete |
| Template substitution | `ai_build_prompt dir template VAR=val` | ✅ Complete |
| JSON output helper | `ai_json "question" schema` | ✅ Complete |
| Background execution | `ai_run_background prompt out.txt` | ✅ Complete |
| Interactive sessions | `ai_run_interactive` | ✅ Complete |
| Validation | `ai_validate` | ✅ Complete |
| CLI interface | `./ai-runner.sh --help` | ✅ Complete |
| Verbose logging | `AI_VERBOSE=1|2` | ✅ Complete |
| Timeout support | `AI_TIMEOUT=300` | ✅ Complete |
| Working directory context | `AI_WORKING_DIR`, `ai_run_with_cwd` | ✅ Complete |
| Exit code semantics | `AI_EXIT_SUCCESS`, etc. | ✅ Complete |
| Exit code helper | `ai_exit_code_name()` | ✅ Complete |
| Retry with backoff | `ai_run_with_retry` | ✅ Complete |
| JSON validation | `ai_json_validated` | ✅ Complete |
| Progress callbacks | `AI_PROGRESS_CALLBACK` | ✅ Complete |
| File context injection | `ai_run_with_files` | ✅ Complete |
| Error handling | `ai_detect_error`, `ai_handle_error` | ✅ Complete |

### Known Gaps

| Gap | Impact | Priority |
|-----|--------|----------|
| Full documentation | User onboarding | High |
| ShellCheck CI | Code quality enforcement | Low |

---

## Roadmap

### v1.0.0 - Stable Release

**Goal:** Production-ready, fully documented, semver-stable API.

**Requirements:**
- [x] All v0.2-0.5 features complete
- [x] Comprehensive test suite (75 tests)
- [x] Full documentation (README, API reference)
- [x] Example integrations (ralfiepretzel, aixam, rec.ai)
- [x] Changelog
- [x] Semantic versioning commitment
- [x] ShellCheck validation
- [x] Qwen-Code support
- [x] Cursor support
- [x] Codex support
- [x] Goose support
- [x] Copilot support

---

## Integration Examples

### aixam (Quiz Assistant)

```bash
#!/usr/bin/env bash
source "$HOME/dev/ai-runner/ai-runner.sh"

analyze_quiz_question() {
  local question="$1"
  local options="$2"
  local docs="$3"

  # Run with human-like delay and doc context
  AI_ENGINE="${AI_ENGINE:-auto}" \
  AI_RETRY_COUNT=3 \
  AI_RETRY_DELAY=5 \
  AI_PROGRESS_CALLBACK=quiz_progress \
    ai_run_with_files "Answer this quiz question using the provided docs. Paraphrase the answer, don't copy word-for-word." \
      "$question" \
      "$options" \
      "$docs"
}

quiz_progress() {
  local event="$1"
  local data="$2"
  echo "[Aixam] $event: $data"
}

# Usage with aixam docs
analyze_quiz_question \
  "What is the capital of France?" \
  "A: Paris\nB: London\nC: Berlin" \
  "$AIXAM_ROOT/docs/france.md"
```

### ralfiepretzel (Orchestration)

```bash
source "$HOME/dev/ai-runner/ai-runner.sh"

execute_prd_in_worktree() {
  local prd="$1"
  local worktree="$2"

  # Use ai-runner with worktree context
  AI_WORKING_DIR="$worktree" \
  AI_RETRY_COUNT=3 \
  AI_RETRY_DELAY=5 \
  AI_PROGRESS_CALLBACK=update_dashboard \
    ai_run_with_files "Implement this PRD following the rules" \
      "$prd" \
      "$RALFIE_ROOT/RULES.md"
}
```

### rec.ai (Recording Analysis)

```bash
source "$HOME/dev/ai-runner/ai-runner.sh"

analyze_recording() {
  local transcript="$1"

  AI_ENGINE=ollama \
  AI_MODEL=llama3.2 \
    ai_json_validated "Extract action items from this transcript" \
      '{"actionItems": [{"task": "string", "assignee": "string"}]}'
}
```

---

## API Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `ai_run "prompt"` | Run prompt, return output |
| `ai_run_file "/path/to/prompt.md"` | Run prompt from file |
| `ai_run_interactive "prompt"` | Start interactive session |
| `ai_run_background "prompt" output.txt` | Run in background, return PID |
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
| `ai_exit_code_name <code>` | Get exit code name |
| `ai_set_progress_callback func` | Set progress handler |
| `ai_list` | List all engines and models |
| `ai_test` | Run self-test |
| `ai_detect_error "provider" "output"` | Detect error type |
| `ai_error_suggestion "error_type"` | Get recovery suggestion |
| `ai_handle_error "provider" code "output"` | Handle error with suggestion |

### Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_ENGINE` | auto | Backend: claude, opencode, ollama, aider |
| `AI_MODEL` | - | Model name (backend-specific) |
| `AI_VERBOSE` | 0 | Verbose level (0, 1, 2) |
| `AI_TIMEOUT` | 300 | Timeout in seconds |
| `AI_WORKING_DIR` | - | Working directory for execution |
| `AI_RETRY_COUNT` | 3 | Number of retry attempts |
| `AI_RETRY_DELAY` | 5 | Initial delay between retries |
| `AI_RETRY_BACKOFF` | 2 | Delay multiplier |
| `AI_PROGRESS_CALLBACK` | - | Progress callback function |

### Exit Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Completed successfully |
| 1 | USER_ABORT | User cancelled (Ctrl+C) |
| 2 | PROVIDER_ERROR | Provider error (rate limit, API error) |
| 3 | INVALID_INPUT | Bad prompt or configuration |
| 4 | INTERNAL_ERROR | ai-runner bug |
| 124 | TIMEOUT | Timed out |

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feat/feature-name`
3. Make changes with tests
4. Ensure tests pass: `bash tests/run_tests.sh`
5. Submit PR with description of changes

### Code Style

- Bash 4+ compatible
- ShellCheck clean (run: `shellcheck ai-runner.sh`)
- Functions prefixed with `ai_` (public) or `_ai_` (internal)
- Clear error messages via `ai_log_error`
- Tests for all new functions

### Running Tests

```bash
# Unit tests (no AI required)
bash tests/run_tests.sh

# Integration tests (requires AI backend)
python3 tests/test_integration.py
```

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for detailed version history.
