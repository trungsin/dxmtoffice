# DXMT Cloud - Detailed User Guide

Welcome to your self-hosted DXMT Cloud platform. This guide provides instructions on how to access and manage your services.

## 🚀 Service Access Overview

Your platform is organized into three main hubs, all accessible via the subdomains you configured in Nginx Proxy Manager.

| Service | Primary URL (Example) | Status |
| :--- | :--- | :--- |
| **Mail Management** | `https://mail.yourdomain.com` | ✅ UP (UI on 8080) |
| **Office Suite** | `https://office.yourdomain.com` | ✅ UP (Nextcloud on 8081) |
| **OnlyOffice** | Internal Integration | ✅ UP (on 8082) |
| **AI Assistant** | `https://ai.yourdomain.com` | ✅ UP (on 3000) |

---

## 📧 Mail Hub (Mailcow)

### 1. Admin Access
- **URL**: Go to your configured mail subdomain (e.g., `https://mail.feelmagic.store`).
- **Initial Login**: Use the default admin credentials (usually `admin` / `moohoo` or the password you set in `mailcow.conf`).
- **Action**: Change your admin password immediately upon first login.

### 2. Creating Mailboxes
1. Navigate to **Configuration** > **Mailboxes**.
2. Click **Add mailbox**.
3. Define the email address (e.g., `hello@yourdomain.com`) and set a strong password.

### 3. Sending and Receiving
- **Sending**: Fully functional. You can send mail via the Web UI or standard SMTP (Port 587 or 465).
- **Receiving (Known Issue)**: Currently, IMAP/POP3 (Ports 143, 993, 995) are reporting as DOWN.
    - **Workaround**: Use the Webmail interface directly on your mail subdomain for now.
    - **Fix**: See the Troubleshooting section below.

---

## 📂 Office Hub (Nextcloud + OnlyOffice)

### 1. Accessing Files
- **URL**: Go to your office subdomain (e.g., `https://office.feelmagic.store`).
- **Login**: Use the admin credentials set during deployment.

### 2. Document Editing (OnlyOffice)
- Clicking on any `.docx`, `.xlsx`, or `.pptx` file within Nextcloud will automatically open it in the **OnlyOffice editor**.
- Collaborative editing is enabled by default.

---

## 🤖 AI Assistant (Gemini)

- **URL**: Your AI subdomain (e.g., `https://ai.feelmagic.store`).
- **Features**: Smart writing, automated reporting, and general assistant tasks.
- **API Access**: The service runs on port 3000 and is proxied through Nginx.

---

## 🛠 Troubleshooting & Maintenance

### 1. Resolving IMAP (Port 993) DOWN
If the healthcheck shows IMAP as DOWN, it usually means Dovecot is waiting for SSL certificates or has a configuration conflict.

**Run this command on your VPS to fix/diagnose:**
```bash
# Check Dovecot logs for errors
docker logs mailcowdockerized-dovecot-mailcow-1 --tail 100

# Force-restart Dovecot
docker compose -f docker-compose.dev.yml restart dovecot-mailcow acme-mailcow
```

### 2. General Healthcheck
You can run the unified healthcheck at any time to monitor your services:
```bash
cd /root/dxmtoffice
./deploy/ubuntu/healthcheck.sh
```

### 3. Updating the System
To pull the latest stability fixes and update the containers:
```bash
git fetch origin main
git reset --hard origin/main
./deploy/ubuntu/deploy_dev.sh
```

---

## 🔒 Security Recommendations
- **Firewall**: UFW is automatically configured to allow only necessary ports.
- **SSL**: All traffic is encrypted via Let's Encrypt through Nginx Proxy Manager.
- **Backups**: Periodically back up the `mailcow/data` and `office/nextcloud_data` volumes.
