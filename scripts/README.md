# L1 IT Support Automation & Diagnostic Scripts

This directory contains battle-tested, non-destructive scripts used during enterprise Tier 1 troubleshooting on Windows 11.

---

## 🛠️ Script Catalog

### 1. `triage-system-health.ps1` (PowerShell)
- **Role:** Comprehensive baseline system health triage.
- **Execution:** `powershell -ExecutionPolicy Bypass -File .\triage-system-health.ps1`
- **Output:** System hostname, OS build, system uptime, physical RAM usage, CPU core breakdown, C: drive free storage, top 5 processes by processor time, and NVMe/SSD physical health status.

### 2. `reset-print-spooler.bat` (Batch / Admin)
- **Role:** Emergency printer queue un-jammer.
- **Execution:** Right-click -> *Run as administrator*.
- **Mechanism:** Gracefully terminates `spoolsv.exe`, deletes locked `.SPL` and `.SHD` spool files in `%systemroot%\System32\Spool\Printers\`, and restarts the Spooler service.

### 3. `reset-windows-update-cache.bat` (Batch / Admin)
- **Role:** Resolves Windows Update errors `0x80070002`, `0x80240034`, and infinite download/rollback loops.
- **Mechanism:** Stops `wuauserv`, `cryptSvc`, and `bits`, safely renames `SoftwareDistribution` and `catroot2`, and brings services back online to regenerate a clean update database.

### 4. `cleanup-disk-space.bat` (Batch / Admin)
- **Role:** Immediate emergency remediation when C: drive drops below 1 GB.
- **Mechanism:** Purges orphaned temporary files from `C:\Windows\Temp`, user `%TEMP%`, and Windows Error Reporting queues.
