#!/usr/bin/env pwsh
#Requires -Modules Logging
#Requires -Modules OverlayFS
#Requires -Modules Hooks
#Requires -Modules AptTools

Write-Log "Starting entry script..."

Invoke-Hook "PreInitialization"

Write-Log "Mounting OverlayFS"
Mount-Overlay -MountPoint $Env:SERVER_ROOT -LowerDir $Env:SERVER_DIR -UpperDir $Env:OVERLAY_DIR -WorkDir $Env:WORK_DIR

Invoke-Hook "PostInitialization"