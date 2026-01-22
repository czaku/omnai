# Model Validation Strategy - Strict with Suggestions

## Core Principle

**NO SILENT FALLBACKS** - If model doesn't exist, stop execution with helpful error.

---

## Validation Flow

```python
def get_config(model_id: str) -> dict | None:
    """
    Get model config - returns None if not found.
    Caller must handle None (throw error).
    """
    # 1. Exact match
    if model_id in MODEL_CONFIGS:
        return MODEL_CONFIGS[model_id]
    
    # 2. Not found
    return None


def find_similar_models(model_id: str, engine: str = None, limit: int = 5) -> list[dict]:
    """
    Find similar model names for suggestions.
    
    Uses fuzzy matching on:
    - Model ID (e.g., "minimax" matches "minimax-m2.1", "minimax-m2")
    - Provider patterns (e.g., "minimax/" matches "minimax/MiniMax-M2")
    - Engine filter (e.g., only opencode models)
    """
    similar = []
    search_lower = model_id.lower()
    
    for mid, config in MODEL_CONFIGS.items():
        # Filter by engine if specified
        if engine and config.get("engine") != engine:
            continue
        
        # Match partial ID
        if search_lower in mid.lower():
            similar.append({
                "id": mid,
                "full_name": config.get("full_name", mid),
                "engine": config.get("engine"),
                "cost": config.get("cost"),
            })
    
    return similar[:limit]


def validate_model(model_id: str, engine: str = None) -> dict:
    """
    Validate model exists and return config.
    
    Raises:
        ValueError: If model not found (with suggestions if available)
    """
    config = get_config(model_id)
    
    if config is not None:
        # Check engine matches if specified
        if engine and config.get("engine") != engine:
            raise ValueError(
                f"Model '{model_id}' exists but is for engine '{config['engine']}', "
                f"not '{engine}'"
            )
        return config
    
    # Model not found - find similar ones
    similar = find_similar_models(model_id, engine)
    
    if similar:
        # Found similar models - suggest them
        suggestions = "\n".join(
            f"  - {m['id']} ({m['full_name']}) - {m['engine']} - {m['cost']}"
            for m in similar
        )
        raise ValueError(
            f"Model '{model_id}' not found. Did you mean one of these?\n{suggestions}\n\n"
            f"Use: --model <model-id>"
        )
    
    # No similar models found
    engine_msg = f" for engine '{engine}'" if engine else ""
    raise ValueError(
        f"Model '{model_id}' not found{engine_msg}.\n\n"
        f"List available models:\n"
        f"  python -c 'from omnai import list_configs; "
        f"print(\"\\n\".join(c[\"id\"] for c in list_configs()))'"
    )
```

---

## Usage Examples

### Example 1: Exact Match (Success)
```python
>>> validate_model("claude-sonnet-4-20250514")
{"engine": "claude", "model": "claude-sonnet-4-20250514", ...}
```

### Example 2: Typo (Show Suggestions)
```python
>>> validate_model("minimax-m2")
ValueError: Model 'minimax-m2' not found. Did you mean one of these?
  - minimax-m2.1 (MiniMax M2.1) - opencode - cheap
  - minimax-m2-api (MiniMax M2 (API)) - opencode - cheap
  - minimax-m2.1-free (MiniMax M2.1 (Free)) - opencode - free

Use: --model <model-id>
```

### Example 3: Provider Pattern (Inform User)
```python
>>> validate_model("minimax/MiniMax-M3")
ValueError: Model 'minimax/MiniMax-M3' not found. Did you mean one of these?
  - minimax-m2.1-api (uses: minimax/MiniMax-M2.1)
  - minimax-m2-api (uses: minimax/MiniMax-M2)

Provider/Model format detected. To add custom models:
  1. Check if provider is supported by opencode
  2. Add to MODEL_CONFIGS in omnai/src/omnai/configs.py
  3. Or use existing model ID from list above
```

### Example 4: Wrong Engine
```python
>>> validate_model("qwen2.5-coder:7b", engine="claude")
ValueError: Model 'qwen2.5-coder:7b' exists but is for engine 'ollama', not 'claude'
```

### Example 5: No Matches
```python
>>> validate_model("nonexistent-model-xyz")
ValueError: Model 'nonexistent-model-xyz' not found.

List available models:
  python -c 'from omnai import list_configs; print("\n".join(c["id"] for c in list_configs()))'
```

---

## Bash Script Integration

In omnai.sh and ralfiepretzel.sh:

```bash
# Validate model before execution
validate_model_or_die() {
  local model="$1"
  local engine="$2"
  
  # Call Python validation
  python3 -c "
from omnai import validate_model
try:
    validate_model('$model', engine='$engine' if '$engine' else None)
except ValueError as e:
    print(e, file=sys.stderr)
    sys.exit(1)
" || return 1
  
  return 0
}

# Usage in ai_run:
if [[ -n "$AI_MODEL" ]]; then
  validate_model_or_die "$AI_MODEL" "$AI_ENGINE" || exit 1
fi
```

---

## Benefits

1. **No silent failures** - Always error on unknown models
2. **Helpful suggestions** - Show similar models to guide user
3. **Clear error messages** - Explain exactly what went wrong
4. **Pattern detection** - Recognize provider/model format and suggest correct approach
5. **Engine validation** - Ensure model matches specified engine

---

## Implementation Checklist

- [ ] Add `find_similar_models()` function to configs.py
- [ ] Add `validate_model()` function to configs.py
- [ ] Update `get_config()` docstring to clarify it returns None
- [ ] Add validation to omnai.sh before model execution
- [ ] Add validation to ralfiepretzel.sh before PRD execution
- [ ] Add tests for validation edge cases
- [ ] Update README with model validation examples
