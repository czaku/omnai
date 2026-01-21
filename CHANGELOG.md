# Changelog

All notable changes to ai-runner are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://sememver.org/spec/v2.0.0.html).

## [Unreleased] - v0.6.0

### Planned
- Aixam integration example
- Provider-specific error mapping improvements

## [v1.0.0-rc2] - January 2026

### Added
- Qwen-Code support (`qwen` engine)
- Cursor agent support (`cursor` engine)
- OpenAI Codex support (`codex` engine)
- Goose CLI support (`goose` engine)
- GitHub Copilot CLI support (`copilot` engine)
- Total of 9 supported AI backends

## [v1.0.0-rc1] - January 2026

### Added
- Structured JSON API (ai_get_engines, ai_get_models, ai_get_status, ai_get_config)
- Config file support (~/.ai-runner.conf)
- Error handling with provider-specific detection
- 75 passing tests
- ShellCheck validated

## [v0.5.0] - January 2026

### Added
- Provider-specific error detection (`ai_detect_error`)
- Error recovery suggestions (`ai_error_suggestion`)
- Error handling wrapper (`ai_handle_error`, `ai_run_with_error_handling`)
- Error type suggestions for all common error types

### Changed
- Updated version to v0.5.0
- Improved error messages with recovery suggestions

## [v0.4.0] - January 2026

### Added
- Progress callbacks (`AI_PROGRESS_CALLBACK`, `ai_set_progress_callback`)
- File context injection (`ai_run_with_files`, `ai_build_prompt_with_files`)

## [v0.3.0] - January 2026

### Added
- Retry logic with exponential backoff (`ai_run_with_retry`)
- JSON response validation (`ai_json_validated`, `ai_json_validated_schema`)

## [v0.2.0] - January 2026

### Added
- Working directory context (`AI_WORKING_DIR`, `ai_run_with_cwd`)
- Standardized exit codes (`AI_EXIT_SUCCESS`, `AI_EXIT_TIMEOUT`, etc.)
- Exit code name helper (`ai_exit_code_name`)

## [v0.1.0] - January 2026

### Added
- Multi-backend support: Claude CLI, OpenCode, Ollama, Aider
- Engine auto-detection (`ai_detect_engine`)
- Core functions: `ai_run`, `ai_run_file`, `ai_json`, `ai_build_prompt`
- CLI interface
- Verbose logging
- Timeout support

[Unreleased]: https://github.com/czaku/ai-runner/compare/v0.5.0...HEAD
[v0.5.0]: https://github.com/czaku/ai-runner/releases/tag/v0.5.0
[v0.4.0]: https://github.com/czaku/ai-runner/releases/tag/v0.4.0
[v0.3.0]: https://github.com/czaku/ai-runner/releases/tag/v0.3.0
[v0.2.0]: https://github.com/czaku/ai-runner/releases/tag/v0.2.0
[v0.1.0]: https://github.com/czaku/ai-runner/releases/tag/v0.1.0
