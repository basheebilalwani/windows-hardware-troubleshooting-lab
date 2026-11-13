# Case Incident Report: INC-10892 - Basic Hardware Diagnostics (RAM, Thermals, Battery, Disk)

**Ticket ID:** INC-10892  
**Date Logged:** 2026-11-13  
**Severity / Priority:** P2 - High (Intermittent BSODs and battery cut-offs affecting remote executive)  
**Assigned Technician:** IT Support Engineer (L1)  
**Endpoint System:** Dell XPS 15 9520 - Windows 11 Pro  

---

## 1. Initial User Ticket / Complaint
- **User Statement:** *"My laptop has become completely unreliable over the past two weeks. First, it randomly blue-screens with an error mentioning 'MEMORY_MANAGEMENT' or 'CRITICAL_PROCESS_DIED' while I'm on Zoom calls. Second, the underside gets burning hot within 10 minutes of turning it on, and the machine turns sluggish as molasses. Third, my battery drops from 85% to 5% instantly and the laptop dies without any low-battery warning. I am traveling internationally next week and need to know if this machine needs to be replaced!"*
- **User:** Robert Sterling (Chief Marketing Officer)  
- **Department:** Executive Office  
- **Reported Impact:** Random system crashes (BSOD), severe thermal throttling, sudden battery shutdowns during meetings.

---

## 2. Technical Causes & Underlying Mechanics
1. **Faulty / Degraded Physical RAM (Memory Corruption):**
   Physical DDR memory chips can develop weak capacitive cells or solder joint fractures over time. When Windows kernel attempts to write or read from an unstable memory address, a non-recoverable hardware fault occurs, triggering a Stop Code like `MEMORY_MANAGEMENT` (`0x0000001A`) or `PAGE_FAULT_IN_NONPAGED_AREA` (`0x00000050`).
2. **Thermal Throttling & Clogged Exhaust Fins:**
   Modern CPUs (Intel Core i7/i9, AMD Ryzen) contain internal thermal junction limiters (Tjunction Max ~100°C). When dust clogs the radiator fins or thermal paste dries out, the CPU throttles its clock multiplier down to minimum floor frequency (e.g., 0.79 GHz or 800 MHz) to prevent silicon damage, resulting in extreme interface lag.
3. **Internal Battery Cell Degradation (Voltage Collapse):**
   Lithium-ion battery packs consist of multiple cells wired in series/parallel. When one cell degrades prematurely, its internal resistance spikes. Under load (such as starting a video conference), the overall pack voltage collapses below the minimum operating threshold, causing the laptop's Power Management Controller (PMC) to trigger an immediate hard shutdown.
4. **Storage Controller Degradation (SMART Warnings):**
   NVMe SSDs report wear-leveling and spare block exhaustion via SMART metrics.

---

## 3. Diagnostic Investigation & Observations
- **Tools Utilized:**
  - `Windows Memory Diagnostic` (`mdsched.exe`).
  - Battery Health Generator (`powercfg /batteryreport`).
  - Storage Reliability Cmdlets (`Get-PhysicalDisk`, `Get-StorageReliabilityCounter`).
  - Event Viewer -> **System Log** -> Filter: Source `MemoryDiagnostics-Results` & `BugCheck`.
  - Task Manager -> **Performance** -> **CPU** (monitoring Clock Speed vs. Thermal load).

### Diagnostic Step 1: Memory Integrity Testing via `mdsched.exe`
1. Executed `mdsched.exe` -> selected **"Restart now and check for problems"**.
2. Ran **Extended Diagnostic Test Pass**.
3. Upon Windows reboot, queried the Event Viewer System log for Source `MemoryDiagnostics-Results`:
```text
Log Name:      System
Source:        Microsoft-Windows-MemoryDiagnostics-Results
Event ID:      1102
Level:         Error
Description:
The Windows Memory Diagnostic tested the computer's memory and detected hardware errors. 
To refer to these errors, contact the computer manufacturer.
```
*Critical Hardware Finding:* Hardware memory failure verified on DIMM Module Slot 2.

