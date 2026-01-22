@{
    RootModule        = 'Hooks.psm1'
    ModuleVersion     = '1.0.0'
    CompatiblePSEditions = @('Core')
    PowerShellVersion = '7.0'

    Description       = 'Module to handle script hooking'
    Author            = 'Pat Hartl'
    CompanyName       = 'LANCommander'
    Copyright         = '(c) LANCommander'

    FunctionsToExport = @('Invoke-Hook')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('plugins')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}