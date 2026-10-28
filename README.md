# 🏛️ Secure Smart Queue Management System (SQMS)
### Production-Grade Government Public Service Portal

A complete, production-ready, secure queue and appointment management web application engineered for municipal and district government offices (e.g. Tehsildar & Collectorate offices).

Built with **React 18/19**, **Vite**, **Node.js 24**, native **SQLite (WAL mode)**, **HMAC-SHA256 Cryptographic Two-Stage QR verification**, and **SHA-256 Tamper-Evident Audit Logging**.

---

## 💻 How to Open in Your IDE (VS Code / Cursor / WebStorm)

This entire application is located in one folder:
```
c:\Users\ATHARVE\Documents\Project
```

### Steps to Open:
1. Open your IDE (e.g., **VS Code**, **Cursor**, **WebStorm**).
2. Click **File** ➔ **Open Folder...** (or press `Ctrl + K, Ctrl + O` on Windows).
3. Navigate to and select:
   ```
   c:\Users\ATHARVE\Documents\Project
   ```
4. Click **Select Folder**.

---

## ⚡ Quick Start: Running the System

Open a terminal in your IDE (`Ctrl + ~` in VS Code) and run:

### 1. Start the Backend API Server (Port 4000)
```bash
npm run dev:server
```
*Health Check*: `http://localhost:4000/api/health`

### 2. Start the Frontend Development Server (Port 5173)
In a second terminal tab:
```bash
npm run dev
```
*Frontend URL*: `http://localhost:5173`

---

## 🧪 Automated Testing & Maintenance Scripts

All scripts can be executed directly from the root project folder:

```bash
# Run the 32-test automated backend test suite
npm run test:server

# Run online database backup with WAL checkpoint & SHA-256 hash
npm run backup

# Run database restore with checksum verification
npm run restore

# Compile production frontend assets into /dist
npm run build

# Generate production build & package clean distribution zip
npm run generate

# Create clean distribution zip (excluding node_modules)
npm run package
```

---

## 🔑 Default Seed Accounts & Roles

The persistent database comes pre-seeded with 3 authorized roles:

| Role | Login Identifier | Password | Assigned Counter / Permissions |
| :--- | :--- | :--- | :--- |
| **Citizen** | `9876543210` | `demo123` | Appointment booking, token tracking, uploads, grievances |
| **Officer** | `priya.sharma@gov.in` | `officer@123` | Counter 3 (Income Certificate), QR verification, turn calls |
| **Admin** | `admin.sqms@gov.in` | `admin@123` | Analytics, audit chain verification, security alerts, configs |

---

## 📁 Project Architecture & File Tree

```
Project/
├── .env                      # Active environment configuration
├── .env.example              # Environment configuration template
├── DEPLOYMENT.md             # Production deployment & Nginx runbook
├── DISASTER_RECOVERY.md      # DRP, RPO/RTO & restoration runbook
├── package.json              # Root project dependencies & scripts
├── vite.config.js            # Vite build configuration with /api reverse proxy
│
├── public/                   # Static browser assets & icons
│
├── src/                      # Frontend Application (React SPA)
│   ├── assets/               # Local icons & media
│   ├── components/           # Reusable UI components (Modals, Badges, Header, Footer)
│   ├── context/
│   │   └── AppContext.jsx    # Live state provider, real API integration, turn alerts
│   ├── pages/
│   │   ├── AdminDashboard.jsx       # Analytics, security alerts & cryptographic audit check
│   │   ├── ApplicationStatus.jsx    # Multi-step application lifecycle
│   │   ├── Booking.jsx              # Slot booking with capacity & holiday checks
│   │   ├── CheckIn.jsx              # Entrance Kiosk Stage 1 QR check-in
│   │   ├── CounterRouting.jsx       # Active counter fleet routing
│   │   ├── DocumentVerification.jsx # Officer document verification workspace
│   │   ├── Grievance.jsx            # Citizen grievance submission & resolution
│   │   ├── Home.jsx                 # Public landing page
│   │   ├── Login.jsx                # Secure login with brute-force lockout
│   │   ├── MyDocuments.jsx          # File manager with magic byte validation
│   │   ├── MyToken.jsx              # Cryptographic QR token pass & turn reminders
│   │   ├── OfficerDashboard.jsx     # Stage 2 Counter Verification & queue calls
│   │   ├── Queue.jsx                # Live Public Display Board (PDB)
│   │   ├── Services.jsx             # Official government services catalog
│   │   └── UrgentRequest.jsx        # Tatkal emergency queue escalation
│   ├── utils/
│   │   ├── api.js                   # Unified async REST client for backend endpoints
│   │   └── helpers.js               # Formatting utilities
│   ├── App.jsx                      # App router & layout shell
│   ├── index.css                    # Tailwind CSS & custom design system
│   └── main.jsx                     # Vite entry point
│
└── server/                   # Backend API (Node.js 24 + Express + SQLite WAL)
    ├── .env                  # Backend active environment file
    ├── .env.example          # Backend environment template
    ├── package.json          # Server dependencies & test scripts
    ├── data/
    │   └── sqms.db           # Persistent SQLite database in WAL mode
    ├── backups/              # Automated database backups with SHA-256 metadata
    ├── scripts/
    │   ├── backup.js         # WAL truncation & SHA-256 backup utility
    │   └── restore.js        # Safe database restore with checksum verification
    ├── src/
    │   ├── db.js             # Native node:sqlite DatabaseSync wrapper
    │   ├── schema.sql        # 23 normalized tables with foreign keys & indexes
    │   ├── seed.js           # Production seeder for services, offices, accounts
    │   ├── index.js          # Express app entry point with security headers
    │   ├── middleware/
    │   │   └── auth.js       # JWT signing/verification, RBAC & rate limiting
    │   ├── utils/
    │   │   ├── auditLogger.js # SHA-256 chained tamper-evident audit ledger
    │   │   └── qrCrypto.js    # HMAC-SHA256 QR signature generation & verification
    │   ├── uploads/          # Secure private document uploads storage
    │   └── routes/
    │       ├── admin.js        # Stats, audit chain verification, security alerts
    │       ├── applications.js # Application lifecycle state machine
    │       ├── auth.js         # Register, login, profile & brute-force protection
    │       ├── booking.js      # Slot capacity, weekend & holiday enforcement
    │       ├── chatbot.js      # Bilingual English & Marathi FAQ assistant
    │       ├── documents.js    # File uploads with magic byte validation
    │       ├── grievance.js    # Citizen grievance submission & redressal
    │       ├── notifications.js# Turn reminders (30m & 15m) & in-app alerts
    │       ├── queue.js        # Two-stage QR check-in, call next, wait times
    │       ├── services.js     # Configurable government services catalog
    │       └── urgent.js       # Tatkal emergency requests & sign-offs
    └── test/
        └── sqms.test.js      # 32 automated tests covering all modules
```

---

## 🏛️ Security & Production Features

- **Two-Stage QR Security Gate**: Entrance Kiosk scans Stage 1; Stage 2 counter serving strictly requires verified Stage 1 arrival.
- **Tamper-Evident SHA-256 Audit Trail**: Hash chained audit ledger verifiable in real-time on Admin Dashboard.
- **Magic-Byte Document Security**: Deep binary inspection for PDF, JPEG, and PNG.
- **Bilingual Interface**: Full bilingual support in English and Marathi (`मराठी`).
