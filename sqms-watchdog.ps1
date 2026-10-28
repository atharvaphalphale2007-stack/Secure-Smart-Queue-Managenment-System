##############################################################
# SQMS Watchdog - Auto-restarts backend if it crashes
# This script runs silently in the background
# Place in Windows Startup folder to run on every login
##############################################################

$backendPath  = "c:\Users\ATHARVE\Documents\Project2\server\src\index.js"
$frontendDir  = "c:\Users\ATHARVE\Documents\Project2"
$backendPort  = 4000
$frontendPort = 5173
$checkInterval = 30  # seconds between health checks
$logFile = "c:\Users\ATHARVE\Documents\Project2\sqms-watchdog.log"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts  $msg" | Tee-Object -FilePath $logFile -Append | Write-Host
}

function Is-PortListening($port) {
    $conn = netstat -ano | Select-String ":$port\s+.+LISTENING"
    return $null -ne $conn
}

function Start-Backend {
    Write-Log "Starting backend on port $backendPort ..."
    Start-Process -FilePath "node" -ArgumentList $backendPath `
        -WindowStyle Hidden -PassThru | Out-Null
    Start-Sleep -Seconds 4
    if (Is-PortListening $backendPort) {
        Write-Log "Backend started OK."
    } else {
        Write-Log "WARNING: Backend may have failed to start. Check index.js"
    }
}

function Start-Frontend {
    Write-Log "Starting frontend on port $frontendPort ..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c cd /d `"$frontendDir`" && npx vite --host 0.0.0.0 --port $frontendPort"
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    Start-Sleep -Seconds 6
    if (Is-PortListening $frontendPort) {
        Write-Log "Frontend started OK."
    } else {
        Write-Log "WARNING: Frontend may have failed to start."
    }
}

Write-Log "=========================================="
Write-Log " SQMS Watchdog STARTED"
Write-Log "=========================================="

# Initial startup
if (-not (Is-PortListening $backendPort))  { Start-Backend  }
if (-not (Is-PortListening $frontendPort)) { Start-Frontend }

# Continuous monitoring loop
while ($true) {
    Start-Sleep -Seconds $checkInterval

    if (-not (Is-PortListening $backendPort)) {
        Write-Log "ALERT: Backend (port $backendPort) is DOWN. Restarting..."
        Start-Backend
    }

    if (-not (Is-PortListening $frontendPort)) {
        Write-Log "ALERT: Frontend (port $frontendPort) is DOWN. Restarting..."
        Start-Frontend
    }
}
