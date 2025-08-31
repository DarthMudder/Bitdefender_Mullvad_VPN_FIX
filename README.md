# Complete Fix for Mullvad VPN vs. Bitdefender Startup Conflict

## Problem
When both Mullvad VPN and Bitdefender are installed, you may get the error:
**"Bitdefender Services Could Not Be Loaded"** on Windows startup.  
This happens because both programs try to access network interfaces at the same time during boot (race condition).

## Root Cause
Both applications initialize network drivers simultaneously during startup. This can cause Bitdefender's services to fail loading properly.

---

## Solution Overview
1. **Disable** Mullvad's built-in autostart
2. **Use Task Scheduler** to delay Mullvad launch by 1 minute
3. **(Optional Advanced)** Add an auto-disconnect script to cleanly disconnect Mullvad before shutdown/restart/logoff

---

## Part 1: Basic Fix (Task Scheduler)

### Step 1: Disable Mullvad's Standard Autostart
- In Mullvad:
  1. Open Mullvad → Settings (gear icon) → UI Settings
  2. Disable "Launch app on system startup"
- In Task Manager:
  1. Press `Ctrl + Shift + Esc`
  2. Go to "Startup Apps"
  3. Set Mullvad VPN to "Disabled"

### Step 2: Create Delayed Task Scheduler Entry
1. Open Task Scheduler
2. Create Task → General Tab:
   - Name: `Delayed Mullvad Launch`
   - Check "Run with highest privileges"
3. Triggers Tab:
   - "Begin task": At log on
   - Delay: 1 minute
4. Actions Tab:
   - Start a program: `C:\Program Files\Mullvad VPN\Mullvad VPN.exe`
5. Conditions Tab:
   - Uncheck "Start only if on AC power"
6. Save

### Step 3: Enable Auto-Connect in Mullvad
- In Mullvad → VPN Settings → Enable "Auto-connect"

---

## Part 2: Advanced Fix (Auto-Disconnect Before Shutdown)

**Why?** Even with delayed start, if you restart/shutdown while VPN is connected, Bitdefender can still fail on next boot.

**Solution:** Run a background script that detects shutdown and disconnects Mullvad automatically.

---

## Installation Steps (Advanced Fix)
1. Create folder: `C:\Scripts`
2. Save `mullvad_starter.vbs`, `mullvad_monitor.ps1`, and `install.reg` inside
3. Double-click `install.reg` to add registry entry
4. Restart your computer
5. Check log: `C:\Scripts\mullvad_log.txt` for confirmation
6. Then shut down completely and start again !

---

## TL;DR
**Basic Fix:** Disable Mullvad autostart → Delay start by 1 minute via Task Scheduler → Enable Mullvad auto-connect.  
**Advanced Fix:** Add background monitor script that cleanly disconnects Mullvad before shutdown/restart/logoff.

---

**Tested on:**  
Windows 10/11 (Home & Pro)  
Mullvad VPN 2025.8  
Bitdefender Internet Security 2025

