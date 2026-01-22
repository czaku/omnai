"""Tests for omnai.configs module."""

import pytest
from omnai import (
    get_config,
    list_configs,
    find_configs,
    get_default_model,
    list_engines,
    register_config,
    list_custom_configs,
    find_similar_models,
    validate_model,
    ENGINE_CONFIGS,
    MODEL_CONFIGS,
)


class TestGetConfig:
    """Test get_config function."""

    def test_get_existing_config(self):
        """Test getting an existing config."""
        config = get_config("claude-sonnet-4-20250514")
        assert config is not None
        assert config["engine"] == "claude"
        assert config["model"] == "claude-sonnet-4-20250514"
        assert config["cost"] == "medium"

    def test_get_nonexistent_config(self):
        """Test getting a config that doesn't exist."""
        config = get_config("nonexistent-model")
        assert config is None

    def test_config_has_required_fields(self):
        """Test that configs have all required metadata fields."""
        config = get_config("claude-sonnet-4-20250514")
        assert "cost" in config
        assert "speed" in config
        assert "quality" in config
        assert "best_for" in config
        assert "free_tier" in config
        assert "cost_per_mtok" in config


class TestListConfigs:
    """Test list_configs function."""

    def test_list_all_configs(self):
        """Test listing all configs."""
        configs = list_configs()
        assert len(configs) > 0
        assert all("id" in c for c in configs)

    def test_list_configs_by_engine(self):
        """Test listing configs filtered by engine."""
        ollama_configs = list_configs(engine="ollama")
        assert len(ollama_configs) > 0
        assert all(c["engine"] == "ollama" for c in ollama_configs)

    def test_list_configs_includes_id(self):
        """Test that listed configs include id field."""
        configs = list_configs()
        assert all("id" in c for c in configs)


class TestFindConfigs:
    """Test find_configs function."""

    def test_find_by_cost(self):
        """Test finding configs by cost."""
        free_models = find_configs(cost="free")
        assert len(free_models) > 0
        assert all(m["cost"] == "free" for m in free_models)

    def test_find_by_multiple_costs(self):
        """Test finding configs by multiple cost levels."""
        cheap_models = find_configs(cost=["free", "cheap"])
        assert len(cheap_models) > 0
        assert all(m["cost"] in ["free", "cheap"] for m in cheap_models)

    def test_find_by_speed(self):
        """Test finding configs by speed."""
        fast_models = find_configs(speed="fast")
        assert len(fast_models) > 0
        assert all(m["speed"] == "fast" for m in fast_models)

    def test_find_by_quality(self):
        """Test finding configs by quality."""
        excellent_models = find_configs(quality="excellent")
        assert len(excellent_models) > 0
        assert all(m["quality"] == "excellent" for m in excellent_models)

    def test_find_by_best_for(self):
        """Test finding configs by use case."""
        coding_models = find_configs(best_for="coding")
        assert len(coding_models) > 0
        assert all("coding" in m["best_for"] for m in coding_models)

    def test_find_by_multiple_best_for(self):
        """Test finding configs by multiple use cases."""
        models = find_configs(best_for=["coding", "research"])
        assert len(models) > 0
        # Should match models that have ANY of the specified use cases
        assert all(
            any(use in m["best_for"] for use in ["coding", "research"])
            for m in models
        )

    def test_find_by_free_tier(self):
        """Test finding configs by free tier availability."""
        free_tier_models = find_configs(free_tier=True)
        assert len(free_tier_models) > 0
        assert all(m["free_tier"] is True for m in free_tier_models)

    def test_find_by_engine(self):
        """Test finding configs by engine."""
        ollama_models = find_configs(engine="ollama")
        assert len(ollama_models) > 0
        assert all(m["engine"] == "ollama" for m in ollama_models)

    def test_find_by_multiple_engines(self):
        """Test finding configs by multiple engines."""
        models = find_configs(engine=["claude-code", "claude"])
        assert len(models) > 0
        assert all(m["engine"] in ["claude-code", "claude"] for m in models)

    def test_find_by_multiple_criteria(self):
        """Test finding configs by multiple criteria."""
        models = find_configs(
            cost="free",
            best_for="coding",
            quality=["excellent", "good"]
        )
        assert len(models) > 0
        assert all(m["cost"] == "free" for m in models)
        assert all("coding" in m["best_for"] for m in models)
        assert all(m["quality"] in ["excellent", "good"] for m in models)

    def test_find_no_matches(self):
        """Test finding with criteria that match nothing."""
        models = find_configs(cost="expensive", speed="very-fast")
        # Should return empty list, not error
        assert models == []


