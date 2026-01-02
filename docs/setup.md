# Setup Guide: DXMT Office

This guide explains how to deploy the self-hosted office suite.

## Prerequisites
- Ubuntu 22.04+ (or compatible Linux)
- Docker & Docker Compose
- Public IP with ports 80, 443, 25, 465, 587, 993 open.

## Deployment

### Dev Mode
```bash
./deploy/scripts/dev-deploy.sh
```

### Production Mode
```bash
./deploy/scripts/prod-deploy.sh
```

## Domains
The following domains must point to your server:
- `feelmagic.store`
- `mail.feelmagic.store`
- `office.feelmagic.store`
- `ai.feelmagic.store`
