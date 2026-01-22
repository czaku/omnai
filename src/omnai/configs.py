"""Model configurations for omnai.

Comprehensive model registry with practical metadata including cost, speed,
quality ratings, and use-case recommendations.

Architecture:
- ENGINE_CONFIGS: Registry of supported engines with their characteristics
- MODEL_CONFIGS: Detailed model configurations with metadata
- Query functions: find_configs(), get_config(), list_configs()

Example:
    >>> from omnai import get_config, find_configs
    >>> config = get_config("claude-sonnet-4-20250514")
    >>> print(f"Cost: {config['cost']}, Best for: {config['best_for']}")
    >>>
    >>> # Find free models good for coding
    >>> free_coding = find_configs(cost="free", best_for="coding")
"""

from dataclasses import dataclass, field
from typing import Any, Literal, Optional

# Type aliases
CostLevel = Literal["free", "cheap", "medium", "expensive"]
SpeedLevel = Literal["very-fast", "fast", "medium", "slow", "very-slow"]
QualityLevel = Literal["excellent", "good", "fair", "basic"]

#------------------------------------------------------------------------------
# Engine Configurations
#------------------------------------------------------------------------------

ENGINE_CONFIGS = {
    "claude": {
        "name": "Claude CLI",
        "description": "Anthropic's Claude via CLI tool",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": "claude-sonnet-4-20250514",
        "aliases": ["claude-code"],  # claude-code is an alias for claude
    },
    "opencode": {
        "name": "OpenCode",
        "description": "Multi-provider AI tool (OpenAI, DeepSeek, MiniMax)",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": "gpt-4o",
    },
    "codex": {
        "name": "Codex CLI",
        "description": "OpenAI Codex CLI (supports multiple providers)",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": "deepseek-v3",
    },
    "ollama": {
        "name": "Ollama",
        "description": "Local inference with open models",
        "type": "local",
        "requires_auth": False,
        "supports_streaming": True,
        "default_model": "qwen2.5-coder:7b",
    },
    "aider": {
        "name": "Aider",
        "description": "AI pair programming assistant",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": None,  # Configured via .aider.conf.yml
    },
    "qwen": {
        "name": "Qwen-Code CLI",
        "description": "Qwen AI coding assistant",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": None,
    },
    "cursor": {
        "name": "Cursor Agent",
        "description": "Cursor AI editor agent",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": None,
    },
    "goose": {
        "name": "Goose CLI",
        "description": "Block's Goose AI assistant",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": None,
    },
    "copilot": {
        "name": "GitHub Copilot CLI",
        "description": "GitHub Copilot command-line interface",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": None,
    },
}

#------------------------------------------------------------------------------
# Model Configurations with Rich Metadata
#------------------------------------------------------------------------------

