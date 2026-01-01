# Changelog

## [1.0.0] - 2026-01-01
### Added
- Standardized Enterprise Repository Layout.
- Modular AI implementation (OpenAI/Claude supported).
- Multi-subdomain Nginx Proxy templates (`mail`, `office`, `ai`, `api`).
- Automated Dev/Prod deployment scripts with log-history branch support.
- GitHub Actions CI/CD with healthcheck and rollback.
- Comprehensive documentation: `setup.md`, `architecture.md`, `troubleshooting.md`.

### Changed
- Migrated from simple flat structure to modular structure (`ai/`, `office/`, `mailcow/`, `infrastructure/`, `deploy/`).
- Enhanced logging in Dev Mode.
