function Mount-Overlay {
    [CmdletBinding(SupportsShouldProcess = $true, PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MountPoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$LowerDir,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UpperDir,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkDir,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Source = "overlay",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$FileSystemType = "overlay",

        [Parameter()]
        [switch]$CreateDirectories,

        [Parameter()]
        [switch]$RequireEmptyWorkDir,

        [Parameter()]
        [switch]$RequireSameFilesystem,

        [Parameter()]
        [switch]$ReadOnly,

        [Parameter()]
        [ValidatePattern('^(0[0-7]{1,3}|[0-7]{1,3})$')]
        [string]$Umask,

        # In PowerShell, keep these as non-nullable and track "was it bound?"
        [Parameter()]
        [uint32]$Uid,

        [Parameter()]
        [uint32]$Gid,

        [Parameter()]
        [switch]$NoAtime,

        [Parameter()]
        [switch]$Relatime,

        # Nullable[bool] is not consistently preserved; accept [object] and validate.
        [Parameter()]
        [object]$Suid,

        [Parameter()]
        [object]$Dev,

        [Parameter()]
        [object]$Exec,

        [Parameter()]
        [string[]]$OverlayOption,

        [Parameter()]
        [string[]]$MountOption,

        [Parameter()]
        [string[]]$MountExtraArg,

        [Parameter()]
        [switch]$PassThru
    )

    Set-StrictMode -Version Latest

    function Join-OverlayLower {
        param([string[]]$Dirs)

        if ($Dirs.Count -eq 1 -and $Dirs[0] -match ':') {
            return $Dirs[0]
        }

        return ($Dirs | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() }) -join ':'
    }

    function Ensure-Dir {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }

    function Test-DirEmpty {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) { return $true }
        $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop
        return ($items.Count -eq 0)
    }

    function Get-DeviceId {
        param([string]$Path)
        $stat = Get-Command stat -ErrorAction SilentlyContinue
        if (-not $stat) { return $null }
        $out = & $stat --format=%d -- $Path 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return $out.Trim()
    }

    function Add-BoolMountOpt {
        param(
            [System.Collections.Generic.List[string]]$List,
            [object]$Value,
            [string]$TrueOpt,
            [string]$FalseOpt
        )

        if ($null -eq $Value) { return }

        # Allow: -Suid:$false (comes in as boolean False), or strings "true"/"false"
        $b = $null
        if ($Value -is [bool]) {
            $b = [bool]$Value
        }
        elseif ($Value -is [string]) {
            if ($Value.Trim() -match '^(true|false)$') { $b = [bool]::Parse($Value.Trim()) }
            else { throw "Invalid boolean value '$Value'. Expected true/false." }
        }
        else {
            throw "Invalid boolean value type '$($Value.GetType().FullName)'. Expected a boolean or 'true'/'false'."
        }

        $List.Add( $(if ($b) { $TrueOpt } else { $FalseOpt }) ) | Out-Null
    }

    $lower = Join-OverlayLower -Dirs $LowerDir

    if ($CreateDirectories) {
        Ensure-Dir -Path $MountPoint
        Ensure-Dir -Path $UpperDir
        Ensure-Dir -Path $WorkDir
    }

    if (-not (Test-Path -LiteralPath $MountPoint)) { throw "MountPoint does not exist: $MountPoint" }
    if (-not (Test-Path -LiteralPath $UpperDir))   { throw "UpperDir does not exist: $UpperDir" }
    if (-not (Test-Path -LiteralPath $WorkDir))    { throw "WorkDir does not exist: $WorkDir" }

    foreach ($ld in ($lower -split ':' | Where-Object { $_ })) {
        if (-not (Test-Path -LiteralPath $ld)) { throw "LowerDir does not exist: $ld" }
    }

    if ($RequireEmptyWorkDir) {
        if (-not (Test-DirEmpty -Path $WorkDir)) {
            throw "WorkDir must be empty for OverlayFS: $WorkDir"
        }
    }

    if ($RequireSameFilesystem) {
        $upperDev = Get-DeviceId -Path $UpperDir
        $workDev  = Get-DeviceId -Path $WorkDir

        if ($null -eq $upperDev -or $null -eq $workDev) {
            Write-Verbose "Could not determine device IDs via 'stat'; skipping filesystem equality check."
        }
        elseif ($upperDev -ne $workDev) {
            throw "UpperDir and WorkDir must be on the same filesystem/device. UpperDir(dev=$upperDev) WorkDir(dev=$workDev)"
        }
    }

    # Build -o options
    $opts = New-Object System.Collections.Generic.List[string]
    $opts.Add("lowerdir=$lower") | Out-Null
    $opts.Add("upperdir=$UpperDir") | Out-Null
    $opts.Add("workdir=$WorkDir") | Out-Null

    if ($OverlayOption) {
        foreach ($o in $OverlayOption) {
            if ($o -and $o.Trim()) { $opts.Add($o.Trim()) | Out-Null }
        }
    }

    if ($ReadOnly) { $opts.Add("ro") | Out-Null }
    if ($NoAtime)  { $opts.Add("noatime") | Out-Null }
    if ($Relatime) { $opts.Add("relatime") | Out-Null }

    Add-BoolMountOpt -List $opts -Value $Suid -TrueOpt "suid" -FalseOpt "nosuid"
    Add-BoolMountOpt -List $opts -Value $Dev  -TrueOpt "dev"  -FalseOpt "nodev"
    Add-BoolMountOpt -List $opts -Value $Exec -TrueOpt "exec" -FalseOpt "noexec"

    if ($Umask) { $opts.Add("umask=$Umask") | Out-Null }

    # Only add uid/gid if the caller actually bound them (avoid default 0 surprises)
    if ($PSBoundParameters.ContainsKey('Uid')) { $opts.Add("uid=$Uid") | Out-Null }
    if ($PSBoundParameters.ContainsKey('Gid')) { $opts.Add("gid=$Gid") | Out-Null }

    if ($MountOption) {
        foreach ($o in $MountOption) {
            if ($o -and $o.Trim()) { $opts.Add($o.Trim()) | Out-Null }
        }
    }

    $optString = ($opts | Where-Object { $_ }) -join ','

    # Build args as a PowerShell string array (avoid List[string].AddRange binding issues)
    $args = @(
        "-t", $FileSystemType
    )
    if ($MountExtraArg) { $args += $MountExtraArg }
    $args += @(
        "-o", $optString,
        $Source,
        $MountPoint
    )

    if ($PassThru) {
        return [pscustomobject]@{
            Executable = "mount"
            Arguments  = $args
            Options    = $optString
            Source     = $Source
            Target     = $MountPoint
        }
    }

    if ($PSCmdlet.ShouldProcess($MountPoint, "Mount overlayfs")) {
        Write-Verbose ("Executing: mount {0}" -f ($args -join ' '))
        & mount @args
        if ($LASTEXITCODE -ne 0) {
            throw "mount failed with exit code $LASTEXITCODE (target: $MountPoint)"
        }
    }
}

Export-ModuleMember -Function Mount-Overlay