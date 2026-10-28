@echo off
title SQMS - Smart Queue Management System
color 0A
echo.
echo ============================================================
echo   SQMS - Smart Queue Management System
echo   Starting servers...
echo ============================================================
echo.

:: Kill any existing instances on these ports first
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":4000" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":5173" ^| findstr "LISTENING"') do (
    taskkill /F /PID %%a >nul 2>&1
)

timeout /t 2 /nobreak >nul

echo [1/2] Starting Backend API (port 4000)...
start "SQMS-Backend" /MIN cmd /c "node c:\Users\ATHARVE\Documents\Project2\server\src\index.js"

timeout /t 3 /nobreak >nul

echo [2/2] Starting Frontend (port 5173)...
start "SQMS-Frontend" /MIN cmd /c "cd /d c:\Users\ATHARVE\Documents\Project2 && npx vite --host 0.0.0.0 --port 5173"

timeout /t 5 /nobreak >nul

echo.
echo ============================================================
echo   SQMS is RUNNING!
echo   Open browser: http://localhost:5173
echo ============================================================
echo.
echo This window can be minimized. Do NOT close it.
echo.
pause
