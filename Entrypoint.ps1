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

# Setup nginx if enabled
if ($Env:HTTP_FILESERVER_ENABLED -eq "true" -or $Env:HTTP_FILESERVER_ENABLED -eq "1") {
    Write-Log "HTTP fileserver is enabled, setting up web server..."
    
    # Ensure web root directory exists
    if (-not (Test-Path -Path $Env:HTTP_FILESERVER_WEB_ROOT)) {
        New-Item -ItemType Directory -Path $Env:HTTP_FILESERVER_WEB_ROOT -Force | Out-Null
        Write-Log "Created nginx web root directory: $Env:HTTP_FILESERVER_WEB_ROOT"
    }
    
    # Ensure nginx log directories exist
    $nginxLogDir = "/var/log/nginx"
    if (-not (Test-Path -Path $nginxLogDir)) {
        New-Item -ItemType Directory -Path $nginxLogDir -Force | Out-Null
    }
    
    # Generate nginx configuration from template
    $nginxConfigPath = "/etc/nginx/nginx.conf"
    $nginxConfigTemplate = Get-Content -Path "/usr/local/share/nginx.conf.template" -Raw -ErrorAction SilentlyContinue
    
    if ($nginxConfigTemplate) {
        $nginxConfig = $nginxConfigTemplate -replace '\{\{HTTP_FILESERVER_WEB_ROOT\}\}', $Env:HTTP_FILESERVER_WEB_ROOT
        Set-Content -Path $nginxConfigPath -Value $nginxConfig -NoNewline
        Write-Log "Generated nginx configuration with web root: $Env:HTTP_FILESERVER_WEB_ROOT"
    } else {
        Write-Log -Level Warning "Nginx config template not found, using default configuration"
    }
    
    # Test nginx configuration
    $nginxTest = & nginx -t 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Nginx configuration test passed"
        # Start nginx as daemon
        & nginx
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Nginx started successfully on port 80"
        } else {
            Write-Log -Level Error "Failed to start nginx"
        }
    } else {
        Write-Log -Level Error "Nginx configuration test failed: $nginxTest"
    }
} else {
    Write-Log "Nginx is disabled (HTTP_FILESERVER_ENABLED not set to 'true' or '1')"
}

Invoke-Hook "ServerStarted"

Set-Location $Env:SERVER_ROOT

$arguments = if ($env:START_ARGS) { [System.Management.Automation.PSParser]::Tokenize($env:START_ARGS, [ref]$null) |
                               Where-Object { $_.Type -eq 'CommandArgument' } |
                               ForEach-Object { $_.Content } } else { @() }

if (-not (Test-Path $Env:START_EXE))
{ 
    throw "START_EXE not found: $Env:START_EXE"
}

exec $Env:START_EXE $arguments

Write-Log "Server has stopped"

Invoke-Hook "ServerStopped"