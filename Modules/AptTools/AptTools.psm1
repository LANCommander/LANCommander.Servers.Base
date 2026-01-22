Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AptAvailable {
    [CmdletBinding()]
    param ()

    $apt = Get-Command apt-get -ErrorAction SilentlyContinue
    return $null -ne $apt
}

function Update-AptCache {
    [CmdletBinding()]
    param (
        [switch]$AssumeYes
    )

    if (-not (Test-AptAvailable)) {
        throw "apt-get is not available on this system."
    }

    $args = @('update')
    if ($AssumeYes) {
        $args += '-y'
    }

    Write-Verbose "Running: apt-get $($args -join ' ')"
    sudo apt-get @args
}

function Install-AptPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Name,

        [switch]$UpdateCache,

        [switch]$AssumeYes,

        [switch]$NoRecommends
    )

    if (-not (Test-AptAvailable)) {
        throw "apt-get is not available on this system."
    }

    if ($UpdateCache) {
        Update-AptCache -AssumeYes:$AssumeYes
    }

    $args = @('install')

    if ($AssumeYes) {
        $args += '-y'
    }

    if ($NoRecommends) {
        $args += '--no-install-recommends'
    }

    $args += $Name

    Write-Verbose "Running: apt-get $($args -join ' ')"
    sudo apt-get @args
}

Export-ModuleMember -Function *-Apt*
