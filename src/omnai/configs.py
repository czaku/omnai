"""Model configurations for omnai.

Comprehensive model registry with practical metadata including cost, speed,
quality ratings, and use-case recommendations.

Architecture:
- ENGINE_CONFIGS: Registry of supported engines with their characteristics
- MODEL_CONFIGS: Detailed model configurations with metadata
- Query functions: find_configs(), get_config(), list_configs()

Example:
    >>> from omnai import get_config, find_configs
    >>> config = get_config("claude-sonnet-4.5")
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
    "claude-code": {
        "name": "Claude Code",
        "description": "Anthropic's Claude via official CLI tool",
        "type": "cloud",
        "requires_auth": True,
        "supports_streaming": True,
        "default_model": "sonnet-4.5",
    },
    "claude": {
        "name": "Claude API",
        "description": "Anthropic's Claude via direct API",
        "type": "cloud",
        "requires_auth": True,
        "requires_api_key": True,
        "supports_streaming": True,
        "default_model": "claude-sonnet-4-5-20250929",
    },
    "ollama": {
        "name": "Ollama",
        "description": "Local inference with open models",
        "type": "local",
        "requires_auth": False,
        "supports_streaming": True,
        "default_model": "qwen2.5-coder:7b",
    },
    "openai": {
        "name": "OpenAI",
        "description": "OpenAI's GPT models via API",
        "type": "cloud",
        "requires_auth": True,
        "requires_api_key": True,
        "supports_streaming": True,
        "default_model": "gpt-4o",
    },
}

#------------------------------------------------------------------------------
# Model Configurations with Rich Metadata
#------------------------------------------------------------------------------

MODEL_CONFIGS = {
    #--------------------------------------------------------------------------
    # Claude Models (claude-code engine)
    #--------------------------------------------------------------------------
    "sonnet-4.5": {
        "engine": "claude-code",
        "model": "sonnet-4.5",
        "full_name": "Claude Sonnet 4.5",
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

    "opus-4.5": {
        "engine": "claude-code",
        "model": "opus-4.5",
        "full_name": "Claude Opus 4.5",
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

    "haiku-4": {
        "engine": "claude-code",
        "model": "haiku-4",
        "full_name": "Claude Haiku 4",
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
    # Claude API Models
    #--------------------------------------------------------------------------
    "claude-sonnet-4-5-20250929": {
        "engine": "claude",
        "model": "claude-sonnet-4-5-20250929",
        "full_name": "Claude Sonnet 4.5 (API)",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "medium",
        "cost_per_mtok": {"input": 3.0, "output": 15.0},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["coding", "analysis", "reasoning", "api-integration"],
        "notes": "Direct API access. Same as claude-code sonnet-4.5 but requires API key.",
    },

    "claude-opus-4-5-20251101": {
        "engine": "claude",
        "model": "claude-opus-4-5-20251101",
        "full_name": "Claude Opus 4.5 (API)",
        "context_window": 200_000,
        "default_temperature": 0.7,

        "cost": "expensive",
        "cost_per_mtok": {"input": 15.0, "output": 75.0},
        "free_tier": False,
        "speed": "slow",
        "quality": "excellent",
        "best_for": ["complex-reasoning", "research", "api-integration"],
        "notes": "Direct API access. Most capable Claude model.",
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
        "speed": "slow",  # Larger model
        "quality": "excellent",
        "best_for": ["coding", "complex-tasks", "offline-work"],
        "notes": "Largest Qwen Coder model. Best quality. Requires ~24GB RAM.",
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
        "best_for": ["coding", "offline-work", "privacy"],
        "notes": "Strong coding model. Alternative to Qwen. Requires ~12GB RAM.",
    },

    "llama3.2:3b": {
        "engine": "ollama",
        "model": "llama3.2:3b",
        "full_name": "Llama 3.2 3B",
        "context_window": 131_072,
        "default_temperature": 0.7,

        "cost": "free",
        "cost_per_mtok": {"input": 0, "output": 0},
        "free_tier": True,
        "speed": "very-fast",
        "quality": "fair",
        "best_for": ["simple-tasks", "low-resource", "offline-work"],
        "notes": "Lightweight model. Fast inference. Good for simple tasks. Requires ~3GB RAM.",
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
        "speed": "medium",
        "quality": "fair",
        "best_for": ["coding", "offline-work", "legacy-support"],
        "notes": "Older coding model. Superseded by Qwen/DeepSeek but still useful. Requires ~6GB RAM.",
    },

    #--------------------------------------------------------------------------
    # OpenAI Models
    #--------------------------------------------------------------------------
    "gpt-4o": {
        "engine": "openai",
        "model": "gpt-4o",
        "full_name": "GPT-4o",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "medium",
        "cost_per_mtok": {"input": 2.5, "output": 10.0},
        "free_tier": False,
        "speed": "fast",
        "quality": "excellent",
        "best_for": ["general", "coding", "multimodal"],
        "notes": "Latest GPT-4. Fast and capable. Good for multimodal tasks.",
    },

    "gpt-4o-mini": {
        "engine": "openai",
        "model": "gpt-4o-mini",
        "full_name": "GPT-4o Mini",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.15, "output": 0.6},
        "free_tier": False,
        "speed": "very-fast",
        "quality": "good",
        "best_for": ["simple-tasks", "batch-processing", "cost-sensitive"],
        "notes": "Cheap and fast. Good for simple tasks. 15x cheaper than GPT-4o.",
    },

    "gpt-4-turbo": {
        "engine": "openai",
        "model": "gpt-4-turbo",
        "full_name": "GPT-4 Turbo",
        "context_window": 128_000,
        "default_temperature": 0.7,

        "cost": "expensive",
        "cost_per_mtok": {"input": 10.0, "output": 30.0},
        "free_tier": False,
        "speed": "medium",
        "quality": "excellent",
        "best_for": ["complex-reasoning", "analysis"],
        "notes": "Previous generation. Generally superseded by GPT-4o.",
    },

    "gpt-3.5-turbo": {
        "engine": "openai",
        "model": "gpt-3.5-turbo",
        "full_name": "GPT-3.5 Turbo",
        "context_window": 16_385,
        "default_temperature": 0.7,

        "cost": "cheap",
        "cost_per_mtok": {"input": 0.5, "output": 1.5},
        "free_tier": False,
        "speed": "very-fast",
        "quality": "fair",
        "best_for": ["simple-tasks", "legacy-support", "cost-sensitive"],
        "notes": "Older model. Cheap and fast. Superseded by gpt-4o-mini.",
    },
}

#------------------------------------------------------------------------------
# Query Functions
#------------------------------------------------------------------------------

def get_config(model_id: str) -> Optional[dict[str, Any]]:
    """Get configuration for a specific model.

    Args:
        model_id: Model identifier (e.g., "sonnet-4.5", "qwen2.5-coder:7b")

    Returns:
        Model configuration dict or None if not found

    Example:
        >>> config = get_config("sonnet-4.5")
        >>> print(f"Cost: {config['cost']}")
        >>> print(f"Best for: {', '.join(config['best_for'])}")
    """
    return MODEL_CONFIGS.get(model_id)


def list_configs(engine: Optional[str] = None) -> list[dict[str, Any]]:
    """List all model configurations, optionally filtered by engine.

    Args:
        engine: Optional engine to filter by (e.g., "claude-code", "ollama")

    Returns:
        List of model configuration dicts

    Example:
        >>> # List all models
        >>> all_models = list_configs()
        >>>
        >>> # List only Ollama models
        >>> ollama_models = list_configs(engine="ollama")
    """
    if engine:
        return [
            {**config, "id": model_id}
            for model_id, config in MODEL_CONFIGS.items()
            if config["engine"] == engine
        ]
    return [
        {**config, "id": model_id}
        for model_id, config in MODEL_CONFIGS.items()
    ]


def find_configs(
    cost: Optional[str | list[str]] = None,
    speed: Optional[str | list[str]] = None,
    quality: Optional[str | list[str]] = None,
    best_for: Optional[str | list[str]] = None,
    free_tier: Optional[bool] = None,
    engine: Optional[str | list[str]] = None,
) -> list[dict[str, Any]]:
    """Find models matching criteria.

    Args:
        cost: Cost level(s): "free", "cheap", "medium", "expensive"
        speed: Speed level(s): "very-fast", "fast", "medium", "slow", "very-slow"
        quality: Quality level(s): "excellent", "good", "fair", "basic"
        best_for: Use case(s): "coding", "general", "research", etc.
        free_tier: True to only show models with free tier
        engine: Engine(s) to filter by

    Returns:
        List of matching model configurations

    Example:
        >>> # Find free models good for coding
        >>> free_coding = find_configs(cost="free", best_for="coding")
        >>>
        >>> # Find fast, cheap models
        >>> fast_cheap = find_configs(
        ...     cost=["free", "cheap"],
        ...     speed=["very-fast", "fast"]
        ... )
    """
    results = []

    # Normalize list parameters
    if isinstance(cost, str):
        cost = [cost]
    if isinstance(speed, str):
        speed = [speed]
    if isinstance(quality, str):
        quality = [quality]
    if isinstance(best_for, str):
        best_for = [best_for]
    if isinstance(engine, str):
        engine = [engine]

    for model_id, config in MODEL_CONFIGS.items():
        # Apply filters
        if cost and config["cost"] not in cost:
            continue
        if speed and config["speed"] not in speed:
            continue
        if quality and config["quality"] not in quality:
            continue
        if best_for and not any(use in config["best_for"] for use in best_for):
            continue
        if free_tier is not None and config["free_tier"] != free_tier:
            continue
        if engine and config["engine"] not in engine:
            continue

        results.append({**config, "id": model_id})

    return results


def get_default_model(engine: str) -> Optional[str]:
    """Get the default model for an engine.

    Args:
        engine: Engine name (e.g., "claude-code", "ollama")

    Returns:
        Default model ID or None if engine not found

    Example:
        >>> default = get_default_model("claude-code")
        >>> print(default)  # "sonnet-4.5"
    """
    engine_config = ENGINE_CONFIGS.get(engine)
    if engine_config:
        return engine_config["default_model"]
    return None


def list_engines() -> list[dict[str, Any]]:
    """List all supported engines.

    Returns:
        List of engine configuration dicts

    Example:
        >>> engines = list_engines()
        >>> for engine in engines:
        ...     print(f"{engine['name']}: {engine['description']}")
    """
    return [
        {**config, "id": engine_id}
        for engine_id, config in ENGINE_CONFIGS.items()
    ]


#------------------------------------------------------------------------------
# Extension API (for custom configs)
#------------------------------------------------------------------------------

_CUSTOM_CONFIGS: dict[str, dict[str, Any]] = {}


def register_config(
    model_id: str,
    config: dict[str, Any],
    override: bool = False,
) -> bool:
    """Register a custom model configuration.

    Args:
        model_id: Unique identifier for the model
        config: Configuration dict with required fields
        override: Allow overriding existing configs

    Returns:
        True if registered, False if already exists and override=False

    Example:
        >>> register_config("my-local-model", {
        ...     "engine": "ollama",
        ...     "model": "my-model:latest",
        ...     "cost": "free",
        ...     "speed": "fast",
        ...     "quality": "good",
        ...     "best_for": ["coding"],
        ... })
    """
    if model_id in MODEL_CONFIGS and not override:
        return False
    if model_id in _CUSTOM_CONFIGS and not override:
        return False

    _CUSTOM_CONFIGS[model_id] = config
    return True


def list_custom_configs() -> list[dict[str, Any]]:
    """List all custom registered configurations.

    Returns:
        List of custom model configuration dicts
    """
    return [
        {**config, "id": model_id}
        for model_id, config in _CUSTOM_CONFIGS.items()
    ]