MODEL_CONFIGS = {
    #--------------------------------------------------------------------------
    # Claude Models (claude engine / claude-code CLI)
    #--------------------------------------------------------------------------
    "claude-sonnet-4-20250514": {
        "engine": "claude",
        "model": "claude-sonnet-4-20250514",
        "full_name": "Claude Sonnet 4 (May 2025)",
        "context_window": 200_000,
        "default_temperature": 0.7,

        # Practical metadata
        "cost": "medium",
        "cost_per_mtok": {"input": 3.0, "output": 15.0},  # USD
        "free_tier": True,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "analysis", "reasoning", "general"],
        "notes": "Best balance of speed, quality, and cost. Recommended default.",
    },

    "claude-opus-4-20250514": {
        "engine": "claude",
        "model": "claude-opus-4-20250514",
        "full_name": "Claude Opus 4 (May 2025)",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "expensive",
        "cost_per_mtok": {"input": 15.0, "output": 75.0},
        "free_tier": False,
        "speed": "slow",
        "quality": "excellent",
        "best_for": ["complex-reasoning", "research", "high-stakes", "difficult-problems"],
        "notes": "Use when quality matters more than cost/speed. 5x more expensive than Sonnet.",
    },

    "claude-sonnet-3.7": {
        "engine": "claude",
        "model": "claude-sonnet-3.7",
        "full_name": "Claude Sonnet 3.7",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "medium",
        "cost_per_mtok": {"input": 3.0, "output": 15.0},
        "free_tier": True,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "analysis", "reasoning"],
        "notes": "Previous generation Sonnet. Still very capable.",
    },

    "claude-haiku-3.5": {
        "engine": "claude",
        "model": "claude-haiku-3.5",
        "full_name": "Claude Haiku 3.5",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.8, "output": 4.0},
        "free_tier": True,
        "speed": "very-fast",
        "quality": "good",
        "best_for": ["simple-tasks", "batch-processing", "quick-responses"],
        "notes": "Fastest and cheapest Claude model. Good for simple, straightforward tasks.",
    },

    #--------------------------------------------------------------------------
    # OpenCode Models (OpenAI + others via opencode.ai)
    #--------------------------------------------------------------------------
    "gpt-4o": {
        "engine": "opencode",
        "model": "gpt-4o",
        "full_name": "GPT-4o",
        "context_window": 128_000,
        "default_temperature": 1.0,

        "cost": "medium",
        "cost_per_mtok": {"input": 2.5, "output": 10.0},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "multimodal", "general", "reasoning"],
        "notes": "OpenAI's flagship model. Optimized for speed and cost.",
    },

    "gpt-4-turbo": {
        "engine": "opencode",
        "model": "gpt-4-turbo",
        "full_name": "GPT-4 Turbo",
        "context_window": 128_000,
        "default_temperature": 1.0,

        "cost": "medium",
        "cost_per_mtok": {"input": 10.0, "output": 30.0},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "analysis", "reasoning"],
        "notes": "Previous generation GPT-4. Still very capable.",
    },

    "gpt-3.5-turbo": {
        "engine": "opencode",
        "model": "gpt-3.5-turbo",
        "full_name": "GPT-3.5 Turbo",
        "context_window": 16_385,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.5, "output": 1.5},
        "free_tier": False,
        "speed": "very-fast",
        "quality": "good",
        "best_for": ["simple-tasks", "batch-processing", "prototyping"],
        "notes": "Fastest and cheapest OpenAI model. Good for simple tasks.",
    },

    "o1-preview": {
        "engine": "opencode",
        "model": "o1-preview",
        "full_name": "OpenAI o1 Preview",
        "context_window": 128_000,
        "default_temperature": 1.0,

        "cost": "expensive",
        "cost_per_mtok": {"input": 15.0, "output": 60.0},
        "free_tier": False,
        "speed": "slow",
        "quality": "excellent",
        "best_for": ["complex-reasoning", "math", "science", "research"],
        "notes": "Advanced reasoning model. Uses extended thinking time for hard problems.",
    },

    "o1": {
        "engine": "opencode",
        "model": "o1",
        "full_name": "OpenAI o1",
        "context_window": 200_000,
        "default_temperature": 1.0,

        "cost": "expensive",
        "cost_per_mtok": {"input": 15.0, "output": 60.0},
        "free_tier": False,
        "speed": "slow",
        "quality": "excellent",
        "best_for": ["complex-reasoning", "production", "high-stakes"],
        "notes": "Production reasoning model with extended context.",
    },

    "deepseek-chat": {
        "engine": "opencode",
        "model": "deepseek-chat",
        "full_name": "DeepSeek V3",
        "context_window": 64_000,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.14, "output": 0.28},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "reasoning", "cost-efficiency"],
        "notes": "DeepSeek V3. Extremely cost-efficient with excellent coding ability.",
    },

    "minimax-m2.1": {
        "engine": "opencode",
        "model": "minimax-m2.1",
        "full_name": "MiniMax M2.1",
        "context_window": 32_000,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.1, "output": 0.1},
        "free_tier": False,
        "speed": "fast",
        "quality": "good",
        "best_for": ["general", "cost-efficiency"],
        "notes": "MiniMax's latest model. Very cost-efficient.",
    },

    # OpenCode Free Tier Models
    "minimax-m2.1-free": {
        "engine": "opencode",
        "model": "minimax-m2.1-free",
        "full_name": "MiniMax M2.1 (Free)",
        "context_window": 32_000,
        "default_temperature": 1.0,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "fast",
        "quality": "good",
        "best_for": ["general", "cost-efficiency", "prototyping"],
        "notes": "Free tier MiniMax M2.1 via opencode. No API key required.",
    },

    "big-pickle": {
        "engine": "opencode",
        "model": "big-pickle",
        "full_name": "Big Pickle",
        "context_window": 200_000,
        "default_temperature": 1.0,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["general", "reasoning", "long-context"],
        "notes": "Free reasoning model via opencode. 200K context window.",
    },

    "glm-4.7-free": {
        "engine": "opencode",
        "model": "glm-4.7-free",
        "full_name": "GLM-4.7 (Free)",
        "context_window": 204_000,
        "default_temperature": 1.0,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["general", "long-context", "analysis"],
        "notes": "Free GLM model via opencode. 204K context window for extensive documents.",
    },

    "gpt-5-nano": {
        "engine": "opencode",
        "model": "gpt-5-nano",
        "full_name": "GPT-5 Nano",
        "context_window": 16_000,
        "default_temperature": 1.0,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "very-fast",
        "quality": "fair",
        "best_for": ["simple-tasks", "testing", "prototyping"],
        "notes": "Free lightweight model via opencode. Good for simple tasks.",
    },

    "grok-code": {
        "engine": "opencode",
        "model": "grok-code",
        "full_name": "Grok Code",
        "context_window": 32_000,
        "default_temperature": 1.0,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "fast",
        "quality": "good",
        "best_for": ["coding", "debugging", "prototyping"],
        "notes": "Free coding-focused model via opencode.",
    },

    # OpenCode Private API Models (provider/model format)
    "minimax-m2": {
        "engine": "opencode",
        "model": "minimax/MiniMax-M2",
        "full_name": "MiniMax M2 (API)",
        "context_window": 32_000,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.3, "output": 1.2},
        "free_tier": False,
        "speed": "fast",
        "quality": "good",
        "best_for": ["general", "cost-efficiency"],
        "notes": "MiniMax M2 via private API key. Use --model minimax/MiniMax-M2.",
    },

    "minimax-m2.1-api": {
        "engine": "opencode",
        "model": "minimax/MiniMax-M2.1",
        "full_name": "MiniMax M2.1 (API)",
        "context_window": 32_000,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.3, "output": 1.2},
        "free_tier": False,
        "speed": "fast",
        "quality": "good",
        "best_for": ["general", "cost-efficiency"],
        "notes": "MiniMax M2.1 via private API key. Use --model minimax/MiniMax-M2.1.",
    },

    #--------------------------------------------------------------------------
    # Codex Models (OpenAI Codex CLI)
    #--------------------------------------------------------------------------
    "deepseek-v3": {
        "engine": "codex",
        "model": "deepseek-v3",
        "full_name": "DeepSeek V3 (via Codex)",
        "context_window": 64_000,
        "default_temperature": 1.0,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.14, "output": 0.28},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "reasoning"],
        "notes": "DeepSeek V3 via Codex CLI. Excellent for coding.",
    },

    "claude-sonnet-4": {
        "engine": "codex",
        "model": "claude-sonnet-4",
        "full_name": "Claude Sonnet 4 (via Codex)",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "medium",
        "cost_per_mtok": {"input": 3.0, "output": 15.0},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "reasoning"],
        "notes": "Claude Sonnet 4 accessed via Codex CLI.",
    },

    #--------------------------------------------------------------------------
    # Ollama Models (Local Inference)
    #--------------------------------------------------------------------------
    "qwen2.5-coder:7b": {
        "engine": "ollama",
        "model": "qwen2.5-coder:7b",
        "full_name": "Qwen 2.5 Coder 7B",
        "context_window": 32_768,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",  # Depends on hardware
        "quality": "good",
        "best_for": ["coding", "offline-work", "privacy", "local-dev"],
        "notes": "Free local inference. Excellent for coding. Requires ~6GB RAM.",
    },

    "qwen2.5-coder:14b": {
        "engine": "ollama",
        "model": "qwen2.5-coder:14b",
        "full_name": "Qwen 2.5 Coder 14B",
        "context_window": 32_768,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["coding", "offline-work", "privacy"],
        "notes": "Larger Qwen model. Better quality than 7B. Requires ~12GB RAM.",
    },

    "qwen2.5-coder:32b": {
        "engine": "ollama",
        "model": "qwen2.5-coder:32b",
        "full_name": "Qwen 2.5 Coder 32B",
        "context_window": 32_768,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "slow",
        "quality": "excellent",
        "best_for": ["coding", "complex-problems", "local-dev"],
        "notes": "Largest Qwen coder. Best quality. Requires ~24GB RAM.",
    },

    "deepseek-coder-v2:16b": {
        "engine": "ollama",
        "model": "deepseek-coder-v2:16b",
        "full_name": "DeepSeek Coder V2 16B",
        "context_window": 16_384,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["coding", "local-dev"],
        "notes": "DeepSeek's local coding model. Strong performance. Requires ~12GB RAM.",
    },

    "codellama:7b": {
        "engine": "ollama",
        "model": "codellama:7b",
        "full_name": "Code Llama 7B",
        "context_window": 16_384,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "fast",
        "quality": "fair",
        "best_for": ["coding", "local-dev", "lightweight"],
        "notes": "Meta's Code Llama. Lightweight option. Requires ~5GB RAM.",
    },

    "llama3.2:3b": {
        "engine": "ollama",
        "model": "llama3.2:3b",
        "full_name": "Llama 3.2 3B",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "very-fast",
        "quality": "fair",
        "best_for": ["simple-tasks", "lightweight", "prototyping"],
        "notes": "Ultra-lightweight general model. Fast inference. Requires ~2GB RAM.",
    },

    "llama3.2": {
        "engine": "ollama",
        "model": "llama3.2",
        "full_name": "Llama 3.2",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["general", "local-dev"],
        "notes": "General-purpose Llama model. Balanced performance.",
    },

    "llama3.1": {
        "engine": "ollama",
        "model": "llama3.1",
        "full_name": "Llama 3.1",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["general", "local-dev"],
        "notes": "Previous generation Llama. Still capable.",
    },

    "mistral": {
        "engine": "ollama",
        "model": "mistral",
        "full_name": "Mistral 7B",
        "context_window": 32_768,
        "default_temperature": 0.7,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "fast",
        "quality": "good",
        "best_for": ["general", "lightweight"],
        "notes": "Mistral's 7B model. Good general performance. Requires ~5GB RAM.",
    },

    "deepseek-coder": {
        "engine": "ollama",
        "model": "deepseek-coder",
        "full_name": "DeepSeek Coder",
        "context_window": 16_384,
        "default_temperature": 0.2,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "medium",
        "quality": "good",
        "best_for": ["coding", "local-dev"],
        "notes": "DeepSeek's original coding model.",
    },
}

