function Import-DeckDependency {
    <#
    .SYNOPSIS
        Imports PwshSpectreConsole module with automatic installation fallback.

    .DESCRIPTION
        Attempts to import the PwshSpectreConsole module. If not found, tries to install it
        using Install-PSResource. On failure, displays helpful ASCII art and installation
        instructions before terminating.

    .EXAMPLE
        Import-DeckDependency
        Attempts to load PwshSpectreConsole, installing if necessary.

    .OUTPUTS
        None. Terminates script on failure.

    .NOTES
        This function will exit the calling script if PwshSpectreConsole cannot be loaded.
    #>
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose 'Checking for PwshSpectreConsole module'
    }

    process {
        try {
            # Try to import the module
            Import-Module PwshSpectreConsole -ErrorAction Stop
            Write-Verbose 'PwshSpectreConsole loaded successfully'
        }
        catch {
            Write-Warning 'PwshSpectreConsole module not found. Attempting to install...'
            
            try {
                # Try to install using Install-PSResource (PSResourceGet)
                Install-PSResource -Name PwshSpectreConsole -Repository PSGallery -TrustRepository -ErrorAction Stop
                Import-Module PwshSpectreConsole -ErrorAction Stop
                Write-Verbose 'PwshSpectreConsole installed and loaded successfully'
            }
            catch {
                # Installation failed - show sad face and exit
                Show-SadFace
                
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('Failed to load PwshSpectreConsole module'),
                    'DependencyLoadFailure',
                    [System.Management.Automation.ErrorCategory]::NotInstalled,
                    'PwshSpectreConsole'
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
    }

    end {
        Write-Verbose 'Dependency check complete'
    }
}
