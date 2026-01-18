@{
    AliasesToExport=@()
    Author='Jake Hildreth'
    CmdletsToExport=@()
    CompanyName='Gilmour Technologies Ltd'
    CompatiblePSEditions=@('Core')
    Copyright='(c) 2026 - 2026 Jake Hildreth @ Gilmour Technologies Ltd. All rights reserved.'
    Description='Deck makes terminal presentations easy!'
    FileList=@(
        'Deck.psd1'
        'Deck.psm1'
        'LICENSE'
        'README.MD'
        'CHANGELOG.MD'
        'Public/Show-Deck.ps1'
        'Private/ConvertFrom-DeckMarkdown.ps1'
        'Private/ConvertTo-CodeBlockSegments.ps1'
        'Private/ConvertTo-SpectreMarkup.ps1'
        'Private/Get-BorderStyleFromSettings.ps1'
        'Private/Get-PaginationText.ps1'
        'Private/Get-SlideNavigation.ps1'
        'Private/Get-SpectreColorFromSettings.ps1'
        'Private/Get-TerminalDimensions.ps1'
        'Private/Import-DeckDependency.ps1'
        'Private/New-FigletText.ps1'
        'Private/Show-ContentSlide.ps1'
        'Private/Show-ImageSlide.ps1'
        'Private/Show-Logo.ps1'
        'Private/Show-MultiColumnSlide.ps1'
        'Private/Show-SadFace.ps1'
        'Private/Show-SectionSlide.ps1'
        'Private/Show-TitleSlide.ps1'
        'Fonts/04B_03__.flf'
        'Fonts/04B_03B_.flf'
        'Fonts/04B_08__.flf'
        'Fonts/04B_09__.flf'
        'Fonts/04B_11__.flf'
        'Fonts/04B_19__.flf'
        'Fonts/04B_20__.flf'
        'Fonts/04B_21__.flf'
        'Fonts/04B_24__.flf'
        'Fonts/04B_25__.flf'
        'Fonts/5by5.flf'
        'Fonts/blocco.flf'
        'Fonts/Bytesized-Regular.flf'
        'Fonts/JacquardaBastarda9-Regular.flf'
        'Fonts/lisp-system-tools.flf'
        'Fonts/Micro5-Regular.flf'
        'Fonts/mini.flf'
        'Fonts/negative-quinpix.flf'
        'Fonts/PressStart2P.flf'
        'Fonts/Silkscreen.flf'
        'Fonts/Sixtyfour-Regular-VariableFont_BLED,SCAN.flf'
        'Fonts/small.flf'
        'Fonts/super-mario-brothers-3-all-stars.flf'
        'Fonts/Tiny5.flf'
        'Fonts/TinyUnicode.flf'
    )
    FunctionsToExport='Show-Deck'
    GUID='409fc543-77b9-48d6-87cc-8bee16c2a20d'
    ModuleVersion='2026.1.18.742'
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
