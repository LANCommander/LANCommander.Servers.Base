@{
    RootModule        = 'AptTools.psm1'
    ModuleVersion     = '1.0.0'
    CompatiblePSEditions = @('Core')
    PowerShellVersion = '7.0'

    Description       = 'Simple PowerShell helpers for installing packages via apt'
    Author            = 'Pat Hartl'
    CompanyName       = 'LANCommander'
    Copyright         = '(c) LANCommander'

    FunctionsToExport = @(
        'Install-AptPackage',
        'Update-AptCache',
        'Test-AptAvailable'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