#------------------------------------------------------------------------------
# Custom Configs Registry (User-registered models)
#------------------------------------------------------------------------------

_CUSTOM_CONFIGS: dict[str, dict[str, Any]] = {}

#------------------------------------------------------------------------------
# Query Functions
#------------------------------------------------------------------------------

def get_config(model_id: str) -> Optional[dict[str, Any]]:
    """Get configuration for a specific model.

    Args:
        model_id: The model identifier

    Returns:
        Model configuration dict with all metadata, or None if not found

    Example:
        >>> config = get_config("gpt-4o")
        >>> print(f"Cost: ${config['cost_per_mtok']['output']}/M output tokens")
    """
    # Check built-in configs first
    if model_id in MODEL_CONFIGS:
        config = MODEL_CONFIGS[model_id].copy()
        config["id"] = model_id
        return config

    # Check custom configs
    if model_id in _CUSTOM_CONFIGS:
        config = _CUSTOM_CONFIGS[model_id].copy()
        config["id"] = model_id
        return config

    return None


def list_configs(engine: Optional[str] = None) -> list[dict[str, Any]]:
    """List all available model configurations, optionally filtered by engine.

    Args:
        engine: Optional engine name to filter by

    Returns:
        List of model configurations with metadata

    Example:
        >>> ollama_models = list_configs(engine="ollama")
        >>> for model in ollama_models:
        ...     print(f"{model['id']}: {model['notes']}")
    """
    configs = []

    # Add built-in configs
    for model_id, config in MODEL_CONFIGS.items():
        if engine is None or config["engine"] == engine:
            model_config = config.copy()
            model_config["id"] = model_id
            configs.append(model_config)

    # Add custom configs
    for model_id, config in _CUSTOM_CONFIGS.items():
        if engine is None or config.get("engine") == engine:
            model_config = config.copy()
            model_config["id"] = model_id
            configs.append(model_config)

    return configs


