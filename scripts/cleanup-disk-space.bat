@echo off
:: ==============================================================
:: Script: cleanup-disk-space.bat
:: Purpose: Safely purges Windows Temp, User Temp, and error logs
:: Requirement: Run as Administrator
:: ==============================================================

echo [IT Support Tool] Purging System Temp files (%systemroot%\Temp)...
del /q /f /s "%systemroot%\Temp\*.*" >nul 2>&1

echo [IT Support Tool] Purging User AppData Temp files (%TEMP%)...
del /q /f /s "%TEMP%\*.*" >nul 2>&1

echo [IT Support Tool] Flushing obsolete Windows Error Reporting files...
del /q /f /s "%ProgramData%\Microsoft\Windows\WER\ReportQueue\*.*" >nul 2>&1

echo [SUCCESS] Temporary files purged successfully.
pause
