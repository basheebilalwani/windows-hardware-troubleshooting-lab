# Case Incident Report: INC-10319 - Application Crashes and Freezing

**Ticket ID:** INC-10319  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P3 - Medium (User workflow intermittently disrupted)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Lenovo ThinkPad T14 Gen 4 - Windows 11 Pro 23H2  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"Every time I try to open a PDF or draft an email with attachments in Outlook, Outlook suddenly vanishes with no warning. No error message pops up—it just closes itself. When I re-open it, it freezes completely on 'Loading Profile...' for 5 minutes. Adobe Acrobat also freezes whenever I scroll down past page 3. I've restarted twice and it keeps happening."*
- **User:** David Kim (Corporate Legal Counsel)  
- **Department:** Legal & Compliance  
- **Reported Impact:** Outlook crash loops during contract review; PDF viewer crashes causing document loss.

---

## 2. Technical Causes & Underlying Mechanics
1. **Faulting DLL / Faulty Third-Party Add-In:**
   Enterprise Outlook profiles often have third-party COM Add-ins (e.g., legacy document management, Zoom plugins, digital signature tools). When an add-in references an unhandled exception or outdated dynamic link library (`.dll`), Windows terminates the host process immediately to protect memory integrity.
2. **Corrupted Local Application Cache / Profile:**
   Corrupted `.ost` (Offline Outlook Data file) or damaged Roaming AppData configuration files.
3. **OS System File / Visual C++ Runtime Corruption:**
   Corrupted shared C++ runtimes (`msvcr120.dll`, `vcruntime140.dll`) causing applications relying on those libraries to crash with unhandled exception `0xc0000005` (Access Violation).

---

## 3. Diagnostic Investigation & Observations
- **Tools Utilized:**
  - `Reliability Monitor` (`perfmon /rel`) — The fastest graphical timeline for crashes.
  - `Event Viewer` (`eventvwr.msc`) -> **Windows Logs** -> **Application**.
  - Safe Mode Launch Flags (`outlook.exe /safe`).
  - System File Checker (`sfc /scannow`) & DISM.

### Diagnostic Step 1: Graphical Timeline Analysis via Reliability Monitor
Opened Run dialog (`Win + R`), executed `perfmon /rel`.  
*Observation:* A steep drop in the System Stability Index (from 8.2 to 2.1) displaying red "Critical Event" X marks for `OUTLOOK.EXE` and `Acrobat.exe`.

### Diagnostic Step 2: Event Viewer Error Analysis
Opened `eventvwr.msc`, navigated to **Windows Logs** -> **Application**, filtered for **Error** and Event IDs `1000` (Application Error) and `1002` (Application Hang).

```text
Log Name:      Application
Source:        Application Error
Event ID:      1000
Task Category: Application Crashing Events
Level:         Error
Description:
Faulting application name: OUTLOOK.EXE, version: 16.0.17126.20132, time stamp: 0x65b9e0f1
Faulting module name: AdobePDFMakerAddIn.dll, version: 21.0.0.14, time stamp: 0x6041a903
Exception code: 0xc0000005 (Access Violation)
Fault offset: 0x000000000003b12c
Faulting process id: 0x3d44
Faulting application path: C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE
Faulting module path: C:\Program Files\Adobe\Acrobat DC\PDFMaker\Office\AdobePDFMakerAddIn.dll
```

*Key Technical Finding:* Outlook was not crashing due to Microsoft code; it was crashing inside `AdobePDFMakerAddIn.dll` throwing an access violation `0xc0000005`.

---

## 4. Root Cause Analysis (RCA)
- **Primary Root Cause:** An outdated, incompatible COM add-in (`AdobePDFMakerAddIn.dll`) injected into Outlook was attempting an illegal memory read operation (`0xc0000005`), causing Windows Error Reporting to terminate the host process (`OUTLOOK.EXE`).
- **Secondary Factor:** Adobe Acrobat's internal hardware acceleration cache was corrupted, causing concurrent document viewer crashes.

---

## 5. Remediation Plan & Action Taken
1. **Isolated Outlook in Safe Mode:**
   - Ran `Win + R` -> `outlook.exe /safe`. Outlook opened immediately without freezing, proving the core executable and mailbox profile were healthy.
2. **Disabled Faulting COM Add-in:**
   - In Outlook: Clicked **File** -> **Options** -> **Add-ins**.
   - Selected **Manage: COM Add-ins** -> Clicked **Go...**.
   - Unchecked `Acrobat PDFMaker Office COM Addin`.
3. **Repaired System Runtimes & Integrity:**
   Executed elevated repair commands in PowerShell:
   ```powershell
   DISM.exe /Online /Cleanup-image /Restorehealth
   sfc /scannow
   ```
   *Result:* SFC reported: *"Windows Resource Protection found corrupt files and successfully repaired them."*
4. **Updated Adobe Acrobat:**
   - Opened Adobe Acrobat -> Clicked **Help** -> **Check for Updates** to pull the patched DLL release.
5. **Escalation Boundary:**
   - *L1 Fix:* Add-in disabling, Office Quick/Online Repair, OST file recreation, SFC/DISM execution.
   - *Escalate to L2 / SysAdmin:* Application crashes caused by Group Policy registry push; widespread crash affecting 50+ users following enterprise patch; developer debugging requiring WinDbg dump analysis (`.dmp`).

---

## 6. Verification & Preventive Measures
- **Verification:** Launched Outlook normally (without `/safe`). Attached a 15MB PDF contract, drafted text, and sent successfully. Repeated with 5 different PDF documents—no crashes occurred.
- **Reliability Monitor:** Verified that no new red critical events registered over the subsequent 45 minutes of active usage.

---

## 7. Customer Communication (Closing Ticket Note)
> *"Hi David, thank you for your patience while we investigated Outlook and Adobe Acrobat. We reviewed the Windows error logs and discovered that an outdated PDF helper plugin inside Outlook was causing the program to shut down abruptly.
>
> We have disabled the conflicting plugin and updated your Adobe software to the latest compatible version. Outlook and your PDF viewer are now fully operational and stable. You can safely open and attach all your contracts without interruptions. Let us know if you need any further assistance!"*
