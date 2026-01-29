# PowerShell script to filter out noisy Android system logs
# Usage: .\filter-logs.ps1

adb logcat | Select-String -Pattern "(PowerHalMgrImpl|ScrollIdentify|DynamicFramerate|ViewRootImpl|AutofillManager|OplusViewDragTouchViewHelper)" -NotMatch