def find_configs(
    cost: Optional[str | list[str]] = None,
    speed: Optional[str | list[str]] = None,
    quality: Optional[str | list[str]] = None,
    best_for: Optional[str | list[str]] = None,
    free_tier: Optional[bool] = None,
    engine: Optional[str | list[str]] = None,
) -> list[dict[str, Any]]:
    """Find models matching the specified criteria.

    All criteria are ANDed together. List values within a criterion are ORed.

    Args:
        cost: Cost level(s): free, cheap, medium, expensive
        speed: Speed level(s): very-fast, fast, medium, slow, very-slow
        quality: Quality level(s): excellent, good, fair, basic
        best_for: Use case(s): coding, reasoning, general, etc.
        free_tier: Whether model has free tier access
        engine: Engine name(s): claude, opencode, ollama, etc.

    Returns:
        List of matching model configurations

    Example:
        >>> # Find free models good for coding
        >>> models = find_configs(cost="free", best_for="coding")
        >>>
        >>> # Find fast, cheap models
        >>> models = find_configs(cost=["free", "cheap"], speed="fast")
    """
    # Normalize list parameters
    def normalize(value):
        if value is None:
            return None
        return [value] if isinstance(value, str) else value

    cost_list = normalize(cost)
    speed_list = normalize(speed)
    quality_list = normalize(quality)
    best_for_list = normalize(best_for)
    engine_list = normalize(engine)

    results = []

    for model_id, config in {**MODEL_CONFIGS, **_CUSTOM_CONFIGS}.items():
        # Check each criterion
        if cost_list and config.get("cost") not in cost_list:
            continue
        if speed_list and config.get("speed") not in speed_list:
            continue
        if quality_list and config.get("quality") not in quality_list:
            continue
        if free_tier is not None and config.get("free_tier") != free_tier:
            continue
        if engine_list and config.get("engine") not in engine_list:
            continue
        if best_for_list:
            model_use_cases = config.get("best_for", [])
            if not any(use in model_use_cases for use in best_for_list):
                continue

        # Model matches all criteria
        model_config = config.copy()
        model_config["id"] = model_id
        results.append(model_config)

    return results


