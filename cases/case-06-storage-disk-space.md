# Case Incident Report: INC-10671 - Storage and Disk-Space Problems

**Ticket ID:** INC-10671  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P2 - High (C: drive critically full, OS instability imminent)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Windows 11 Enterprise - HP ZBook Studio G8 (512GB NVMe SSD)  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"A red warning bar popped up over my C: drive saying 'Low Disk Space'. Now I can't save my Photoshop mockups, Outlook says 'The disk is full', and Windows won't even let me take screenshots or extract zip files. When I check File Explorer, it says 0 bytes free out of 476 GB! I haven't downloaded anything huge recently, so where did all my storage go?!"*
- **User:** Chloe Bennett (Lead Graphic Designer)  
- **Department:** Marketing & Creative Media  
- **Reported Impact:** Inability to save working files, application cache crashes, temp file write failures.

---

## 2. Technical Causes & Underlying Mechanics
1. **Accumulated Temporary File Bloat (`%TEMP%` & `C:\Windows\Temp`):**
   Applications (especially creative software like Adobe Suite, video editors, and unmanaged build tools) create multi-gigabyte scratch files during rendering. If an app crashes or fails to clean up on exit, these temp files persist indefinitely.
2. **Windows Component Store & Update Cache Bloat:**
   The `C:\Windows\SoftwareDistribution\Download` folder stores historical patch payloads. If previous cumulative updates encountered minor errors, gigabytes of stale `.cab` and `.esd` archives remain stranded.
3. **Runaway Windows Log Files (CBS Log Bloat Bug):**
   A well-documented Windows servicing bug where `C:\Windows\Logs\CBS\CBS.log` exceeds 20GB because the compression utility (`makecab.exe`) fails on large logs, spawning infinite multi-gigabyte temp files in `C:\Windows\Temp`.
4. **Volume Shadow Copy (VSS) Allocation Overload:**
   System Restore points or backup agents consuming an excessive percentage of drive allocation without self-trimming.

---

## 3. Diagnostic Investigation & Observations
- **Tools Utilized:**
  - Windows Settings -> **System** -> **Storage** (Storage Sense).
  - Disk Cleanup (`cleanmgr.exe /lowdisk`).
  - TreeSize Free / WizTree / WinDirStat (portable diagnostic visualizers).
  - Elevated PowerShell / Command Prompt (`Get-PSDrive`, `vssadmin`).

### Diagnostic Step 1: Storage Assessment via PowerShell
```powershell
Get-PSDrive C | Select-Object Name, @{Name="Used_GB";Expression={[math]::round($_.Used/1GB,2)}}, @{Name="Free_GB";Expression={[math]::round($_.Free/1GB,2)}}, @{Name="Total_GB";Expression={[math]::round(($_.Used+$_.Free)/1GB,2)}}
```

**Observed Output:**
```text
Name Used_GB Free_GB Total_GB
---- ------- ------- --------
C     475.82    0.18   476.00
```
*Critical Finding:* Less than 200 MB free (0.03% available headroom). Windows requires a minimum of 10-15% free space for virtual memory paging and temporary file swapping.

### Diagnostic Step 2: Storage Directory Tree Analysis
Ran portable directory analyzer (`WizTree`) in elevated mode to pinpoint space hogs:
1. `C:\Users\cbennett\AppData\Local\Temp`: **114 GB** (Stale Adobe Photoshop `.tmp` scratch files from unexpected shutdowns).
2. `C:\Windows\Temp`: **88 GB** (Orphaned `cab_xxxx_x` logs created by Windows servicing loops).
3. `C:\Windows\SoftwareDistribution\Download`: **34 GB** (Redundant patch download archives).
4. `System Volume Information`: **42 GB** (Old VSS restore points).

---

## 4. Root Cause Analysis (RCA)
- **Primary Root Cause:** Over **236 GB** of disk space was consumed by orphaned temporary application scratch files (`AppData\Local\Temp`), stranded Windows Update download payloads, and runaway Windows `cab_*.tmp` servicing logs.

---

## 5. Remediation Plan & Action Taken
1. **Emergency Temp File Purge:**
   Safely cleared all non-locked temporary files using elevated administrative script:
   ```cmd
   del /q /f /s "%systemroot%\Temp\*.*"
   del /q /f /s "%TEMP%\*.*"
   ```
2. **Purged Redundant Windows Update Delivery Cache:**
   ```cmd
   net stop wuauserv
   rd /s /q "%systemroot%\SoftwareDistribution\Download"
   net start wuauserv
   ```
3. **Executed Windows Component Store Cleanup (DISM):**
   Compressed and purged superseded system binaries:
   ```powershell
   Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
   ```
4. **Trimmed Volume Shadow Copies:**
   Inspected and resized VSS shadow storage cap:
   ```cmd
   vssadmin list shadowstorage
   vssadmin resize shadowstorage /for=c: /on=c: /maxsize=15GB
   ```
5. **Configured Windows 11 Storage Sense for Auto-Maintenance:**
   - Navigated to **Settings** -> **System** -> **Storage**.
   - Toggled **Storage Sense** to **On**.
   - Configured schedule: Run automatically when free disk space is low; purge Recycle Bin items older than 14 days and temporary files every 30 days.
6. **Escalation Boundary:**
   - *L1 Fix:* Safe temp deletion, DISM component cleanup, SoftwareDistribution purge, Storage Sense configuration.
   - *Escalate to L2 / Infrastructure:* Physical drive capacity upgrade needed (user genuinely requires 1TB+ for active local raw video editing); BitLocker recovery partition issues.

---

## 6. Verification & Preventive Measures
- **Re-assessed Free Storage:**
  - `Used_GB`: **212.4 GB**
  - `Free_GB`: **263.6 GB** (Over **55% free space restored**).
- **Functional Validation:** Chloe opened Photoshop, created a 4GB multi-layer test canvas, saved without errors, and drafted an email in Outlook successfully.

---

## 7. Customer Communication (Closing Ticket Note)
> *"Hi Chloe, thank you for your patience while we resolved your storage emergency! We analyzed your hard drive and discovered that over 200 GB of temporary scratch files and old background update records had built up without properly cleaning themselves out.
>
> We have safely cleared out the temporary files, tuned your system maintenance settings, and activated Windows Storage Sense so your laptop automatically clears unnecessary background cache going forward. You now have over 260 GB of free space available, and your creative tools are running smoothly again!"*
