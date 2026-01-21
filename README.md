# ai-runner

Universal local AI agent runner for bash scripts. A lightweight library for running prompts through various AI backends.

## Supported Backends

- **Claude CLI** (`claude` / `claude-code`) - Anthropic's CLI tool
- **OpenCode** - Alternative AI coding assistant
- **Ollama** - Local LLMs (llama3.2, mistral, etc.)
- **Aider** - AI pair programming

## Installation

```bash
# Clone to your dev folder
git clone git@github.com:czaku/ai-runner.git ~/dev/ai-runner

# Or just copy the single file
curl -O https://raw.githubusercontent.com/czaku/ai-runner/main/ai-runner.sh
chmod +x ai-runner.sh
```

## CLI Usage

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

## Library Usage

### Source in your script

```bash
#!/usr/bin/env bash
source /path/to/ai-runner.sh

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

### Quick one-liner

```bash
source ai-runner.sh
ai "Explain this error: $error_message"
```

### Template-based prompts

```bash
source ai-runner.sh

# Build prompt from template with variable substitution
prompt=$(ai_build_prompt "./prompts" "code-review" \
  "CODE=$code" \
  "LANGUAGE=python")

result=$(ai_run "$prompt")
```

### JSON responses

```bash
source ai-runner.sh

# Get structured JSON response
result=$(ai_json "List 3 programming languages" '{"languages": []}')
```

## Configuration

Set via environment variables:

```bash
# Choose backend (auto-detected if not set)
export AI_ENGINE=claude      # or: opencode, ollama, aider

# Set model
export AI_MODEL=sonnet       # claude models: haiku, sonnet, opus
export AI_MODEL=llama3.2     # ollama models

# Enable verbose logging
export AI_VERBOSE=1

# Set timeout (default: 300s)
export AI_TIMEOUT=600
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

### Helper Functions

| Function | Description |
|----------|-------------|
| `ai "prompt"` | Quick one-liner |
| `ai_json "prompt" '{"schema":""}'` | Get JSON response |
| `ai_code "request" "language"` | Generate code |
| `ai_build_prompt dir name VAR=val` | Build from template |
| `ai_stream` | Read prompt from stdin |

### Utility Functions

| Function | Description |
|----------|-------------|
| `ai_detect_engine` | Get active backend |
| `ai_available` | Check if AI is available |
| `ai_info` | Print backend info |
| `ai_test` | Run self-test |

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

## Integration Examples

### With ralfie/ralfiepretzel

```bash
# In ralfie commands
source /path/to/ai-runner.sh

# Generate PRD
prompt=$(ai_build_prompt "$RALFIE_ROOT/prompts" "generate-prd" \
  "FEATURE=$feature_name" \
  "CONTEXT=$context")

result=$(ai_run "$prompt")
```

### With CV Studio

```bash
# In cvs commands
source /path/to/ai-runner.sh

# Position bullets for category
prompt=$(ai_build_prompt "$CVS_ROOT/prompts" "position" \
  "BASE_JSON=$base_json" \
  "CATEGORY=$category")

positioned=$(ai_run "$prompt")
```

## License

MIT
