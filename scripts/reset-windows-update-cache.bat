@echo off
:: ==============================================================
:: Script: reset-windows-update-cache.bat
:: Purpose: Resets Windows Update Agent, SoftwareDistribution & Catroot2
:: Requirement: Run as Administrator
:: ==============================================================

echo [IT Support Tool] Stopping Update & Cryptographic Services...
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1

echo [IT Support Tool] Renaming SoftwareDistribution and catroot2 cache folders...
if exist "%systemroot%\SoftwareDistribution.old" rd /s /q "%systemroot%\SoftwareDistribution.old"
if exist "%systemroot%\System32\catroot2.old" rd /s /q "%systemroot%\System32\catroot2.old"

ren "%systemroot%\SoftwareDistribution" SoftwareDistribution.old >nul 2>&1
ren "%systemroot%\System32\catroot2" catroot2.old >nul 2>&1

echo [IT Support Tool] Restarting Services...
net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1

echo [SUCCESS] Windows Update cache reset successfully.
echo Please go to Settings -> Windows Update and click 'Check for updates'.
pause
