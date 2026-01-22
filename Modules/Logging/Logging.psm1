Set-StrictMode -Version Latest

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter()]
        [string]$Prefix = '[LANCommander]',

        [Parameter()]
        [ValidateSet('Info','Debug','Verbose','Warning','Error')]
        [string]$Level = 'Info'
    )

    $text = "$Prefix $Message"

    switch ($Level) {
        'Debug'   { Write-Debug $text }
        'Verbose' { Write-Verbose $text }
        'Warning' { Write-Warning $text }
        'Error'   { Write-Host $text -ForegroundColor Red }
        default   { Write-Information $text -InformationAction Continue }
    }
}

Export-ModuleMember -Function Write-Log
