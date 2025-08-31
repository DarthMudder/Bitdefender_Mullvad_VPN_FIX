# Log file for monitoring
$logFile = "C:\Scripts\mullvad_log.txt"
Add-Content $logFile "$(Get-Date): Mullvad Auto-Disconnect Monitor started - Early Detection Version"

# Function to disconnect Mullvad VPN with retries
function Disconnect-Mullvad {
    param($reason)
    try {
        # First check current status
        $statusBefore = cmd /c "mullvad status" 2>&1
        Add-Content $logFile "$(Get-Date): *** EARLY SHUTDOWN DETECTED: $reason ***"
        Add-Content $logFile "$(Get-Date): Status before disconnect: $statusBefore"
        
        # Multiple disconnect attempts for reliability
        for ($i = 1; $i -le 3; $i++) {
            Add-Content $logFile "$(Get-Date): Disconnect attempt $i of 3..."
            $output = cmd /c "mullvad disconnect" 2>&1
            Add-Content $logFile "$(Get-Date): Disconnect $i output: $output"
            Start-Sleep -Seconds 2
            
            # Check if actually disconnected
            $currentStatus = cmd /c "mullvad status" 2>&1
            if ($currentStatus -match "Disconnected") {
                Add-Content $logFile "$(Get-Date): *** SUCCESSFULLY DISCONNECTED on attempt $i ***"
                break
            } else {
                Add-Content $logFile "$(Get-Date): Still connected after attempt $i, trying again..."
            }
        }
        
        # Final status check
        $statusAfter = cmd /c "mullvad status" 2>&1
        Add-Content $logFile "$(Get-Date): Final status: $statusAfter"
        Add-Content $logFile "$(Get-Date): *** DISCONNECT SEQUENCE COMPLETED ***"
        
    } catch {
        Add-Content $logFile "$(Get-Date): Error during disconnect: $($_.Exception.Message)"
    }
}

# PowerShell exit handler - ensures disconnect when PowerShell closes
$null = Register-EngineEvent PowerShell.Exiting -Action {
    Add-Content "C:\Scripts\mullvad_log.txt" "$(Get-Date): PowerShell exiting - emergency disconnect"
    try { 
        # Emergency disconnect
        cmd /c "mullvad disconnect" 
        Start-Sleep -Seconds 3
        cmd /c "mullvad disconnect"  # Second attempt
    } catch {}
}

Add-Content $logFile "$(Get-Date): Early detection monitoring active"

# Enhanced monitoring with multiple early indicators
$heartbeatCounter = 0
$consecutiveReductions = 0

try {
    while ($true) {
        Start-Sleep -Seconds 2  # Faster checking for early detection
        
        # Method 1: shutdown.exe detection (EARLIEST AND MOST RELIABLE)
        $shutdown = Get-Process -Name "shutdown" -ErrorAction SilentlyContinue
        if ($shutdown) {
            # Try to read command line to distinguish restart vs shutdown
            try {
                $cmdline = (Get-WmiObject Win32_Process -Filter "ProcessId='$($shutdown.Id)'" -ErrorAction SilentlyContinue).CommandLine
                Add-Content $logFile "$(Get-Date): shutdown.exe detected with command: $cmdline"
                Disconnect-Mullvad "shutdown.exe process (Early detection)"
                Start-Sleep -Seconds 10  # Wait long enough for disconnect to complete
                break  # Stop monitoring after disconnect
            } catch {
                Add-Content $logFile "$(Get-Date): shutdown.exe detected (command line unreadable)"
                Disconnect-Mullvad "shutdown.exe process"
                Start-Sleep -Seconds 10
                break
            }
        }
        
        # Method 2: Check for rapid process reduction (but more conservative than before)
        $currentProcessCount = (Get-Process).Count
        if ($currentProcessCount -lt 200) {  # Very low process count = likely shutdown
            Add-Content $logFile "$(Get-Date): Very low process count detected: $currentProcessCount"
            Disconnect-Mullvad "Critically low process count"
        }
        
        # Method 3: LogonUI detection (as backup)
        $logonUI = Get-Process -Name "LogonUI" -ErrorAction SilentlyContinue
        if ($logonUI) {
            Add-Content $logFile "$(Get-Date): LogonUI backup detection"
            Disconnect-Mullvad "LogonUI screen (backup detection)"
        }
        
        # Method 4: Session manager shutdown preparation
        try {
            $sessionManager = Get-Process -Name "smss" -ErrorAction SilentlyContinue
            if (-not $sessionManager) {
                Add-Content $logFile "$(Get-Date): Session Manager (smss.exe) missing"
                Disconnect-Mullvad "Session Manager shutdown"
            }
        } catch {}
        
        # Method 5: User session changes (for logoff detection)
        try {
            $sessionInfo = quser 2>$null
            if (-not $sessionInfo -or $sessionInfo.Length -eq 0) {
                Add-Content $logFile "$(Get-Date): User session ending"
                Disconnect-Mullvad "User session logoff"
            }
        } catch {
            # quser failing can also indicate session ending
            Add-Content $logFile "$(Get-Date): Session query failed - possible logoff"
            Disconnect-Mullvad "Session query failure"
        }
        
        # Heartbeat every 5 minutes
        $heartbeatCounter++
        if ($heartbeatCounter -ge 150) {  # 150 * 2 seconds = 5 minutes
            Add-Content $logFile "$(Get-Date): Early detection monitor running normally"
            $heartbeatCounter = 0
        }
    }
} catch {
    Add-Content $logFile "$(Get-Date): Monitor terminated: $($_.Exception.Message)"
    Disconnect-Mullvad "Exception - emergency disconnect"
}