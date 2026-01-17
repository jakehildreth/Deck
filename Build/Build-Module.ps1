param (
    # A CalVer string if you need to manually override the default yyyy.M.d version string.
    [string]$CalVer,
    [switch]$PublishToPSGallery,
    [string]$PSGalleryAPIPath
)

if (Get-Module -Name 'PSPublishModule' -ListAvailable) {
    Write-Verbose 'PSPublishModule is installed.'
} else {
    Write-Verbose 'PSPublishModule is not installed. Attempting installation.'
    try {
        Install-Module -Name Pester -AllowClobber -Scope CurrentUser -SkipPublisherCheck -Force
        Install-Module -Name PSScriptAnalyzer -AllowClobber -Scope CurrentUser -Force
        Install-Module -Name PSPublishModule -AllowClobber -Scope CurrentUser -Force
    } catch {
        Write-Error "PSPublishModule installation failed. $_"
    }
}

Update-Module -Name PSPublishModule
Import-Module -Name PSPublishModule -Force

$CopyrightYear = if ($Calver) { $CalVer.Split('.')[0] } else { (Get-Date -Format yyyy) }

Build-Module -ModuleName 'Deck' {
    # Usual defaults as per standard module
    $Manifest = [ordered] @{
        ModuleVersion        = if ($Calver) { $CalVer } else { (Get-Date -Format yyyy.M.d.Hmm) }
        CompatiblePSEditions   = @('Core')
        GUID                   = '409fc543-77b9-48d6-87cc-8bee16c2a20d'
        Author                 = 'Jake Hildreth'
        CompanyName            = 'Gilmour Technologies Ltd'
        Copyright              = "(c) 2026 - $CopyrightYear Jake Hildreth @ Gilmour Technologies Ltd. All rights reserved."
        Description            = 'Deck makes terminal presentations easy!'
        PowerShellVersion      = '7.4'
        Tags                   = @('Windows', 'MacOS', 'Linux')
    }
    New-ConfigurationManifest @Manifest

    # Add standard module dependencies (directly, but can be used with loop as well)
    New-ConfigurationModule -Type RequiredModule -Name 'PwshSpectreConsole', 'Microsoft.PowerShell.PSResourceGet' -Guid 'Auto' -Version 'Latest'

    # Add external module dependencies, using loop for simplicity
    foreach ($Module in @('Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Archive', 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Security')) {
        New-ConfigurationModule -Type ExternalModule -Name $Module
    }

    # Add approved modules, that can be used as a dependency, but only when specific function from those modules is used
    # And on that time only that function and dependant functions will be copied over
    # Keep in mind it has it's limits when "copying" functions such as it should not depend on DLLs or other external files
    #New-ConfigurationModule -Type ApprovedModule -Name 'PSSharedGoods', 'PSWriteColor', 'Connectimo', 'PSUnifi', 'PSWebToolbox', 'PSMyPassword'

    #New-ConfigurationModuleSkip -IgnoreFunctionName 'Invoke-Formatter', 'Find-Module' -IgnoreModuleName 'platyPS'
    New-ConfigurationModuleSkip -IgnoreFunctionName 'Clear-Host', 'Get-TrueColorBg', 'Get-TrueColorFg' -IgnoreModuleName 'platyPS'

    $ConfigurationFormat = [ordered] @{
        RemoveComments                              = $false

        PlaceOpenBraceEnable                        = $true
        PlaceOpenBraceOnSameLine                    = $true
        PlaceOpenBraceNewLineAfter                  = $true
        PlaceOpenBraceIgnoreOneLineBlock            = $false

        PlaceCloseBraceEnable                       = $true
        PlaceCloseBraceNewLineAfter                 = $true
        PlaceCloseBraceIgnoreOneLineBlock           = $false
        PlaceCloseBraceNoEmptyLineBefore            = $true

        UseConsistentIndentationEnable              = $true
        UseConsistentIndentationKind                = 'space'
        UseConsistentIndentationPipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
        UseConsistentIndentationIndentationSize     = 4

        UseConsistentWhitespaceEnable               = $true
        UseConsistentWhitespaceCheckInnerBrace      = $true
        UseConsistentWhitespaceCheckOpenBrace       = $true
        UseConsistentWhitespaceCheckOpenParen       = $true
        UseConsistentWhitespaceCheckOperator        = $true
        UseConsistentWhitespaceCheckPipe            = $true
        UseConsistentWhitespaceCheckSeparator       = $true

        AlignAssignmentStatementEnable              = $true
        AlignAssignmentStatementCheckHashtable      = $true

        UseCorrectCasingEnable                      = $true
    }
    # Disabled all formatting due to PSScriptAnalyzer issues with custom attributes and line endings
    # Use 'Minimal' style for PSD1 generation (without formatting)
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1' -PSD1Style 'Minimal'

    # configuration for documentation, at the same time it enables documentation processing
    New-ConfigurationDocumentation -Enable:$false -StartClean -UpdateWhenNew -PathReadme 'Docs\Readme.md' -Path 'Docs'

    New-ConfigurationImportModule -ImportSelf -ImportRequiredModules

    New-ConfigurationBuild -Enable:$true -SignModule:$false -DeleteTargetModuleBeforeBuild -MergeModuleOnBuild -MergeFunctionsFromApprovedModules -DoNotAttemptToFixRelativePaths

    # global options for publishing to github/psgallery
    if($PublishToPSGallery) {
        if ($PSGalleryAPIKey) {
            # Use API key directly (from environment variable in CI)
            New-ConfigurationPublish -Type PowerShellGallery -ApiKey $PSGalleryAPIKey -Enabled:$true
        } elseif ($PSGalleryAPIPath) {
            # Use API key from file (for local development)
            New-ConfigurationPublish -Type PowerShellGallery -FilePath $PSGalleryAPIPath -Enabled:$true
        } else {
            Write-Error "PublishToPSGallery specified but neither PSGalleryAPIKey nor PSGalleryAPIPath provided."
        }
    }
}
