# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - 2026-11-14

### Fixed
- `setup-claude-stack.sh`: on macOS, fall back to the direct jdtls download when Homebrew is missing or
  cannot install it (e.g. Intel Macs, where Homebrew no longer ships prebuilt packages).
- `setup-claude-stack.sh`: a failed jdtls install is now a warning, so the plugins are still installed.

### Changed
- README: documented that `claude plugin install --scope project` may reorder `.claude/settings.json`.

## [0.1.0] - 2026-11-14

### Added
- `templates/java-spring/.claude/settings.json`: plugins and permissions for Java/Spring Boot projects.
- `templates/node-react-next/.claude/settings.json`: plugins and permissions for Node/TypeScript/React/Next.js projects.
- `scripts/setup-claude-stack.sh`: setup for macOS, Linux and WSL2 (LSP binaries + plugins from the repo's settings.json).
- `scripts/setup-claude-stack-windows.ps1`: WSL2 bootstrap, or native Windows setup without LSP plugins.
- README in English and Portuguese, CONTRIBUTING, SECURITY policy and CI checks.
