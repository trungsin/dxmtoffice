# Architecture Overview

The system is designed as a modular suite of self-hosted services proxied through Nginx Proxy Manager.

## Components
- **Proxy**: Nginx Proxy Manager (Terminates SSL, routes traffic).
- **Email**: Mailcow (Postfix, Dovecot, SOGo, Rspamd).
- **Office**: Nextcloud (Files, Calendar, Contacts).
- **Document Editing**: OnlyOffice Document Server.
- **AI Integration**: Custom AI service/integration via APIs.

## Network Flow
1. User -> Port 443 -> NPM (terminates SSL)
2. NPM -> Infrastructure Docker Network -> Target Service
