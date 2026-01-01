# Troubleshooting Guide

This guide covers common issues and their solutions for the DXMT Office system.

## 🏁 General Issues

### 502 Bad Gateway
- **Cause**: The backend service is down or still starting.
- **Fix**: Check `docker ps` to ensure containers are healthy. Wait 1-2 minutes for Mailcow/Nextcloud to finish initialization.

### Port Binding Failed
- **Cause**: Another process is using port 80, 443, or 25.
- **Fix**: Run `lsof -i :80` to find the process and stop it. For port 25, ensure your VPS provider hasn't blocked it.

## 📨 Email (Mailcow)

### Emails are not being received
- **Fix**: Check DKIM/SPF/DMARC settings in the Mailcow UI. Ensure MX records are correctly pointed.

### Can't login to Webmail
- **Fix**: Ensure `MAILCOW_HOSTNAME` in `mailcow.conf` matches your subdomain.

## 📂 Office (Nextcloud)

### OnlyOffice Document fails to load
- **Fix**: Check the `JWT_SECRET` in both Nextcloud settings and the OnlyOffice container environment. They must match.

## 🤖 AI

### AI Assistant not responding
- **Fix**: Verify your `AI_API_KEY` in the `.env` file and restart the service.
