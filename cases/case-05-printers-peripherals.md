# Case Incident Report: INC-10562 - Printer and Peripheral Connectivity Issues

**Ticket ID:** INC-10562  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P3 - Medium (User unable to print confidential invoices)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Windows 11 Pro - HP ProDesk 400 G9 Mini / Canon imageRUNNER 3530  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"I've been trying to print our monthly customer billing invoices for the last hour and nothing comes out. The printer says 'Ready' on its physical touch screen, but on my computer it shows 'Offline' or 'Error - Printing'. I clicked 'Print' six times, tried turning the printer off and on, and now even my USB barcode scanner stopped working and makes a disconnecting sound every 10 seconds!"*
- **User:** Angela Martin (Accounts Receivable Specialist)  
- **Department:** Accounting & Billing  
- **Reported Impact:** Billing dispatch stalled; printer queue locked; USB scanner disconnecting cyclically.

---

## 2. Technical Causes & Underlying Mechanics
1. **Print Spooler Crash / Stale Job Deadlock:**
   The Windows Print Spooler service (`spoolsv.exe`) manages the spool directory (`C:\Windows\System32\spool\PRINTERS`). If a corrupt EMF (Enhanced Metafile) or raw spool file (`.SHD` / `.SPL`) fails to render, the spooler thread enters a deadlock. All subsequent print jobs stack up behind the corrupted job, and the spooler drops the printer into an "Error / Offline" state.
2. **WSD (Web Services for Devices) Port Drift:**
   Windows 11 often defaults to discovering network printers via WSD instead of a static TCP/IP port. WSD is notoriously prone to dropping offline when sleep/standby IP re-negotiation occurs.
3. **USB Root Hub Power Management (Selective Suspend):**
   Windows Power Management enables "Selective Suspend" on USB root hubs by default, cutting power to low-draw peripherals (like barcode scanners) during idle states and causing rapid disconnect loops.

---

## 3. Diagnostic Investigation & Observations
- **Tools Utilized:**
  - `Print Management` (`printmanagement.msc`)
  - `Services Console` (`services.msc` -> Print Spooler)
  - `Device Manager` (`devmgmt.msc` -> Universal Serial Bus controllers)
  - PowerShell (`Get-PrintJob`, `Restart-Service Spooler`)

### Diagnostic Step 1: Querying the Local Print Queue via PowerShell
```powershell
Get-PrintJob -PrinterName "Canon-Floor3-Finance" | Select-Object Id, DocumentName, JobStatus, Size
```

**Observed Output:**
```text
Id  DocumentName                 JobStatus   Size
--  ------------                 ---------   ----
14  Customer_Invoice_Batch.pdf   Error       2841920
15  Customer_Invoice_Batch.pdf   Retrying    2841920
16  Customer_Invoice_Batch.pdf   Spooling    2841920
17  Customer_Invoice_Batch.pdf   Queued      2841920
18  Customer_Invoice_Batch.pdf   Queued      2841920
```
*Finding:* Job ID 14 was locked in an unrecoverable `Error` state, causing a complete FIFO queue blockage.

### Diagnostic Step 2: Investigating the Port Configuration
Navigated to **Printers & scanners** -> **Canon-Floor3-Finance** -> **Printer properties** -> **Ports** tab:
*Finding:* The port was assigned to `WSD-9fa1...` instead of a dedicated Standard TCP/IP Port.

### Diagnostic Step 3: USB Peripheral Disconnect Inspection
Checked Device Manager under **Universal Serial Bus controllers**. Observed **USB Root Hub (USB 3.0)** power management setting: *"Allow the computer to turn off this device to save power"* was checked.

---

## 4. Root Cause Analysis (RCA)
- **Primary Root Cause:** A corrupted PDF rendering job jammed the local Windows Print Spooler queue (`C:\Windows\System32\spool\PRINTERS`), preventing all pending jobs from dispatching.
- **Secondary Root Cause:** The network printer was bound to an unstable WSD discovery port rather than a fixed Standard TCP/IP port, causing frequent "Offline" status reports.
- **Peripheral Cause:** USB Selective Suspend was aggressively disabling the barcode scanner's USB hub port.

---

## 5. Remediation Plan & Action Taken
1. **Purged the Jammed Spool Queue:**
   Executed the classic L1 emergency spooler reset sequence in elevated Command Prompt:
   ```cmd
   net stop spooler
   del /Q /F /S "%systemroot%\System32\Spool\Printers\*.*"
   net start spooler
   ```
   *Result:* Cleared the five stalled `.SPL` and `.SHD` lock files safely.
2. **Converted WSD Port to Static Standard TCP/IP Port:**
   - In Printer Properties -> **Ports** tab -> Clicked **Add Port...**.
   - Selected **Standard TCP/IP Port** -> **New Port**.
   - Configured Printer IP: `192.168.10.85` (reserved static DHCP lease).
   - Unchecked *"Bidirectional support"* if driver status pinging caused false offline flags.
3. **Fixed USB Scanner Disconnection:**
   - In Device Manager -> **Universal Serial Bus controllers** -> Right-clicked each **USB Root Hub** -> **Properties** -> **Power Management**.
   - Unchecked: **"Allow the computer to turn off this device to save power"**.
4. **Escalation Boundary:**
   - *L1 Fix:* Clearing spooler files, restarting service, configuring TCP/IP port, USB power management, driver re-installation.
   - *Escalate to L2 / Print Server Admin:* Centrally managed Active Directory Print Server queue corruption; network firewall blocking raw LPR/RAW port 9100; physical printer hardware faults (fuser error, paper feed sensor failure).

---

## 6. Verification & Preventive Measures
- **Test Page Generation:** Sent a standard Windows Test Page from Printer Properties. Output printed cleanly in 3 seconds.
- **User Workflow Test:** Guided Angela to print invoice pages 1–5. The job processed instantly without spooler errors.
- **Barcode Scanner Test:** Reconnected the USB scanner. Scanned 10 sample barcodes continuously without any disconnect chimes or drops.

---

## 7. Customer Communication (Closing Ticket Note)
> *"Hi Angela, thank you for your patience! We investigated both your printer and barcode scanner. A corrupted document had stalled your computer's print service, creating a digital traffic jam that prevented all other invoices from printing. We also resolved the scanner issue by preventing Windows from turning off your USB port during power-saving mode.
>
> We have cleared the queue, switched the printer to a rock-solid direct network address, and successfully printed a test document. Your billing invoices and barcode scanner are now ready to use. Please let us know if you need anything else!"*
