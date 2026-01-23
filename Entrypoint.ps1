#!/usr/bin/env pwsh
#Requires -Modules Logging
#Requires -Modules OverlayFS
#Requires -Modules Hooks
#Requires -Modules AptTools

Write-Log "Starting entry script..."

Write-Log "Setting up modules and hooks"

if (-not (Test-Path -Path $Env:USER_MODULES)) {
    New-Item -ItemType Directory -Path $Env:USER_MODULES | Out-Null
}

if (-not (Test-Path -Path $Env:USER_HOOKS)) {
    New-Item -ItemType Directory -Path $Env:USER_HOOKS | Out-Null
}

Copy-Item -Path "$Env:BASE_MODULES/*" -Destination "$Env:USER_MODULES" -Recurse -Force
Copy-Item -Path "$Env:BASE_HOOKS/*" -Destination "$Env:USER_HOOKS" -Recurse -Force

Invoke-Hook "PreInitialization"

Write-Log "Mounting OverlayFS"

if (-not (Test-Path -Path $Env:OVERLAY_DIR)) {
    New-Item -ItemType Directory -Path $Env:OVERLAY_DIR | Out-Null
}

if (-not (Test-Path -Path $Env:SERVER_DIR)) {
    New-Item -ItemType Directory -Path $Env:SERVER_DIR | Out-Null
}

if (-not (Test-Path -Path $Env:SERVER_ROOT)) {
    New-Item -ItemType Directory -Path $Env:SERVER_ROOT | Out-Null
}

if (Test-Path -Path $Env:WORK_DIR) {
    Write-Log "Removing existing work directory: $Env:WORK_DIR"
    Remove-Item -Path $Env:WORK_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path -Path $Env:WORK_DIR)) {
    New-Item -ItemType Directory -Path $Env:WORK_DIR | Out-Null
    Write-Log "Created work directory: $Env:WORK_DIR"
}

try {
    Mount-Overlay -MountPoint $Env:SERVER_ROOT -LowerDir $Env:SERVER_DIR -UpperDir $Env:OVERLAY_DIR -WorkDir $Env:WORK_DIR -RequireEmptyWorkDir
    Write-Log "OverlayFS mounted successfully"
} catch {
    Write-Log -Level Error "Failed to mount OverlayFS: $($_.Exception.Message)"
}

Invoke-Hook "PostInitialization"

Invoke-Hook "ServerStarted"

Set-Location $Env:SERVER_ROOT

Invoke-Expression $Env:START_CMD

Write-Log "Server has stopped"

Invoke-Hook "ServerStopped"