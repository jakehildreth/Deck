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
    ModuleVersion='2026.1.10.1006'
    PowerShellVersion='7.4'
    PrivateData=@{
        PSData=@{
            ExternalModuleDependencies=@('Microsoft.PowerShell.Utility',                'Microsoft.PowerShell.Archive',                'Microsoft.PowerShell.Management',                'Microsoft.PowerShell.Security')
            RequireLicenseAcceptance=$false
            Tags=@('Windows',                'MacOS',                'Linux')
        }
    }
    RequiredModules=@(@{
        Guid='8c5ca00d-7f0f-4179-98bf-bdaebceaebc0'
        ModuleName='PwshSpectreConsole'
        ModuleVersion='2.2.0'
    },        @{
        Guid='e4e0bda1-0703-44a5-b70d-8fe704cd0643'
        ModuleName='Microsoft.PowerShell.PSResourceGet'
        ModuleVersion='1.1.1'
    },        'Microsoft.PowerShell.Utility',        'Microsoft.PowerShell.Archive',        'Microsoft.PowerShell.Management',        'Microsoft.PowerShell.Security')
    RootModule='Deck.psm1'
}