class TestGetDefaultModel:
    """Test get_default_model function."""

    def test_get_default_for_claude_code(self):
        """Test getting default model for claude-code engine."""
        default = get_default_model("claude-code")
        assert default == "claude-sonnet-4-20250514"

    def test_get_default_for_ollama(self):
        """Test getting default model for ollama engine."""
        default = get_default_model("ollama")
        assert default == "qwen2.5-coder:7b"

    def test_get_default_for_nonexistent_engine(self):
        """Test getting default for engine that doesn't exist."""
        default = get_default_model("nonexistent")
        assert default is None


class TestListEngines:
    """Test list_engines function."""

    def test_list_engines(self):
        """Test listing all engines."""
        engines = list_engines()
        assert len(engines) > 0
        assert all("id" in e for e in engines)
        assert all("name" in e for e in engines)

    def test_engines_have_required_fields(self):
        """Test that engines have required fields."""
        engines = list_engines()
        for engine in engines:
            assert "id" in engine
            assert "name" in engine
            assert "type" in engine
            assert "default_model" in engine


class TestRegisterConfig:
    """Test register_config function."""

    def test_register_new_config(self):
        """Test registering a new custom config."""
        success = register_config("test-model", {
            "engine": "ollama",
            "model": "test:latest",
            "cost": "free",
            "speed": "fast",
            "quality": "good",
            "best_for": ["testing"],
        })
        assert success is True

        # Verify it was registered
        custom_configs = list_custom_configs()
        assert any(c["id"] == "test-model" for c in custom_configs)

    def test_register_duplicate_without_override(self):
        """Test registering duplicate without override fails."""
        register_config("test-dup", {"engine": "ollama", "model": "test:1"})
        success = register_config("test-dup", {"engine": "ollama", "model": "test:2"})
        assert success is False

    def test_register_duplicate_with_override(self):
        """Test registering duplicate with override succeeds."""
        register_config("test-override", {"engine": "ollama", "model": "test:1"})
        success = register_config(
            "test-override",
            {"engine": "ollama", "model": "test:2"},
            override=True
        )
        assert success is True


class TestListCustomConfigs:
    """Test list_custom_configs function."""

    def test_list_custom_configs(self):
        """Test listing custom configs."""
        register_config("custom-1", {"engine": "ollama", "model": "c1"})
        register_config("custom-2", {"engine": "ollama", "model": "c2"})

        custom = list_custom_configs()
        assert len(custom) >= 2
        assert all("id" in c for c in custom)


class TestModelConfigs:
    """Test MODEL_CONFIGS structure."""

    def test_all_configs_have_required_fields(self):
        """Test that all configs have required fields."""
        required_fields = [
            "engine", "model", "full_name", "context_window",
            "cost", "speed", "quality", "best_for", "free_tier",
            "cost_per_mtok", "notes"
        ]

        for model_id, config in MODEL_CONFIGS.items():
            for field in required_fields:
                assert field in config, f"{model_id} missing {field}"

    def test_cost_valid_values(self):
        """Test that cost field has valid values."""
        valid_costs = ["free", "cheap", "medium", "expensive"]
        for model_id, config in MODEL_CONFIGS.items():
            assert config["cost"] in valid_costs, f"{model_id} has invalid cost"

    def test_speed_valid_values(self):
        """Test that speed field has valid values."""
        valid_speeds = ["very-fast", "fast", "medium", "slow", "very-slow"]
        for model_id, config in MODEL_CONFIGS.items():
            assert config["speed"] in valid_speeds, f"{model_id} has invalid speed"

    def test_quality_valid_values(self):
        """Test that quality field has valid values."""
        valid_qualities = ["excellent", "good", "fair", "basic"]
        for model_id, config in MODEL_CONFIGS.items():
            assert config["quality"] in valid_qualities, f"{model_id} has invalid quality"

    def test_cost_per_mtok_structure(self):
        """Test that cost_per_mtok has correct structure."""
        for model_id, config in MODEL_CONFIGS.items():
            cost = config["cost_per_mtok"]
            assert "input" in cost, f"{model_id} missing input cost"
            assert "output" in cost, f"{model_id} missing output cost"
            assert isinstance(cost["input"], (int, float))
            assert isinstance(cost["output"], (int, float))

    def test_best_for_is_list(self):
        """Test that best_for is a list."""
        for model_id, config in MODEL_CONFIGS.items():
            assert isinstance(config["best_for"], list), f"{model_id} best_for not list"
            assert len(config["best_for"]) > 0, f"{model_id} best_for is empty"


