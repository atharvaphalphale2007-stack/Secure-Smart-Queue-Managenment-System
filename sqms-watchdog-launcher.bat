@echo off
:: SQMS Watchdog Launcher - Runs in Windows Startup
:: Starts the PowerShell watchdog silently in the background
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "c:\Users\ATHARVE\Documents\Project2\sqms-watchdog.ps1"
