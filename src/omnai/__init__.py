"""omnai - Universal AI model configurations and runner.

Provides comprehensive model configurations with practical metadata including
cost, speed, quality, and use-case recommendations.

Example:
    >>> from omnai import get_config, find_configs, validate_model
    >>>
    >>> # Get specific model config
    >>> config = get_config("claude-sonnet-4-20250514")
    >>> print(f"Cost: ${config['cost_per_mtok']['output']}/M tokens")
    >>>
    >>> # Find models by criteria
    >>> free_coding = find_configs(cost="free", best_for="coding")
    >>> for model in free_coding:
    ...     print(f"{model['full_name']}: {model['notes']}")
    >>>
    >>> # Validate model with helpful suggestions on error
    >>> try:
    ...     config = validate_model("minimax-m2")  # Typo
    ... except ValueError as e:
    ...     print(e)  # Shows suggestions: minimax-m2.1, minimax-m2-api, etc.
"""

from .configs import (
    # Query functions
    get_config,
    list_configs,
    find_configs,
    get_default_model,
    list_engines,

    # Validation functions
    find_similar_models,
    get_model_suggestions,
    validate_model,

    # Extension API
    register_config,
    list_custom_configs,

    # Configuration dicts
    ENGINE_CONFIGS,
    MODEL_CONFIGS,
)

__version__ = "1.0.0-rc3"

__all__ = [
    # Query functions
    "get_config",
    "list_configs",
    "find_configs",
    "get_default_model",
    "list_engines",

    # Validation functions
    "find_similar_models",
    "get_model_suggestions",
    "validate_model",

    # Extension API
    "register_config",
    "list_custom_configs",

    # Configuration dicts
    "ENGINE_CONFIGS",
    "MODEL_CONFIGS",
]
