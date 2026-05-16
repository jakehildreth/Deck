@{
    AliasesToExport=@()
    Author='Jake Hildreth'
    CmdletsToExport=@()
    CompanyName='Gilmour Technologies Ltd'
    CompatiblePSEditions=@('Core')
    Copyright='(c) 2026 - 2026 Jake Hildreth @ Gilmour Technologies Ltd. All rights reserved.'
    Description='Deck makes terminal presentations easy!'
    FunctionsToExport='Show-Deck'
    GUID='409fc543-77b9-48d6-87cc-8bee16c2a20d'
    ModuleVersion='2026.5.160848'
    PowerShellVersion='7.4'
    PrivateData=@{
        PSData=@{
            ExternalModuleDependencies=@('Microsoft.PowerShell.Utility',                'Microsoft.PowerShell.Archive',                'Microsoft.PowerShell.Management',                'Microsoft.PowerShell.Security')
            RequireLicenseAcceptance=$false
            Tags=@('Windows',                'MacOS',                'Linux')
        }
    }
    RequiredModules=@(@{
        Guid='fe78d2cb-2418-4308-9309-a0850e504cd6'
        ModuleName='TextMate'
        ModuleVersion='0.2.1'
    },        @{
        Guid='e4e0bda1-0703-44a5-b70d-8fe704cd0643'
        ModuleName='Microsoft.PowerShell.PSResourceGet'
        ModuleVersion='1.2.0'
    },        'Microsoft.PowerShell.Utility',        'Microsoft.PowerShell.Archive',        'Microsoft.PowerShell.Management',        'Microsoft.PowerShell.Security')
    RootModule='Deck.psm1'
}
