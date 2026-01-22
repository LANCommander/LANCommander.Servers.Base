@{
    RootModule        = 'Logging.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'c4b2e1c9-9a18-4b1e-9c9a-7e5e8f9a4b32'
    Author            = 'Pat Hartl'
    CompanyName       = 'LANCommander'
    Copyright         = '(c) LANCommander'
    Description       = 'Simple logging module with boolean level flags.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Write-Log')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('logging', 'diagnostics')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}