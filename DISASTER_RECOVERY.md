# Secure Smart Queue Management System (SQMS)
## Disaster Recovery & Business Continuity Plan (DRP)

This document establishes the official disaster recovery and business continuity procedures for the **Secure Smart Queue Management System (SQMS)** in government office environments.

---

### 1. Recovery Objectives

| Metric | Target | Description |
| :--- | :--- | :--- |
| **RPO (Recovery Point Objective)** | **< 1 hour** | Maximum acceptable data loss in the event of an unrecoverable disaster. Achieved via hourly WAL archiving or daily full backups. |
| **RTO (Recovery Time Objective)** | **< 15 minutes** | Maximum allowable downtime from disaster declaration to restored service operations. |
| **Integrity Target** | **100% Zero-Loss Audit Chain** | All historical audit hashes prior to the backup timestamp must remain cryptographically verifiable. |

---

### 2. Backup Architecture & Retention

SQMS uses single-file SQLite database storage with Write-Ahead Logging (`WAL`).

- **Backup Mechanism**: `server/scripts/backup.js` checkpoints and truncates the WAL log (`PRAGMA wal_checkpoint(TRUNCATE)`), validates SQLite database integrity (`PRAGMA integrity_check`), creates a timestamped clone in `server/backups/`, and generates a SHA-256 metadata record (`.meta.json`).
- **Storage Location**:
  - Primary Local: `/opt/sqms/server/backups/`
  - Off-Site Secondary (Recommended): Government secure S3/Blob storage or off-site NAS via rsync.
- **Retention Schedule**:
  - Hourly snapshots: Retained for 48 hours.
  - Daily backups: Retained for 90 days.
  - Monthly archives: Retained for 7 years (mandated for public administration records).

---

### 3. Step-by-Step Restoration Runbook

#### Scenario A: Database Corruption or Data Error
When the SQLite database encounters corruption, disk faults, or accidental deletion:

1. **Stop Application Backend**:
   ```bash
   sudo systemctl stop sqms-backend
   # Or if using PM2:
   pm2 stop sqms-backend
   ```

2. **Run Automated Restore Script**:
   The automated restore script (`server/scripts/restore.js`) performs:
   - Automated detection of the latest valid backup.
   - Cryptographic SHA-256 verification against the metadata record.
   - Pre-restore snapshot preservation of the existing damaged file (to prevent further loss).
   - Database restoration and `PRAGMA integrity_check`.

   ```bash
   cd /opt/sqms/server
   npm run restore
   ```

   To restore a specific backup rather than the latest:
   ```bash
   node scripts/restore.js backups/sqms_backup_20261017_120050.db
   ```

3. **Verify Restored Database**:
   ```bash
   # Run quick verification check
   node -e "
     const { DatabaseSync } = require('node:sqlite');
     const db = new DatabaseSync('data/sqms.db');
     console.log('Integrity check:', db.prepare('PRAGMA integrity_check;').get());
     console.log('Token count:', db.prepare('SELECT COUNT(*) AS count FROM tokens;').get());
     db.close();
   "
   ```

4. **Restart Application Backend**:
   ```bash
   sudo systemctl start sqms-backend
   sudo systemctl status sqms-backend
   ```

5. **Verify Live Health Check**:
   ```bash
   curl -s http://127.0.0.1:4000/api/health | jq .
   ```

---

#### Scenario B: Tampered Audit Log or Suspected Security Breach
If the audit log integrity check (`GET /api/admin/audit-logs/verify`) fails with `valid: false`:

1. **Freeze System & Capture Forensic Snapshot**:
   ```bash
   sudo systemctl stop sqms-backend
   cp data/sqms.db data/sqms.db.forensic-tamper.$(date +%s)
   ```

2. **Identify Tampered Entry**:
   Query the database to identify which record hash fails verification:
   ```bash
   node -e "
     const { getDb } = await import('./src/db.js');
     const { verifyAuditTrail } = await import('./src/utils/auditLogger.js');
     const report = verifyAuditTrail();
     console.log('Audit Integrity Report:', report);
   "
   ```

3. **Analyze Security Event**:
   Inspect the `security_alerts` table:
   ```sql
   SELECT * FROM security_alerts WHERE alert_type = 'AUDIT_INTEGRITY_BREACH' ORDER BY id DESC;
   ```

4. **Remediate & Restore**:
   - If tampering is unauthorized, restore from the last known untampered backup.
   - Rotate all JWT and HMAC keys immediately in `.env`.
   - File official cyber incident report.

---

#### Scenario C: Total Hardware Failure / Server Migration

In the event of a destroyed or decommissioned server host:

1. **Provision New Host Server**:
   Install Node.js 24 and Nginx on the new host machine.

2. **Deploy Codebase**:
   ```bash
   git clone <repo-url> /opt/sqms
   cd /opt/sqms && npm install
   cd /opt/sqms/server && npm install
   cd /opt/sqms && npm run build
   ```

3. **Transfer Latest Backup & Metadata from Off-site Vault**:
   ```bash
   scp user@backup-vault:/vault/sqms_backup_latest.db /opt/sqms/server/backups/
   scp user@backup-vault:/vault/sqms_backup_latest.meta.json /opt/sqms/server/backups/
   ```

4. **Restore Database**:
   ```bash
   cd /opt/sqms/server
   npm run restore
   ```

5. **Apply Environment Secrets**:
   Restore `.env` configuration file with production secrets.

6. **Start Service**:
   ```bash
   sudo systemctl enable --now sqms-backend
   sudo systemctl restart nginx
   ```

---

### 4. Verification & Sign-Off Checklist After Recovery

After any disaster recovery operation, the duty administrator must verify:

- [ ] `/api/health` reports status `ok` and version `2.0.0-production`.
- [ ] Active counters are visible in the Live Queue dashboard.
- [ ] Entrance kiosk can scan and verify Stage 1 arrival tokens.
- [ ] Counter officers can log in, view assigned appointments, and serve tokens.
- [ ] Tamper-evident audit chain verification passes (`GET /api/admin/audit-logs/verify` -> `valid: true`).
- [ ] Citizen login and appointment history display correct historical bookings.
- [ ] Pre-restore forensic snapshot is archived securely for investigation.

---

### 5. Disaster Recovery Drill Schedule

To ensure operational preparedness:
- **Monthly**: Automated non-destructive backup validation and checksum audit.
- **Quarterly**: Dry-run database restoration on a staging server.
- **Annual**: Full simulated hardware failure and off-site restore drill.
