' Start PowerShell script invisibly (no window shown)
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\Scripts\mullvad_monitor.ps1""", 0, False
