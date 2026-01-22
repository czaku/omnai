"""omnai - Universal AI model configurations and runner.

Provides comprehensive model configurations with practical metadata including
cost, speed, quality, and use-case recommendations.

Example:
    >>> from omnai import get_config, find_configs
    >>>
    >>> # Get specific model config
    >>> config = get_config("sonnet-4.5")
    >>> print(f"Cost: ${config['cost_per_mtok']['output']}/M tokens")
    >>>
    >>> # Find models by criteria
    >>> free_coding = find_configs(cost="free", best_for="coding")
    >>> for model in free_coding:
    ...     print(f"{model['full_name']}: {model['notes']}")
"""

from .configs import (
    # Query functions
    get_config,
    list_configs,
    find_configs,
    get_default_model,
    list_engines,

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

    # Extension API
    "register_config",
    "list_custom_configs",

    # Configuration dicts
    "ENGINE_CONFIGS",
    "MODEL_CONFIGS",
]
