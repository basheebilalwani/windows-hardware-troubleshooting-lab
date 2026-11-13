# Case Incident Report: INC-10204 - Slow Computer and High Resource Utilization

**Ticket ID:** INC-10204  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P3 - Medium (User operational but severely degraded)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Windows 11 Enterprise (Physical Workstation)  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"My laptop has been crawling all morning. When I open Excel or try to switch between Outlook and Teams, the mouse freezes, the fan sounds like a jet engine, and Windows keeps saying 'Not Responding' for 30 seconds at a time. I have a major quarterly budget presentation with our VP this afternoon and I cannot work like this!"*
- **User:** Rachel Green (Senior Financial Analyst)
- **Department:** Financial Planning & Analysis  
- **Reported Impact:** Severe UI stuttering, application latency, system fan running at maximum speed.

---

## 2. Initial Assessment & Information Gathering
- **Triage Questions Asked:**
  1. *How long has this been happening?* -> *"Started about 2 hours ago when I opened a large Excel workbook while running Teams and Outlook."*
  2. *Have you restarted your machine recently?* -> *"I shut the lid every evening when I leave the office."*
- **Baseline Hardware Profile:**
  - **CPU:** AMD Ryzen 7 7435HS (8 Cores, 16 Logical Processors)
  - **Base Clock:** 3.10 GHz (Current Speed: ~3.39 GHz - Normal boost range)
  - **Installed RAM:** 16.0 GB DDR5 SODIMM (4800 MT/s)
  - **System Up Time:** 0:21:31:02 (~21.5 hours)

---

## 3. Diagnostic Investigation & Observations
- **Diagnostic Tools Utilized:**
  - `Task Manager` (`taskmgr`)
  - `PowerShell 5.1` (`Get-Process`)
  - `Resource Monitor` (`resmon`)

### Step 1: Real-Time Process Inspection (Task Manager)
Sorted running processes by CPU and Memory utilization:
```text
Image Name          PID     Status      CPU %    Working Set (RAM)
------------------------------------------------------------------
EXCEL.EXE          4210    Running     88.4%    3,842.1 MB
msedge.exe         9144    Running      4.1%      840.5 MB
SearchIndexer.exe  2180    Running      3.2%      185.2 MB
MsMpEng.exe        3108    Running      1.1%      159.7 MB
explorer.exe       5892    Running      0.4%      105.7 MB
```

### Step 2: PowerShell Diagnostic Triage
Executed diagnostic query to inspect processes by cumulative processor time:
```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, Id, CPU, @{Name="RAM_MB"; Expression={[math]::round($_.WorkingSet / 1MB, 2)}}
```

**Observed Output:**
```text
ProcessName        Id      CPU         RAM_MB
-----------        --      ---         ------
EXCEL              4210    1452.83     3842.10
msedge             9144     393.09      840.50
Teams             11400     111.02      514.11
SearchIndexer      2180      66.59      185.20
MsMpEng            3108      50.84      159.70
```

> **Technical Insight:**  
> In Task Manager, the CPU column displays **instantaneous CPU % utilization**. In PowerShell (`Get-Process`), the `CPU` property reflects **cumulative processor time in CPU-seconds** consumed over the entire lifetime of the process.

---

## 4. Root Cause Analysis (RCA)
- **Primary Root Cause:** A locked multi-threaded calculation loop in `EXCEL.EXE` (PID 4210) was consuming 88% of total CPU capacity and holding 3.8 GB of private working set memory.
- **Secondary Factor:** Windows Fast Startup preserved kernel state across lid closures, accumulating background memory fragmentation over multiple days.

---

## 5. Remediation Plan & Action Taken
1. **Isolated Unresponsive Process:** Inspected Resource Monitor -> CPU -> **Analyze Wait Chain**. Confirmed `EXCEL.EXE` was waiting on a stalled network drive reference.
2. **Terminated Runaway Process:** Safely ended `EXCEL.EXE` (PID 4210) via Task Manager.
3. **Optimized Startup Configuration:** Disabled unapproved high-impact startup items in Task Manager -> **Startup apps**.
4. **Performed Cold Reboot:** Executed `shutdown /r /t 0` to bypass Fast Startup hibernation cache, flush system RAM, and reset uptime.
5. **Escalation Boundary:**  
   - *Resolved at L1:* Runaway application termination, startup pruning, Fast Startup cache flush.  
   - *Escalate to L2 / Hardware:* Sustained thermal throttling (< 1.0 GHz clock speed under load) due to fan bearing or heatsink failure; uncorrectable memory parity errors.

---

## 6. Verification & Preventive Measures
- **Verification:** System CPU dropped to healthy idle baseline (< 3%), RAM stabilized at 32%, and application response times normalized to < 1 second.
- **Preventive Measure:** Guided user on enabling Excel AutoRecover intervals and performing a weekly system restart.

---

## 7. Customer Communication (Closing Ticket Note)
> *"Hi Rachel, thank you for your patience today. We identified that an Excel background process was caught in a calculation loop, which was consuming most of your processor power and causing your fans to run at high speed.
>
> We safely cleared the locked process, refreshed your system memory, and verified that your laptop is running cool and at full speed again. Everything is ready for your presentation this afternoon. Please reach out if you need anything else, and good luck with the presentation!"*