class TestEngineConfigs:
    """Test ENGINE_CONFIGS structure."""

    def test_all_engines_have_required_fields(self):
        """Test that all engines have required fields."""
        required_fields = ["name", "description", "type", "default_model"]

        for engine_id, config in ENGINE_CONFIGS.items():
            for field in required_fields:
                assert field in config, f"{engine_id} missing {field}"

    def test_default_models_exist(self):
        """Test that default models referenced by engines exist."""
        for engine_id, config in ENGINE_CONFIGS.items():
            default = config["default_model"]
            # Skip engines with no default model (configured externally)
            if default is None:
                continue
            # Find at least one model with this ID
            assert any(
                m_id == default for m_id in MODEL_CONFIGS.keys()
            ), f"Default model {default} for {engine_id} not found"


class TestFindSimilarModels:
    """Test find_similar_models function."""

    def test_find_similar_exact_prefix(self):
        """Test finding models with exact prefix match."""
        similar = find_similar_models("minimax")
        assert len(similar) > 0
        # Should find minimax-m2.1, minimax-m2-api, minimax-m2.1-api, minimax-m2.1-free
        assert all("minimax" in m["id"] for m in similar)

    def test_find_similar_with_engine_filter(self):
        """Test finding models filtered by engine."""
        similar = find_similar_models("minimax", engine="opencode")
        assert len(similar) > 0
        assert all(m["engine"] == "opencode" for m in similar)

    def test_find_similar_case_insensitive(self):
        """Test case-insensitive matching."""
        similar1 = find_similar_models("MINIMAX")
        similar2 = find_similar_models("minimax")
        assert len(similar1) == len(similar2)

    def test_find_similar_respects_limit(self):
        """Test that limit parameter works."""
        similar = find_similar_models("qwen", limit=2)
        assert len(similar) <= 2

    def test_find_similar_no_matches(self):
        """Test when no similar models found."""
        similar = find_similar_models("nonexistent-xyz-123")
        assert similar == []

    def test_find_similar_includes_metadata(self):
        """Test that results include required metadata."""
        similar = find_similar_models("claude")
        assert len(similar) > 0
        for model in similar:
            assert "id" in model
            assert "full_name" in model
            assert "engine" in model
            assert "cost" in model


class TestValidateModel:
    """Test validate_model function."""

    def test_validate_existing_model(self):
        """Test validating an existing model."""
        config = validate_model("claude-sonnet-4-20250514")
        assert config is not None
        assert config["engine"] == "claude"
        assert config["model"] == "claude-sonnet-4-20250514"

    def test_validate_with_engine_match(self):
        """Test validation with matching engine."""
        config = validate_model("claude-sonnet-4-20250514", engine="claude")
        assert config["engine"] == "claude"

    def test_validate_with_engine_mismatch(self):
        """Test validation fails with mismatched engine."""
        with pytest.raises(ValueError) as exc_info:
            validate_model("claude-sonnet-4-20250514", engine="ollama")
        assert "exists but is for engine" in str(exc_info.value)
        assert "claude" in str(exc_info.value)
        assert "not 'ollama'" in str(exc_info.value)

    def test_validate_nonexistent_with_suggestions(self):
        """Test validation failure shows suggestions for similar models."""
        with pytest.raises(ValueError) as exc_info:
            validate_model("minimax-m3")  # Doesn't exist but similar to minimax models
        error_msg = str(exc_info.value)
        assert "not found" in error_msg
        assert "Did you mean" in error_msg
        # Should suggest minimax-m2, minimax-m2.1, minimax-m2-api, etc.
        assert "minimax" in error_msg

    def test_validate_nonexistent_no_suggestions(self):
        """Test validation failure with no similar models."""
        with pytest.raises(ValueError) as exc_info:
            validate_model("completely-nonexistent-xyz-123")
        error_msg = str(exc_info.value)
        assert "not found" in error_msg
        assert "List available models" in error_msg

    def test_validate_nonexistent_with_engine_filter(self):
        """Test validation shows only engine-specific suggestions."""
        with pytest.raises(ValueError) as exc_info:
            validate_model("qwen", engine="ollama")
        error_msg = str(exc_info.value)
        assert "not found" in error_msg
        # Should suggest ollama models only
        if "Did you mean" in error_msg:
            assert "ollama" in error_msg

    def test_validate_returns_config_with_id(self):
        """Test that validate_model returns config with id field."""
        config = validate_model("gpt-4o")
        assert "id" in config
        assert config["id"] == "gpt-4o"

    def test_validate_custom_model(self):
        """Test validating a custom registered model."""
        # Register a custom model
        register_config("test-validate-custom", {
            "engine": "ollama",
            "model": "test:latest",
            "cost": "free",
        }, override=True)
        
        # Should validate successfully
        config = validate_model("test-validate-custom")
        assert config is not None
        assert config["engine"] == "ollama"