### Diagnostic Step 2: Battery Health & Degradation Analysis
Generated Windows Battery Health telemetry in elevated PowerShell:
```powershell
powercfg /batteryreport /output "C:\temp\battery_report.html"
```
Extracted telemetry details from the generated report:
```text
BATTERY CHARACTERISTICS
DESIGN CAPACITY:   86,000 mWh
FULL CHARGE CAP:   29,140 mWh  (Degraded by > 66%)
CYCLE COUNT:       892 cycles

RECENT BATTERY DRAIN:
14:10:05 - Active - 82% (23,894 mWh)
14:12:18 - Suspended - 4% (1,165 mWh) [Sudden Voltage Drop]
```
*Finding:* Battery pack has experienced severe chemical degradation; cycle count exceeds rating (892 cycles) and capacity has diminished by 66%, explaining the instant power cuts.

### Diagnostic Step 3: Storage SMART Health Check
Queried NVMe drive health via PowerShell:
```powershell
Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, OperationalStatus
Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk)[0] | Select-Object Temperature, Wear, ReadErrorsTotal, WriteErrorsTotal
```
*Finding:* Drive HealthStatus: `Healthy`, Wear: `9%`, Temperature: `42°C`. The NVMe SSD is in excellent condition.

### Diagnostic Step 4: Thermal & CPU Frequency Verification
Observed CPU behavior under load:
- Base speed: **2.30 GHz**.
- Measured speed during Zoom call: **0.79 GHz** locked.
- CPU Fan: Spinning at maximum RPM with audible whistling (dust accumulation blocking radiator vents).

---

## 4. Root Cause Analysis (RCA)
- **Root Cause 1 (BSODs):** Defective physical RAM stick installed in Slot 2, failing Windows Memory Diagnostic address testing and triggering kernel BugCheck `0x0000001A`.
- **Root Cause 2 (Thermal Throttling):** Dust obstruction across cooling heatsink radiator fins causing CPU thermal throttling to 0.79 GHz.
- **Root Cause 3 (Battery Drops):** Chemically degraded lithium-ion battery pack with an internal failing cell dropping voltage under load.

---

## 5. Remediation Plan & Escalation Decision
1. **Immediate L1 Action (Thermal Mitigation & Workaround):**
   - Cleaned cooling vents and fan exhaust using compressed air in controlled bursts.
   - Removed defective RAM module from Slot 2; laptop booted cleanly on the remaining 16GB stick in Slot 1.
   - Re-ran `mdsched.exe` on Slot 1 RAM alone: **Passed with 0 errors**.
2. **Escalation to L2 / Hardware Depot (RMA Warranty Dispatch):**
   - Opened Dell ProSupport Plus hardware dispatch ticket:
     - Dispatched replacement 16GB DDR5 SODIMM module.
     - Dispatched replacement OEM 86 Wh battery pack.
   - Scheduled on-site technician visit before Robert's international flight.
3. **Escalation Boundary:**
   - *L1 Action:* Running memory diagnostics, battery health reporting, SMART disk queries, vent cleaning, single-stick isolation.
   - *Escalate to Hardware Vendor / Depot:* Component replacement (motherboard, soldered RAM, battery replacement, thermal assembly repasting).

---

## 6. Verification & Preventive Measures
- **Temporary Stability Test:** With the faulty RAM stick removed, ran a 30-minute stress test while streaming 4K video. Zero BSODs recorded.
- **Thermal Post-Check:** After air dusting, CPU speed stabilized between **2.8 GHz and 3.4 GHz** without throttling to 0.79 GHz.
- **User Temporary Guidance:** Instructed Robert to keep the laptop connected to AC power until the Dell on-site technician arrives to install the new battery pack.

---

## 7. Customer Communication (Closing / Status Note)
> *"Hi Robert, thank you for bringing your laptop in. We conducted a complete hardware diagnostic suite on your Dell XPS. Here are our findings:
>
> 1. **Crashes:** We identified that one of your laptop's memory sticks has developed physical errors. We have safely removed the faulty stick; your laptop is currently running stably on 16GB of memory without any crashes.
> 2. **Overheating:** We cleaned out dust blocking your cooling vents, which has brought your processor speeds back to full speed.
> 3. **Battery:** The battery has naturally degraded after extensive use and requires replacement.
>
> Because your laptop has executive next-business-day warranty coverage, we have already scheduled a certified technician to replace the battery and install a brand-new memory stick tomorrow morning before your departure. You can safely use the laptop on charger power today. We will see you tomorrow to finalize the repair!"*
