# Windows 11 IT Support & Troubleshooting Lab

A collection of hands-on Windows 11 desktop support case studies, diagnostic workflows, and automation scripts. Each case documents a real-world incident from initial user report to root cause analysis (RCA), resolution, and verification.

---

## 📁 Repository Structure

```text
├── cases/                                # Documented incident reports with RCA and resolutions
│   ├── case-01-slow-pc-high-resources.md # High CPU/RAM usage & process triage
│   ├── case-02-startup-boot-issues.md    # Boot storms, clean boot & boot configuration
│   ├── case-03-app-crashes-freezing.md   # Outlook/PDF crashes, Event ID 1000 & Safe Mode triage
│   ├── case-04-driver-device-manager.md  # Wi-Fi driver Code 43, PnPUtil & hardware ID matching
│   ├── case-05-printers-peripherals.md   # Print spooler deadlock, TCP/IP ports & USB suspend
│   ├── case-06-storage-disk-space.md     # C: drive storage exhaustion, temp purging & DISM cleanup
│   ├── case-07-windows-update-failures.md# Update error 0x80070002 & SoftwareDistribution rebuild
│   └── case-08-hardware-diagnosis.md     # Memory failure (mdsched), thermals & battery reporting
├── scripts/                              # L1 diagnostic and remediation automation
│   ├── README.md                         # Script documentation and usage
│   ├── triage-system-health.ps1          # PowerShell endpoint health diagnostic collector
│   ├── reset-print-spooler.bat           # Emergency spooler reset & queue un-jammer
│   ├── reset-windows-update-cache.bat    # Automated update cache rebuilder
│   └── cleanup-disk-space.bat            # Safe temporary file cleanup script
└── README.md
```

---

## 📋 Incident Cases

| Ticket ID | Category | Issue Description | Diagnostic Tools | Report |
| :---: | :--- | :--- | :--- | :---: |
| **INC-10204** | Resource Utilization | Severe UI latency, fan at max, Excel freezing | Task Manager, `resmon`, PowerShell | [View](cases/case-01-slow-pc-high-resources.md) |
| **INC-10245** | Startup & Boot | 8-minute boot time, Automatic Repair loop | `msconfig`, Task Manager Startup, WinRE | [View](cases/case-02-startup-boot-issues.md) |
| **INC-10319** | Application Stability | Outlook crashing silently on PDF attachments | Event Viewer (ID 1000), `perfmon /rel` | [View](cases/case-03-app-crashes-freezing.md) |
| **INC-10488** | Drivers & Hardware | Wi-Fi adapter disabled with Code 43 | `devmgmt.msc`, `pnputil`, Hardware IDs | [View](cases/case-04-driver-device-manager.md) |
| **INC-10562** | Printers & Peripherals | Billing printer offline; USB scanner disconnects | `printmanagement.msc`, `spoolsv.exe` | [View](cases/case-05-printers-peripherals.md) |
| **INC-10671** | Storage & Volumes | C: drive has 0 bytes free; apps failing to save | Storage Sense, `cleanmgr`, DISM | [View](cases/case-06-storage-disk-space.md) |
| **INC-10734** | Windows Servicing | Cumulative update rolls back with Error 0x80070002 | `wuauserv`, `SoftwareDistribution`, DISM | [View](cases/case-07-windows-update-failures.md) |
| **INC-10892** | Hardware Diagnostics | Intermittent BSODs, CPU throttling to 0.79GHz, battery drop | `mdsched.exe`, `powercfg`, SMART telemetry | [View](cases/case-08-hardware-diagnosis.md) |

---

## ⚙️ Diagnostic Scripts

| Script | Language | Purpose |
| :--- | :---: | :--- |
| `triage-system-health.ps1` | PowerShell | Collects baseline system health: Uptime, CPU, RAM %, C: drive storage, top 5 processes by CPU time, and physical disk status. |
| `reset-print-spooler.bat` | Batch | Stops `spoolsv.exe`, clears locked `.SPL` and `.SHD` spool files from `%systemroot%\System32\Spool\Printers\`, and restarts the service. |
| `reset-windows-update-cache.bat` | Batch | Halts update services (`wuauserv`, `cryptSvc`, `bits`), renames `SoftwareDistribution` and `catroot2` to purge corrupt download caches, and restarts services. |
| `cleanup-disk-space.bat` | Batch | Safely purges temporary directories (`%systemroot%\Temp` and `%TEMP%`) and Windows Error Reporting queues to free immediate drive space. |

---

## 🛠️ Tools & Technologies Used

* **OS Diagnostics:** Task Manager (`taskmgr`), Resource Monitor (`resmon`), Performance Monitor (`perfmon`), Event Viewer (`eventvwr.msc`), Reliability Monitor (`perfmon /rel`), Windows Memory Diagnostic (`mdsched.exe`).
* **Device & Print Management:** Device Manager (`devmgmt.msc`), Driver Store (`pnputil`), Print Management (`printmanagement.msc`).
* **System Repair & Servicing:** DISM (`dism.exe`), System File Checker (`sfc.exe`), Check Disk (`chkdsk.exe`), System Configuration (`msconfig`).
* **Scripting & Automation:** Windows PowerShell 5.1 / 7 (CIM/WMI cmdlets), Windows Command Prompt.
