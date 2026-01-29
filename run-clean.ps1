# Run Flutter with clean logs (filters out OnePlus system spam)
# Usage: .\run-clean.ps1

Write-Host "Starting Flutter with filtered logs..." -ForegroundColor Green

# Start Flutter in background
$flutterJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    flutter run
}

# Wait a bit for app to start
Start-Sleep -Seconds 3

# Get the PID of your app
$appPid = adb shell pidof -s de.unitune.unitune

if ($appPid) {
    Write-Host "App PID: $appPid" -ForegroundColor Cyan
    Write-Host "Showing only app logs (filtered)..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
    
    # Show only logs from your app, filter out noise
    adb logcat --pid=$appPid | Select-String -Pattern "(PowerHal|ScrollIdentify|DynamicFramerate|ViewRootImpl|AutofillManager|OplusView|IJankManager|ExtensionsLoader|ProfileInstaller|OplusInputMethod|OplusScrollToTop|LibMBrain|GrallocExtra|BLASTBufferQueue|SurfaceView|SurfaceControl|InsetsController|ImeTracker)" -NotMatch
} else {
    Write-Host "Could not find app PID. Showing all Flutter logs..." -ForegroundColor Yellow
    Receive-Job -Job $flutterJob -Wait
}

# Cleanup
Stop-Job -Job $flutterJob
Remove-Job -Job $flutterJob
