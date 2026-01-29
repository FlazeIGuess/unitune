#!/bin/bash
# Filter out noisy Android system logs
# Usage: ./filter-logs.sh

adb logcat | grep -v -E "(PowerHalMgrImpl|ScrollIdentify|DynamicFramerate|ViewRootImpl|AutofillManager|OplusViewDragTouchViewHelper)"
