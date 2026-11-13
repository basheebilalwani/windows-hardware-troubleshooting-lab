@echo off
:: ==============================================================
:: Script: reset-print-spooler.bat
:: Purpose: Flushes stuck print queue jobs and restarts spooler
:: Requirement: Run as Administrator
:: ==============================================================

echo [IT Support Tool] Stopping Print Spooler Service...
net stop spooler >nul 2>&1

echo [IT Support Tool] Purging stuck .SPL and .SHD spool files...
del /Q /F /S "%systemroot%\System32\Spool\Printers\*.*" >nul 2>&1

echo [IT Support Tool] Restarting Print Spooler Service...
net start spooler >nul 2>&1

if %errorlevel% equ 0 (
    echo [SUCCESS] Print spooler restarted and queue cleared successfully.
) else (
    echo [ERROR] Failed to restart spooler. Verify administrator privileges.
)
pause
