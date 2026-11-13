<#
.SYNOPSIS
    L1 Support Triage & System Health Diagnostic Script
.DESCRIPTION
    Safely collects baseline system telemetry: Uptime, CPU, RAM utilization,
    Disk free space, top consuming processes, and physical disk status.
    Read-only, non-destructive.
.OUTPUTS
    Console formatted summary table.
#>

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         L1 IT SUPPORT SYSTEM HEALTH TRIAGE TOOL          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Operating System & Uptime
$OS = Get-CimInstance Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.LastBootUpTime
Write-Host "`n[+] SYSTEM IDENTITY & UPTIME:" -ForegroundColor Yellow
Write-Host "Host Name:       $($env:COMPUTERNAME)"
Write-Host "OS Build:        $($OS.Caption) ($($OS.Version))"
Write-Host "Last Boot Time:  $($OS.LastBootUpTime)"
Write-Host "Total Uptime:    $($Uptime.Days) Days, $($Uptime.Hours) Hours, $($Uptime.Minutes) Minutes"

# 2. CPU Information
$CPU = Get-CimInstance Win32_Processor
Write-Host "`n[+] PROCESSOR (CPU):" -ForegroundColor Yellow
Write-Host "Model:           $($CPU.Name)"
Write-Host "Cores / Threads: $($CPU.NumberOfCores) Cores / $($CPU.NumberOfLogicalProcessors) Logical Processors"
Write-Host "Max Clock Speed: $($CPU.MaxClockSpeed) MHz"

# 3. RAM Utilization
$TotalRAM_GB = [math]::round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM_GB  = [math]::round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM_GB  = [math]::round($TotalRAM_GB - $FreeRAM_GB, 2)
$PercentRAM  = [math]::round(($UsedRAM_GB / $TotalRAM_GB) * 100, 1)

Write-Host "`n[+] MEMORY (RAM):" -ForegroundColor Yellow
Write-Host "Total Physical:  $TotalRAM_GB GB"
Write-Host "In Use:          $UsedRAM_GB GB ($PercentRAM%)"
Write-Host "Free Available:  $FreeRAM_GB GB"

# 4. Storage Space (C: Drive)
$DriveC = Get-PSDrive C
$DriveTotal_GB = [math]::round(($DriveC.Used + $DriveC.Free) / 1GB, 2)
$DriveUsed_GB  = [math]::round($DriveC.Used / 1GB, 2)
$DriveFree_GB  = [math]::round($DriveC.Free / 1GB, 2)
$DrivePercent  = [math]::round(($DriveUsed_GB / $DriveTotal_GB) * 100, 1)

Write-Host "`n[+] SYSTEM DISK (C:):" -ForegroundColor Yellow
Write-Host "Total Capacity:  $DriveTotal_GB GB"
Write-Host "Used Space:      $DriveUsed_GB GB ($DrivePercent%)"
Write-Host "Free Space:      $DriveFree_GB GB"

if ($DriveFree_GB -lt 15) {
    Write-Host "WARNING: C: Drive has less than 15GB free space!" -ForegroundColor Red
} else {
    Write-Host "Status: Healthy Storage Headroom" -ForegroundColor Green
}

# 5. Top 5 CPU Processes (Cumulative Processor Time)
Write-Host "`n[+] TOP 5 PROCESSES BY CPU TIME:" -ForegroundColor Yellow
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 ProcessName, Id, @{Name="CPU_Seconds"; Expression={[math]::round($_.CPU, 1)}}, @{Name="WorkingSet_MB"; Expression={[math]::round($_.WorkingSet / 1MB, 1)}} | Format-Table -AutoSize

# 6. Physical Disk Health Status
Write-Host "[+] STORAGE HARDWARE HEALTH:" -ForegroundColor Yellow
Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, HealthStatus, OperationalStatus | Format-Table -AutoSize

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                 TRIAGE SCAN COMPLETE                     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
