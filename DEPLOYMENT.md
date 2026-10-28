# Secure Smart Queue Management System (SQMS)
## Production Deployment & Operational Runbook

This guide covers the deployment, configuration, security hardening, and operational management of the **Secure Smart Queue Management System (SQMS)** in government office environments.

---

### Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Server & System Requirements](#2-server--system-requirements)
3. [Step-by-Step Installation](#3-step-by-step-installation)
4. [Environment Configuration](#4-environment-configuration)
5. [Process Management (systemd / PM2)](#5-process-management-systemd--pm2)
6. [Reverse Proxy & SSL/TLS Configuration (Nginx)](#6-reverse-proxy--ssltls-configuration-nginx)
7. [Automated Backups & Maintenance Crons](#7-automated-backups--maintenance-crons)
8. [External Integrations (Gov SMS / NIC Gateway)](#8-external-integrations-gov-sms--nic-gateway)
9. [Pre-Flight Security Checklist](#9-pre-flight-security-checklist)

---

### 1. Architecture Overview

SQMS is built with a decoupled, high-performance, resilient architecture:
- **Frontend SPA**: React 18, Vite, Tailwind CSS, Lucide icons. Static assets compiled to `/dist` and served via Nginx or CDN.
- **Backend API**: Node.js 24 (ESM), Express 4, native `node:sqlite` with write-ahead logging (WAL), HMAC-SHA256 cryptographic signatures, and JWT (RFC 7519) authentication.
- **Data Persistence**: Single-file persistent SQLite database (`server/data/sqms.db`) with full ACID compliance, foreign key constraints, and tamper-evident SHA-256 audit chaining.
- **Verification Gates**: Two-stage physical arrival verification (Entrance Kiosk HMAC QR scan) + Counter Service verification.

```
+--------------------+        HTTPS        +---------------------+
| Citizen / Kiosk /  | ------------------> |   Nginx Web Server  |
| Officer Browser UI |                     |   (SSL Termination) |
+--------------------+                     +----------+----------+
                                                      |
                                    +-----------------+-----------------+
                                    |                                   |
                             /api requests                       Static UI files
                                    v                                   v
                         +---------------------+              +--------------------+
                         | Node.js 24 API      |              | /dist (React App)  |
                         | (Express on :4000)  |              +--------------------+
                         +----------+----------+
                                    |
                         +----------+----------+
                         | SQLite (WAL Mode)   |
                         | server/data/sqms.db |
                         +---------------------+
```

---

### 2. Server & System Requirements

- **Operating System**: Linux (Ubuntu 22.04 LTS / Debian 12 / RHEL 9) or Windows Server 2022.
- **Runtime**: Node.js `>= 24.0.0` (LTS recommended) and `npm >= 10.0.0`.
- **Memory**: Minimum 2 GB RAM (4 GB recommended for busy municipal offices).
- **Disk Space**: Minimum 20 GB SSD storage (accommodates SQLite DB, daily backups, and document uploads).
- **Network**: Static IP address, Port 80 (HTTP redirect) and Port 443 (HTTPS) open.

---

### 3. Step-by-Step Installation

#### 3.1. Clone and Install Dependencies
```bash
# Clone the repository
git clone <repository-url> /opt/sqms
cd /opt/sqms

# Install root dependencies
npm install

# Install backend dependencies
cd /opt/sqms/server
npm install
```

#### 3.2. Build Frontend Assets
```bash
cd /opt/sqms
npm run build
# Compiled files will be created in /opt/sqms/dist
```

#### 3.3. Verify Native Database & Run Initial Seed
The server automatically initializes `server/data/sqms.db` with migrations and default office seed data on first boot. You can also run it manually:
```bash
cd /opt/sqms/server
node src/seed.js
```

---

### 4. Environment Configuration

Create production environment files from the provided templates:
```bash
cd /opt/sqms/server
cp .env.example .env
```

Generate secure, unguessable cryptographic keys for production:
```bash
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"
node -e "console.log('QR_HMAC_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"
```

Configure `.env`:
```ini
NODE_ENV=production
PORT=4000
DB_PATH=/opt/sqms/server/data/sqms.db

JWT_SECRET=<your-generated-jwt-secret>
QR_HMAC_SECRET=<your-generated-qr-secret>
JWT_EXPIRES_IN=8h

CORS_ORIGIN=https://sqms.pune.gov.in

TURN_REMINDER_WINDOW_1_MINS=30
TURN_REMINDER_WINDOW_2_MINS=15

# SMS Gateway Integration
SMS_DELIVERY_ENABLED=false
SMS_GATEWAY_PROVIDER=GOV_SMS_NIC_GATEWAY_STAGING
SMS_API_ENDPOINT=https://mgov.gov.in/api/v2/sms/send
SMS_API_KEY=
SMS_SENDER_ID=GOVSQM

MAX_UPLOAD_FILE_SIZE_MB=5
ALLOWED_DOCUMENT_MIMES=application/pdf,image/jpeg,image/png
UPLOAD_STORAGE_PATH=/opt/sqms/server/src/uploads
```

---

### 5. Process Management (systemd / PM2)

#### Option A: systemd Service (Recommended for Linux Server)
Create `/etc/systemd/system/sqms-backend.service`:
```ini
[Unit]
Description=Secure Smart Queue Management System API Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/sqms/server
ExecStart=/usr/bin/node src/index.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
EnvironmentFile=/opt/sqms/server/.env
StandardOutput=journal
StandardError=journal
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable sqms-backend
sudo systemctl start sqms-backend
sudo systemctl status sqms-backend
```

#### Option B: PM2 Process Manager
```bash
npm install -g pm2
cd /opt/sqms/server
pm2 start src/index.js --name "sqms-backend" -i 1 --max-memory-restart 500M
pm2 save
pm2 startup
```

---

### 6. Reverse Proxy & SSL/TLS Configuration (Nginx)

Install Nginx and Certbot:
```bash
sudo apt update && sudo apt install nginx certbot python3-certbot-nginx -y
```

Create `/etc/nginx/sites-available/sqms.conf`:
```nginx
server {
    listen 80;
    server_name sqms.pune.gov.in;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name sqms.pune.gov.in;

    ssl_certificate /etc/letsencrypt/live/sqms.pune.gov.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sqms.pune.gov.in/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self';" always;

    # Frontend Static Files
    root /opt/sqms/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API Reverse Proxy to Node Backend
    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Upload limits
        client_max_body_size 10M;
    }
}
```

Enable site configuration:
```bash
sudo ln -s /etc/nginx/sites-available/sqms.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### 7. Automated Backups & Maintenance Crons

SQMS includes an integrated backup utility with WAL truncation and SHA-256 integrity verification (`server/scripts/backup.js`).

Set up a daily automated cron task for midnight backups:
```bash
# Open crontab for www-data or root
crontab -e
```

Add the following entries:
```cron
# Daily backup at midnight with SHA-256 integrity verification
0 0 * * * cd /opt/sqms/server && /usr/bin/node scripts/backup.js >> /var/log/sqms_backup.log 2>&1

# Prune backups older than 30 days
0 1 * * * find /opt/sqms/server/backups/ -type f -mtime +30 -delete
```

To test backup manually:
```bash
cd /opt/sqms/server
npm run backup
```

To test restore manually:
```bash
cd /opt/sqms/server
npm run restore
```

---

### 8. External Integrations (Gov SMS / NIC Gateway)

By default, SQMS operates with `SMS_DELIVERY_ENABLED=false` to prevent silent delivery failures. SMS messages are staged in the `sms_inbox` table and user notifications table.

When moving to physical government office production:
1. Register with the **National Informatics Centre (NIC) SMS Gateway** or authorized telecom provider (DLT registration mandatory per TRAI regulations).
2. Obtain Sender ID (e.g. `MHGOVT`, `PUNADM`) and API Token.
3. Update `.env`:
   ```ini
   SMS_DELIVERY_ENABLED=true
   SMS_GATEWAY_PROVIDER=NIC_SMS_GATEWAY_PRODUCTION
   SMS_API_ENDPOINT=https://api.gov.in/sms/v1/transmit
   SMS_API_KEY=<official-nic-api-key>
   SMS_SENDER_ID=PUNADM
   ```
4. Verify turn reminder alerts (30-minute advance alert and 15-minute gate alert) with a test mobile number.

---

### 9. Pre-Flight Security Checklist

Before taking the system live:

- [ ] **Default Passwords Changed**: Update passwords for `CIT-101`, `OFF-402`, and `ADM-101` in the database.
- [ ] **Secret Keys Replaced**: Verify that `JWT_SECRET` and `QR_HMAC_SECRET` in `.env` are cryptographically random 256-bit hex strings.
- [ ] **HTTPS Enforced**: Confirm HTTP port 80 redirects to HTTPS 443 with valid SSL certificate.
- [ ] **CORS Restricted**: Ensure `CORS_ORIGIN` matches the exact public domain of the application.
- [ ] **Two-Stage QR Verified**: Verify that Entrance Kiosk scans Stage 1 and Counter officers require Stage 1 verification before serving.
- [ ] **Audit Trail Validated**: Confirm `GET /api/admin/audit-logs/verify` returns `valid: true`.
- [ ] **Automated Test Run**: Run `npm test` inside `/opt/sqms/server` and ensure 100% test pass rate.
