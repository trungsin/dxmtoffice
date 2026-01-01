# ✅ DXMT Office - Mail + Office + AI (Self-Hosted)

Hệ thống văn phòng tự host tương đương Outlook + Google Workspace, được thiết kế để vận hành ổn định, bảo mật và tích hợp AI mạnh mẽ.

## 🎯 Mục tiêu hệ thống
- **Email Server**: Mailcow (Postfix, Dovecot, SOGo).
- **Office**: Nextcloud + OnlyOffice (Real-time collaboration).
- **Proxy**: Nginx Proxy Manager (SSL Let's Encrypt).
- **AI**: Phase 1 (OpenAI/Claude API) integration.

## 🌐 Domains
- `feelmagic.store` - Proxy Manager Admin
- `mail.feelmagic.store` - Webmail & Mail Admin
- `office.feelmagic.store` - Nextcloud Office
- `ai.feelmagic.store` - AI Services

## 🚀 Lộ trình triển khai

### 1️⃣ Chuẩn bị (Dev Mode)
Sử dụng Dev Mode để kiểm tra trên VPS test trước khi release.

```bash
# Clone repository
git clone https://github.com/trungsin/dxmtoffice
cd dxmtoffice

# Copy env
cp .env.example .env.dev

# Chạy deploy dev
./deployment/scripts/dev-deploy.sh
```

### 2️⃣ Vận hành (Production Mode)
Sau khi test OK, chuyển sang Production Mode để tối ưu hiệu suất và bảo mật.

```bash
# Cấu hình production
cp .env.example .env.prod
# (Sửa .env.prod: DEV_MODE=false, GIT_PUSH_LOG=false)

# Chạy deploy prod
./deployment/scripts/prod-deploy.sh
```

## 📂 Cấu trúc dự án
- `infrastructure/`: Chứa Docker Compose và config của từng service.
- `deployment/`: Chứa scripts vận hành và logs.
- `docs/`: Tài liệu chi tiết (Setup, Architecture, Troubleshooting).

## ♻️ Quy trình Loop Fix (Dev Mode)
Trong chế độ Dev, hệ thống tự động:
1. Ghi log chi tiết vào `deployment/logs/dev/`.
2. Đẩy log lên Git (`chore(log): dev deploy log ...`).
3. Lưu lỗi mới nhất vào `deployment/logs/ai-context/latest-error.md`.

## 🧪 CI/CD
Tích hợp GitHub Actions để:
- Tự động deploy khi push vào nhánh `main`.
- Tự động Rollback (`./deployment/scripts/rollback.sh`) nếu deploy thất bại.

## 🛠 Hỗ trợ
Xem chi tiết tại [docs/setup.md](docs/setup.md) và [docs/troubleshooting.md](docs/troubleshooting.md).
