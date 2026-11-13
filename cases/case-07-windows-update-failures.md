# Case Incident Report: INC-10734 - Windows Update and Installation Failures

**Ticket ID:** INC-10734  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P3 - Medium (Compliance vulnerability; machine non-compliant with corporate patch baseline)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Microsoft Surface Laptop 5 - Windows 11 Enterprise  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"My laptop keeps popping up a notification saying 'Your device is missing important security and quality updates'. Every night it tries to install the 2026-10 Cumulative Update (KB5031354). It downloads to 100%, restarts, reaches 30%, and then says: 'Something didn't go as planned. No need to worry—undoing changes.' It rolls back, wastes 45 minutes, and throws Error code 0x80070002 or 0x800f0922 in Settings. Our cybersecurity team just sent me an alert that my machine will be quarantined if not patched by Friday!"*
- **User:** James Holloway (Operations Manager)  
- **Department:** Supply Chain Operations  
- **Reported Impact:** Daily update crash loops; risk of automated network quarantine due to non-compliance.

---

## 2. Technical Causes & Underlying Mechanics
1. **Corrupted SoftwareDistribution / Catroot2 Cache:**
   When an update payload downloads across an unstable network, partial archives can pass initial hash checks but fail during pre-stage verification. When Windows tries to unpack the missing file (`0x80070002` = `ERROR_FILE_NOT_FOUND`), the servicing agent aborts.
2. **Damaged Windows Component Store (`WinSxS`):**
   The Component-Based Servicing (CBS) engine relies on the hardlinked `WinSxS` directory. If system manifest files or `.mum` records are corrupted or missing, updates fail with error `0x800f081f` (`CBS_E_SOURCE_NOT_FOUND`) or `0x800f0922`.
3. **Third-Party Antivirus / VPN Filter Interception:**
   Security agents locking files in `%windir%\System32\catroot2` while cryptographic signatures are being validated.

---

## 3. Diagnostic Investigation & Observations
- **Tools Utilized:**
  - Windows Settings -> **Windows Update** -> **Update history**.
  - `Windows Update Troubleshooter` (`ms-settings:troubleshoot`).
  - `CBS.log` (`C:\Windows\Logs\CBS\CBS.log`).
  - PowerShell (`Get-WindowsUpdateLog`, `DISM /Online /Cleanup-Image /ScanHealth`).

### Diagnostic Step 1: Checking Update History and Error Codes
Navigated to **Settings** -> **Windows Update** -> **Update history**.  
*Observation:* Cumulative Update `KB5031354` has failed 6 consecutive times with error code:
```text
Install error - 0x80070002 (ERROR_FILE_NOT_FOUND)
```

### Diagnostic Step 2: Component Store Health Check via DISM
Executed read-only DISM scan in elevated PowerShell:
```powershell
DISM /Online /Cleanup-Image /ScanHealth
```

**Observed Output:**
```text
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.2428

[==========================100.0%==========================]
The component store is repairable.
The operation completed successfully.
```
*Key Finding:* Component store corruption detected; repairable via online Windows Update manifests.

---

## 4. Root Cause Analysis (RCA)
- **Primary Root Cause:** A corrupted update download archive stored inside `C:\Windows\SoftwareDistribution` combined with missing manifest pointers in the Windows Component Store caused the servicing engine to throw `0x80070002` during the rollback phase.

---

## 5. Remediation Plan & Action Taken
1. **Stopped All Dependent Windows Update Services:**
   Executed elevated command sequence to halt servicing daemons:
   ```cmd
   net stop wuauserv
   net stop cryptSvc
   net stop bits
   net stop msiserver
   ```
2. **Flushed & Rebuilt Update and Cryptographic Repositories:**
   Renamed the existing caches so Windows generates fresh, uncorrupted databases upon service restart:
   ```cmd
   ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
   ren C:\Windows\System32\catroot2 catroot2.old
   ```
3. **Restarted Services:**
   ```cmd
   net start wuauserv
   net start cryptSvc
   net start bits
   net start msiserver
   ```
4. **Repaired Component Store & System Integrity:**
   Repaired the underlying servicing store using clean cloud-hosted binaries from Microsoft servers:
   ```cmd
   DISM /Online /Cleanup-Image /RestoreHealth
   sfc /scannow
   ```
   *Result:* DISM reported: *"The restore operation completed successfully."* SFC reported: *"Windows Resource Protection found corrupt files and successfully repaired them."*
5. **Manual Update Trigger:**
   Manually invoked Windows Update discovery via PowerShell:
   ```powershell
   UsoClient.exe StartScan
   UsoClient.exe StartDownload
   UsoClient.exe StartInstall
   ```
6. **Escalation Boundary:**
   - *L1 Fix:* SoftwareDistribution / Catroot2 rename, DISM /RestoreHealth, SFC, manual standalone MSU installer via Microsoft Update Catalog.
   - *Escalate to L2 / Endpoint Management:* WSUS / SCCM / Intune policy misconfiguration preventing ring deployments; BitLocker TPM PCR lock; complete In-Place Upgrade required.

---

## 6. Verification & Preventive Measures
- **Installation Verification:** Windows successfully downloaded `KB5031354`, installed without stalling, prompted for reboot, and reached 100% completion in 6 minutes without rolling back.
- **Compliance Status:** Settings -> Windows Update now displays: *"You're up to date (Last checked: Today)"*.
- **Endpoint Protection:** Confirmed with Security Operations that James's Surface is marked compliant in Microsoft Intune / Defender portal.

---

## 7. Customer Communication (Closing Ticket Note)
> *"Hi James, good news! We have resolved the update failure on your Surface Laptop. We found that an older download file had become damaged in the system cache, which was causing Windows to safely roll back the installation each night.
>
> We cleared out the corrupted cache, repaired your system's core update files, and successfully applied the latest security patch (KB5031354). Your laptop is now 100% up to date and fully compliant with company security requirements. You won't face any network quarantine on Friday. Thank you for your patience!"*
