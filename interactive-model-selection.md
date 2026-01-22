# Interactive Model Selection

## Overview

omnai now provides user-friendly interactive model selection for Claude, OpenCode, and OpenAI engines. Instead of cryptic errors when you specify an invalid model, you get a helpful menu to choose from.

## Features

- **Automatic activation**: Triggers when model is invalid or not specified
- **Smart suggestions**: Fuzzy matching for typos (e.g., "claude-sonett" → "claude-sonnet-4")
- **Visual menu**: Numbered list with cost and speed info
- **TTY-aware**: Only activates in interactive sessions (disabled in scripts/pipes)
- **Configurable**: Control via `OMNAI_INTERACTIVE_SELECT` environment variable

## Usage Examples

### Example 1: Wrong model name (typo)

```bash
$ ./omnai.sh --engine claude --model claude-sonnett "Hello"

Model 'claude-sonnett' not found for claude.

Available claude models:

   1. claude-sonnet-4-20250514       - medium   cost, fast       speed
   2. claude-opus-4-20250514         - expensive cost, slow       speed
   3. claude-sonnet-3.7              - medium   cost, fast       speed
   4. claude-haiku-3.5               - cheap    cost, very-fast  speed

Select a model [1-4] (or 'q' to quit): 1
✓ Using model: claude-sonnet-4-20250514

[... continues with execution ...]
```

### Example 2: No model specified

```bash
$ ./omnai.sh --engine opencode "Generate code"

Available opencode models:

   1. gpt-4o                         - medium   cost, fast       speed
   2. gpt-4o-mini                    - cheap    cost, very-fast  speed
   3. claude-sonnet-3.5              - medium   cost, fast       speed
   4. minimax-m2.1                   - cheap    cost, fast       speed
   5. minimax-m2.1-free              - free     cost, fast       speed

Select a model [1-5] (or 'q' to quit): 5
✓ Using model: minimax-m2.1-free

[... continues with execution ...]
```

### Example 3: Quit selection

```bash
$ ./omnai.sh --engine claude --model unknown "Test"

Model 'unknown' not found for claude.

Available claude models:
  [... models listed ...]

Select a model [1-4] (or 'q' to quit): q

⚠ [omnai] claude model 'unknown' not found in configs (may still work)
[... continues anyway with warning ...]
```

## Configuration

### Disable Interactive Selection

```bash
# Disable for single command
OMNAI_INTERACTIVE_SELECT=false ./omnai.sh --engine claude "test"

# Disable globally
export OMNAI_INTERACTIVE_SELECT=false
```

### Non-Interactive Contexts

Interactive selection automatically disables in:
- Scripts (non-TTY stdin)
- Piped input (`echo "1" | ./omnai.sh ...`)
- CI/CD environments
- Background processes

In these contexts, omnai falls back to:
- Engine defaults if no model specified
- Warnings + continue if invalid model specified

## Integration with RalfiePretzel

ralfiepretzel inherits this functionality through `lib/ai.sh`:

```bash
# Wrong model - will prompt for selection
./ralfie build --engine claude --model wrongmodel user-auth.json

# No model - will prompt for selection
./ralfie build --engine claude user-auth.json

# Disable prompts in scripts
OMNAI_INTERACTIVE_SELECT=false ./ralfie build ...
```

## Implementation

The feature consists of two parts:

### 1. Python (`omnai/src/omnai/configs.py`)

```python
def get_model_suggestions(
    model_id: Optional[str] = None,
    engine: Optional[str] = None,
    limit: int = 10
) -> list[dict]:
    """Get model suggestions for interactive selection."""
    # Returns: [{id, full_name, engine, cost, speed, quality}, ...]
```

### 2. Bash (`omnai.sh`)

```bash
ai_select_model_interactive() {
  # 1. Check if TTY and enabled
  # 2. Call Python get_model_suggestions()
  # 3. Display numbered menu
  # 4. Read user input
  # 5. Set AI_MODEL environment variable
}

ai_validate_model() {
  # For claude/opencode/openai:
  #   1. Check if model exists in Python configs
  #   2. If not, call ai_select_model_interactive()
  #   3. Continue with selected model
}
```

## Benefits

### Before (Strict Validation)
```bash
$ ./omnai.sh --engine claude --model wrong "test"
ERROR: Model 'wrong' not found. Did you mean one of these?
  - claude-sonnet-4-20250514 (Claude Sonnet 4) - claude - medium
  - claude-opus-4-20250514 (Claude Opus 4) - claude - expensive

Use: --model <model-id>
$ # User has to re-run command with correct model
```

### After (Interactive Selection)
```bash
$ ./omnai.sh --engine claude --model wrong "test"

Model 'wrong' not found for claude.

Available claude models:
   1. claude-sonnet-4-20250514  - medium cost, fast speed
   2. claude-opus-4-20250514    - expensive cost, slow speed

Select a model [1-2] (or 'q' to quit): 1
✓ Using model: claude-sonnet-4-20250514

[... execution continues immediately ...]
```

## Future Enhancements

- [ ] Remember last selection per engine (caching)
- [ ] Show estimated cost per request
- [ ] Filter by criteria (cost=free, speed=fast, etc.)
- [ ] Integration with `gum choose` for prettier menus
- [ ] Keyboard shortcuts (arrow keys, search)

---

**Related:**
- [omnai Python Configs](src/omnai/configs.py)
- [omnai Bash Library](omnai.sh)
- [Model Validation Strategy](dynamic-model-validation.md)
