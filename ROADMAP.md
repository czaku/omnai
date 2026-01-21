# ai-runner Roadmap

**Version:** 0.1.0 → 1.0.0
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

## Current State (v0.1.0)

### Working

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

### Known Gaps

| Gap | Impact | Priority |
|-----|--------|----------|
| No working directory context | Can't run in worktrees | Critical |
| No exit code standardization | Inconsistent error handling | High |
| No output validation | `ai_json` doesn't verify JSON | High |
| No retry logic | Transient failures break batches | Medium |
| No progress callbacks | No real-time status | Medium |
| No file context injection | Verbose prompt building | Medium |

---

## Roadmap

### v0.2.0 - Execution Context (Next)

**Goal:** Enable running AI in specific directories with standardized exit codes.

#### Feature: Working Directory Context

```bash
# Environment variable
AI_WORKING_DIR="/path/to/worktree" ai_run "implement feature"

# Or flag
ai_run --cwd /path/to/worktree "implement feature"
```

**Implementation:**
- Add `AI_WORKING_DIR` environment variable
- Wrap execution in `(cd "$cwd" && ...)`
- Update all provider implementations

#### Feature: Exit Code Semantics

```bash
# Standardized exit codes
AI_EXIT_SUCCESS=0          # Completed successfully
AI_EXIT_USER_ABORT=1       # User cancelled (Ctrl+C)
AI_EXIT_PROVIDER_ERROR=2   # Provider error (rate limit, API error)
AI_EXIT_INVALID_INPUT=3    # Bad prompt or configuration
AI_EXIT_INTERNAL_ERROR=4   # ai-runner bug
AI_EXIT_TIMEOUT=124        # Timed out (standard timeout code)
```

**Implementation:**
- Define constants in ai-runner.sh
- Map provider-specific codes to standard codes
- Add `ai_exit_code_name()` helper

**Deliverables:**
- [ ] `AI_WORKING_DIR` support
- [ ] `--cwd` flag
- [ ] Exit code constants
- [ ] Exit code mapping for each provider
- [ ] Tests for new features
- [ ] Updated README

---

### v0.3.0 - Reliability

**Goal:** Make ai-runner robust for batch/orchestration use cases.

#### Feature: Structured Output Validation

```bash
# Validate JSON response
response=$(ai_json_validated "List 3 colors" '{"colors": ["string"]}')

# With schema file
response=$(ai_json_validated "Generate config" --schema config.schema.json)
```

**Implementation:**
- Add `ai_json_validated()` function
- Use `jq` for basic JSON validation
- Optional: Python for JSON schema validation

#### Feature: Retry with Backoff

```bash
# Configuration
AI_RETRY_COUNT=3
AI_RETRY_DELAY=5
AI_RETRY_BACKOFF=2

# Automatic retry
ai_run_with_retry "prompt"
```

**Implementation:**
- Add retry configuration variables
- Exponential backoff logic
- Skip retry for user abort and invalid input
- Logging for retry attempts

**Deliverables:**
- [ ] `ai_json_validated()` function
- [ ] `ai_run_with_retry()` function
- [ ] Retry configuration variables
- [ ] Tests for retry scenarios
- [ ] Updated README

---

### v0.4.0 - Integration

**Goal:** Better integration with orchestration tools and dashboards.

#### Feature: Progress Callbacks

```bash
# Set callback function
AI_PROGRESS_CALLBACK=my_progress_handler

my_progress_handler() {
  local event="$1"  # started, streaming, completed, error
  local data="$2"
  echo "{\"event\": \"$event\", \"data\": \"$data\"}" >> /tmp/ai-progress.jsonl
}

ai_run "long prompt"  # Callback invoked at each stage
```

**Implementation:**
- Add `AI_PROGRESS_CALLBACK` variable
- Invoke callback at: started, streaming (if supported), completed, error
- Standard event format

#### Feature: File Context Injection

```bash
# Attach files to prompt
ai_run_with_files "Implement this PRD" \
  docs/prds/feature.json \
  RULES.md \
  examples/similar-feature.md
```

**Implementation:**
- Add `ai_run_with_files()` function
- Format files with clear delimiters
- Prepend to prompt

**Deliverables:**
- [ ] `AI_PROGRESS_CALLBACK` support
- [ ] Standard event types
- [ ] `ai_run_with_files()` function
- [ ] File formatting with delimiters
- [ ] Tests for callbacks
- [ ] Updated README

---

### v1.0.0 - Stable Release

**Goal:** Production-ready, fully documented, semver-stable API.

**Requirements:**
- [ ] All v0.2-0.4 features complete
- [ ] Comprehensive test suite
- [ ] Full documentation
- [ ] Example integrations (ralfiepretzel, rec.ai)
- [ ] Changelog
- [ ] Semantic versioning commitment

---

## Integration Examples

### ralfiepretzel (Orchestration)

```bash
source "$HOME/dev/ai-runner/ai-runner.sh"

execute_prd_in_worktree() {
  local prd="$1"
  local worktree="$2"

  # Use ai-runner with worktree context
  AI_WORKING_DIR="$worktree" \
  AI_RETRY_COUNT=3 \
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
    ai_json "Extract action items from this transcript: $(cat "$transcript")" \
      '{"actionItems": [{"task": "string", "assignee": "string"}]}'
}
```

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feat/working-directory`
3. Make changes with tests
4. Submit PR with description of changes

### Code Style

- Bash 4+ compatible
- ShellCheck clean
- Functions prefixed with `ai_` (public) or `_ai_` (internal)
- Clear error messages via `ai_log_error`

---

## Changelog

### v0.1.0 (January 2026)
- Initial release
- Multi-backend support: claude, opencode, ollama, aider
- Core functions: `ai_run`, `ai_run_file`, `ai_json`, `ai_build_prompt`
- Engine auto-detection
- CLI interface
- Verbose logging
