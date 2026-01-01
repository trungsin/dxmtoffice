# DXMT Office (Self-Hosted Office Suite)

A complete, self-hosted replacement for Outlook + Google Workspace, featuring Email, File Sharing, and AI integration.

## 🚀 Quick Start

### 1. Prerequisites
- Ubuntu 22.04+
- Docker & Docker Compose
- Domain names pointed to Server IP

### 2. Configuration
Copy `.env.example` to `.env.dev` or `.env.prod` and update the variables.

### 3. Deployment
**Development Mode:**
```bash
./deployment/scripts/dev-deploy.sh
```

**Production Mode:**
```bash
./deployment/scripts/prod-deploy.sh
```

## 📂 Repository Structure
- `infrastructure/`: Core service configurations (Mailcow, Nextcloud, NPM).
- `deployment/`: Deployment scripts, logs, and CI/CD workflows.
- `docs/`: System architecture, setup, and troubleshooting guides.
- `docker-compose.yml`: Root compose file for production.
- `docker-compose.dev.yml`: Root compose file for development.

## 🤖 AI Integration
Phase 1 (API-based) is ready for configuration in Nextcloud. Update your `.env` with API keys.

## 🧪 CI/CD
Automated deployment is handled via GitHub Actions in `.github/workflows/cd.yml`.
