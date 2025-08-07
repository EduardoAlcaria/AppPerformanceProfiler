$package = "com.youappid.app"
$logFile = "performance_log.txt"
$logBuffer = New-Object System.Collections.Generic.List[string]

Write-Host "`n[INFO] Checking ADB and device..."


$deviceCheck = & adb get-state 2>&1
if ($deviceCheck -ne "device") {
    Write-Host "[ERROR] No device found or USB debugging not authorized."
    exit 1
}


$packageCheck = & adb shell pm list packages | Select-String $package
if (-not $packageCheck) {
    Write-Host "[ERROR] Package '$package' not found on device. The app is not installed or you did not change the $package"
    exit 1
}

Write-Host "[INFO] Monitoring $package"
Write-Host "[INFO] Press Ctrl + C to stop and save the log to $logFile`n"

$null = Register-ObjectEvent -InputObject ([Console]) -EventName "CancelKeyPress" -Action {
    Write-Host "`n[INFO] Ctrl+C detected. Saving log..."
    $global:logBuffer | Out-File -FilePath $global:logFile -Encoding UTF8
    Write-Host "[INFO] Log saved to $global:logFile"
    [Environment]::Exit(0)
}


$global:logBuffer = $logBuffer
$global:logFile = $logFile

try {
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "`n========== $timestamp ==========" -ForegroundColor Cyan
        $logEntry = @()
        $logEntry += "`n========== $timestamp =========="
        
        
        Write-Host "`n[CPU USAGE]" -ForegroundColor Yellow
        try {
            $cpu = & adb shell top -n 1 -b
            $cpu_filtered = $cpu | Where-Object { $_ -match $package }
            if ($cpu_filtered) {
                $cpu_filtered | ForEach-Object { 
                    if ($_ -match '\s+(\d+\.\d+)%\s+(\d+\.\d+)%') {
                        $cpuPercent = $matches[1]
                        Write-Host "  CPU: $cpuPercent%" -ForegroundColor Green
                    }
                    Write-Host "  $_"
                }
                $logEntry += "[CPU USAGE]"
                $cpu_filtered | ForEach-Object { $logEntry += $_ }
            } else {
                Write-Host "  No CPU data found for package" -ForegroundColor Red
                $logEntry += "[CPU USAGE] - No data found"
            }
        } catch {
            Write-Host "  [ERROR] Failed to get CPU data: $($_.Exception.Message)" -ForegroundColor Red
            $logEntry += "[CPU USAGE] - Error: $($_.Exception.Message)"
        }
        
       
        Write-Host "`n[MEMORY USAGE]" -ForegroundColor Yellow
        try {
            $memory = & adb shell dumpsys meminfo $package | Select-String -Pattern "TOTAL|Native Heap|Dalvik Heap|TOTAL PSS"
            if ($memory) {
                $memory | ForEach-Object { 
                    Write-Host "  $_" -ForegroundColor Green
                }
                $logEntry += "`n[MEMORY USAGE]"
                $memory | ForEach-Object { $logEntry += $_.ToString() }
            } else {
                Write-Host "  No memory data available" -ForegroundColor Red
                $logEntry += "`n[MEMORY USAGE] - No data available"
            }
        } catch {
            Write-Host "  [ERROR] Failed to get memory data: $($_.Exception.Message)" -ForegroundColor Red
            $logEntry += "`n[MEMORY USAGE] - Error: $($_.Exception.Message)"
        }
        
       
        Write-Host "`n[BATTERY USAGE]" -ForegroundColor Yellow
        try {
            $battery = & adb shell dumpsys batterystats $package | Select-String -Pattern "Estimated power use|Uid|Total power|CPU|Wake"
            if ($battery) {
                $battery | Select-Object -First 10 | ForEach-Object { 
                    Write-Host "  $_" -ForegroundColor Green
                }
                $logEntry += "`n[BATTERY USAGE]"
                $battery | Select-Object -First 10 | ForEach-Object { $logEntry += $_.ToString() }
            } else {
                Write-Host "  No battery data available" -ForegroundColor Red
                $logEntry += "`n[BATTERY USAGE] - No data available"
            }
        } catch {
            Write-Host "  [ERROR] Failed to get battery data: $($_.Exception.Message)" -ForegroundColor Red
            $logEntry += "`n[BATTERY USAGE] - Error: $($_.Exception.Message)"
        }
        
        
        Write-Host "`n[FRAME STATS]" -ForegroundColor Yellow
        try {
            $fps = & adb shell dumpsys gfxinfo $package framestats | Select-String -Pattern "Total frames rendered|Janky frames|90th percentile|95th percentile|99th percentile"
            if ($fps) {
                $fps | ForEach-Object { 
                    Write-Host "  $_" -ForegroundColor Green
                }
                $logEntry += "`n[FRAME STATS]"
                $fps | ForEach-Object { $logEntry += $_.ToString() }
            } else {
                Write-Host "  No frame stats available" -ForegroundColor Red
                $logEntry += "`n[FRAME STATS] - No data available"
            }
        } catch {
            Write-Host "  [ERROR] Failed to get frame stats: $($_.Exception.Message)" -ForegroundColor Red
            $logEntry += "`n[FRAME STATS] - Error: $($_.Exception.Message)"
        }
        
        
        Write-Host "`n[NETWORK USAGE]" -ForegroundColor Yellow
        try {
            $network = & adb shell cat /proc/net/xt_qtaguid/stats | Select-String $package
            if ($network) {
                $network | Select-Object -First 5 | ForEach-Object { 
                    Write-Host "  $_" -ForegroundColor Green
                }
                $logEntry += "`n[NETWORK USAGE]"
                $network | Select-Object -First 5 | ForEach-Object { $logEntry += $_.ToString() }
            } else {
                Write-Host "  No network data available" -ForegroundColor Red
                $logEntry += "`n[NETWORK USAGE] - No data available"
            }
        } catch {
            Write-Host "  [ERROR] Failed to get network data: $($_.Exception.Message)" -ForegroundColor Red
            $logEntry += "`n[NETWORK USAGE] - Error: $($_.Exception.Message)"
        }
        
        
        Write-Host "`n[SUMMARY] Data collected at $timestamp" -ForegroundColor Magenta
        $logEntry += "`n[SUMMARY] Data collected at $timestamp"
        
        
        foreach ($entry in $logEntry) {
            $logBuffer.Add($entry.ToString())
        }
        
        Write-Host "`nWaiting 10 seconds... (Press Ctrl+C to stop)" -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
}
catch [System.OperationCanceledException] {
    Write-Host "`n[INFO] Operation cancelled. Saving log..."
    $logBuffer | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host "[INFO] Log saved to $logFile"
}
catch {
    Write-Host "`n[INFO] Script interrupted. Saving log..."
    Write-Host "[DEBUG] Error: $($_.Exception.Message)"
    $logBuffer | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host "[INFO] Log saved to $logFile"
}