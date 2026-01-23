Set-StrictMode -Version Latest

#Requires -Modules Logging

function Invoke-Hook {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Hook,

        [Parameter(ParameterSetName = 'Filter')]
        [string] $Filter = '*.ps1'
    )

    $hookDirectory = "$Env:USER_HOOKS/$Hook"

    if (-not (Test-Path -Path $hookDirectory -PathType Container)) {
        Write-Log -Level Error "Hook directory does not exist: $hookDirectory"
        return
    }

    $scripts = @(Get-ChildItem -Path $hookDirectory -Filter $Filter -File -ErrorAction SilentlyContinue | Sort-Object -Property Name)

    if ($scripts.Count -eq 0) {
        return
    }

    foreach ($script in $scripts) {
        try {
            Write-Log "Executing hook script: $Hook/$($script.Name)"
            & $script.FullName
        }
        catch {
            Write-Log -Level Error $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Invoke-Hook