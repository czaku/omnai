# Changelog

All notable changes to omni-ai are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://sememver.org/spec/v2.0.0.html).

## [Unreleased] -

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
- Config file support (~/.omni-ai.conf)
- Error handling with provider-specific detection
- 75 passing tests
- ShellCheck validated

---

**Note:** Earlier versions (v0.1.0 - v0.5.0) have been removed as they contained breaking changes and are no longer maintained. Please use v1.0.0-rc1 or later.

[Unreleased]: https://github.com/czaku/omni-ai/compare/v1.0.0-rc2...HEAD
[v1.0.0-rc2]: https://github.com/czaku/omni-ai/releases/tag/v1.0.0-rc2
[v1.0.0-rc1]: https://github.com/czaku/omni-ai/releases/tag/v1.0.0-rc1
