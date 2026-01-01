# ✅ DXMT Office - Ubuntu VPS + Gemini AI

Hệ thống văn phòng tự host (Mail, Office, AI) được tối ưu hóa cho Ubuntu 20.04/22.04 và tích hợp Google Gemini AI.

## 🚀 Triển khai nhanh trên Ubuntu

### 1. Chuẩn bị VPS
- Thuê VPS Ubuntu (Khuyên dùng: 2 vCPU, 4GB RAM).
- Trỏ các domain sau về IP VPS:
  - `feelmagic.store`
  - `mail.feelmagic.store`
  - `office.feelmagic.store`
  - `ai.feelmagic.store`
  - `api.feelmagic.store`

### 2. Cài đặt (One-liner)
```bash
git clone https://github.com/trungsin/dxmtoffice
cd dxmtoffice
chmod +x deploy/ubuntu/*.sh
./deploy/ubuntu/install_dependencies.sh
./deploy/ubuntu/setup_server.sh
```

### 3. Cấu hình
Copy `.env.example` thành `.env.prod` và nhập:
- `GEMINI_API_KEY`: Lấy tại [Google AI Studio](https://aistudio.google.com/).
- Cập nhật các domain tương ứng.

### 4. Deploy
```bash
./deploy/ubuntu/setup_domain.sh  # Cấu hình SSL
./deploy/scripts/deploy_prod.sh # Khởi chạy hệ thống
```

## 🤖 Tính năng AI (Gemini)
Hệ thống sử dụng Gemini 1.5/2.0 để hỗ trợ:
- **Smart Writing**: Gợi ý soạn thảo văn bản và email chuyên nghiệp.
- **Reporting**: Tạo báo cáo tự động từ dữ liệu văn bản.
- **AI Assistant**: Trợ lý giải đáp và xử lý tác vụ tại `ai.feelmagic.store`.

## 📂 Quản lý & Bảo trì
- **Xem log**: `./deploy/ubuntu/status.sh` hoặc `./deploy/scripts/view_logs.sh prod`
- **Backup**: Công cụ backup tích hợp trong Mailcow và Nextcloud.
- **Troubleshooting**: Xem chi tiết tại `docs/troubleshooting.md`.

## 🔒 Bảo mật
- Tự động cấu hình UFW (Firewall).
- Tự động gia hạn SSL qua Certbot.
- Mode Dev/Prod tách biệt hoàn toàn.