def get_default_model(engine: str) -> Optional[str]:
    """Get the default model for an engine.

    Args:
        engine: Engine name (e.g., "claude", "ollama")

    Returns:
        Default model ID for the engine, or None if engine not found

    Example:
        >>> default = get_default_model("ollama")
        >>> print(default)  # "qwen2.5-coder:7b"
    """
    # Handle aliases
    if engine == "claude-code":
        engine = "claude"

    if engine in ENGINE_CONFIGS:
        return ENGINE_CONFIGS[engine].get("default_model")
    return None


def list_engines() -> list[dict[str, Any]]:
    """List all supported engines.

    Returns:
        List of engine configurations with metadata

    Example:
        >>> engines = list_engines()
        >>> for engine in engines:
        ...     print(f"{engine['id']}: {engine['description']}")
    """
    engines = []
    for engine_id, config in ENGINE_CONFIGS.items():
        engine_config = config.copy()
        engine_config["id"] = engine_id
        engines.append(engine_config)
    return engines


#------------------------------------------------------------------------------
# Validation Functions
#------------------------------------------------------------------------------

def find_similar_models(
    model_id: str,
    engine: Optional[str] = None,
    limit: int = 5
) -> list[dict[str, Any]]:
    """Find similar model names for helpful suggestions.

    Uses fuzzy matching on model IDs to suggest alternatives when
    a model is not found. Useful for typos or partial names.

    Args:
        model_id: The model identifier to search for
        engine: Optional engine filter (only suggest models for this engine)
        limit: Maximum number of suggestions to return

    Returns:
        List of similar model configs with id, full_name, engine, cost

    Example:
        >>> similar = find_similar_models("minimax-m2", engine="opencode")
        >>> for m in similar:
        ...     print(f"{m['id']} - {m['cost']}")
        minimax-m2.1 - cheap
        minimax-m2-api - cheap
    """
    similar = []
    search_lower = model_id.lower()

    # Search in both built-in and custom configs
    all_configs = {}
    for mid, cfg in MODEL_CONFIGS.items():
        all_configs[mid] = cfg
    for mid, cfg in _CUSTOM_CONFIGS.items():
        all_configs[mid] = cfg

    for mid, config in all_configs.items():
        # Filter by engine if specified
        if engine and config.get("engine") != engine:
            continue

        mid_lower = mid.lower()

        # Match strategies (in order of priority):
        # 1. Exact substring match
        # 2. Search term is in model ID
        # 3. Model ID starts with search term
        # 4. Common prefix (for typos like "minimax-m3" -> "minimax-m2")
        matched = False

        if search_lower in mid_lower or mid_lower in search_lower:
            matched = True
        elif mid_lower.startswith(search_lower) or search_lower.startswith(mid_lower[:len(search_lower)//2] if len(search_lower) > 3 else ""):
            matched = True
        else:
            # Check for common prefix (at least 5 chars)
            common_len = 0
            for i, (c1, c2) in enumerate(zip(search_lower, mid_lower)):
                if c1 == c2:
                    common_len = i + 1
                else:
                    break
            if common_len >= 5:
                matched = True

        if matched:
            similar.append({
                "id": mid,
                "full_name": config.get("full_name", mid),
                "engine": config.get("engine"),
                "cost": config.get("cost", "unknown"),
                "speed": config.get("speed", "unknown"),
                "quality": config.get("quality", "unknown"),
                "model": config.get("model"),  # Actual model string used
            })

    return similar[:limit]


def get_model_suggestions(
    model_id: Optional[str] = None,
    engine: Optional[str] = None,
    limit: int = 10
) -> list[dict[str, Any]]:
    """Get model suggestions for interactive selection.

    Returns structured model data suitable for building selection menus.
    If model_id is provided, finds similar models. Otherwise, lists all
    models for the specified engine (or all models if no engine).

    Args:
        model_id: Optional partial/incorrect model name to find similar to
        engine: Optional engine to filter by
        limit: Maximum number of suggestions (default: 10)

    Returns:
        List of model dicts with: id, full_name, engine, cost, speed, quality

    Example:
        >>> # Get all claude models
        >>> suggestions = get_model_suggestions(engine="claude")
        >>> for s in suggestions:
        ...     print(f"{s['id']} - {s['cost']} cost, {s['speed']} speed")

        >>> # Find models similar to typo
        >>> suggestions = get_model_suggestions(model_id="minimax-m3", engine="opencode")
        >>> # Returns minimax-m2.1, minimax-m2, etc.
    """
    if model_id:
        # Find similar models (typo correction)
        return find_similar_models(model_id, engine, limit)
    else:
        # List all models for engine
        configs = list_configs(engine=engine)
        return [{
            "id": c["id"],
            "full_name": c.get("full_name", c["id"]),
            "engine": c["engine"],
            "cost": c.get("cost", "unknown"),
            "speed": c.get("speed", "unknown"),
            "quality": c.get("quality", "unknown"),
        } for c in configs[:limit]]


def validate_model(model_id: str, engine: Optional[str] = None) -> dict[str, Any]:
    """Validate that a model exists and return its configuration.

    Strict validation with helpful error messages and suggestions.
    Does NOT silently fall back or auto-generate configs.

    Args:
        model_id: The model identifier to validate
        engine: Optional engine to validate against

    Returns:
        Model configuration dict if valid

    Raises:
        ValueError: If model not found (with suggestions if available)
        ValueError: If model exists but engine doesn't match

    Example:
        >>> config = validate_model("claude-sonnet-4-20250514")
        >>> print(config["engine"])
        claude

        >>> validate_model("minimax-m2")  # Typo
        ValueError: Model 'minimax-m2' not found. Did you mean one of these?
          - minimax-m2.1 (MiniMax M2.1) - opencode - cheap
          - minimax-m2-api (MiniMax M2 (API)) - opencode - cheap
    """
    config = get_config(model_id)

    if config is not None:
        # Model exists - check engine matches if specified
        if engine and config.get("engine") != engine:
            raise ValueError(
                f"Model '{model_id}' exists but is for engine '{config['engine']}', "
                f"not '{engine}'"
            )
        return config

    # Model not found - find similar ones for suggestions
    similar = find_similar_models(model_id, engine)

    if similar:
        # Found similar models - show suggestions
        suggestions = "\n".join(
            f"  - {m['id']} ({m['full_name']}) - {m['engine']} - {m['cost']}"
            for m in similar
        )
        engine_msg = f" for engine '{engine}'" if engine else ""
        raise ValueError(
            f"Model '{model_id}' not found{engine_msg}. Did you mean one of these?\n"
            f"{suggestions}\n\n"
            f"Use: --model <model-id>"
        )

    # No similar models found - provide generic help
    engine_msg = f" for engine '{engine}'" if engine else ""
    engine_filter = f', engine="{engine}"' if engine else ""
    raise ValueError(
        f"Model '{model_id}' not found{engine_msg}.\n\n"
        f"List available models:\n"
        f"  python -c 'from omnai import list_configs; "
        f"configs = list_configs({engine_filter}); "
        f"print(\"\\n\".join(c[\"id\"] for c in configs))'"
    )


#------------------------------------------------------------------------------
# Extension API (for custom models)
#------------------------------------------------------------------------------

def register_config(
    model_id: str,
    config: dict[str, Any],
    override: bool = False
) -> bool:
    """Register a custom model configuration.

    Args:
        model_id: Unique identifier for the model
        config: Model configuration dict (must include at least "engine" and "model")
        override: Whether to override existing config with same ID

    Returns:
        True if registered successfully, False if ID already exists and override=False

    Example:
        >>> register_config("my-model", {
        ...     "engine": "ollama",
        ...     "model": "custom:latest",
        ...     "cost": "free",
        ...     "speed": "fast",
        ...     "quality": "good",
        ...     "best_for": ["testing"],
        ... })
    """
    if model_id in _CUSTOM_CONFIGS and not override:
        return False

    # Ensure required fields with defaults
    full_config = {
        "cost": "medium",
        "speed": "medium",
        "quality": "good",
        "best_for": [],
        "free_tier": False,
        "cost_per_mtok": {"input": 0, "output": 0},
        "notes": "",
        **config,
    }

    _CUSTOM_CONFIGS[model_id] = full_config
    return True


def list_custom_configs() -> list[dict[str, Any]]:
    """List all custom (user-registered) model configurations.

    Returns:
        List of custom model configurations
    """
    configs = []
    for model_id, config in _CUSTOM_CONFIGS.items():
        model_config = config.copy()
        model_config["id"] = model_id
        configs.append(model_config)
    return configs
