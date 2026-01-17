function Import-DeckDependency {
    <#
    .SYNOPSIS
        Imports PwshSpectreConsole module with automatic installation fallback.

    .DESCRIPTION
        Attempts to import the PwshSpectreConsole module required for terminal rendering.
        Implements a three-tier loading strategy:
        
        1. Try Import-Module (module already installed)
        2. Try Install-PSResource + Import-Module (auto-install from PSGallery)
        3. Show-SadFace + Terminate (installation failed, show help)
        
        This function ensures Deck presentations work out of the box by automatically
        handling the PwshSpectreConsole dependency without user intervention in most cases.
        
        On failure, displays friendly ASCII art and manual installation instructions before
        terminating the script with a proper error record.

    .EXAMPLE
        Import-DeckDependency
        # Module already installed: Loads successfully
        # Module missing: Attempts install, then loads
        # Install fails: Shows help and exits

        Standard usage at the beginning of Show-Deck function.

    .EXAMPLE
        Import-DeckDependency -Verbose
        # VERBOSE: Checking for PwshSpectreConsole module
        # VERBOSE: PwshSpectreConsole loaded successfully

        Verbose output shows loading progress.

    .OUTPUTS
        None. Loads module into session or terminates script on failure.

    .NOTES
        Dependency Requirements:
        - Module: PwshSpectreConsole
        - Repository: PSGallery (default PowerShell repository)
        - Required for: All terminal rendering in Deck
        
        Installation Methods:
        - Primary: Install-PSResource (PSResourceGet module, PowerShell 7.4+)
        - Fallback: Users can manually install with Install-Module (older systems)
        - TrustRepository: Uses -TrustRepository to avoid confirmation prompts
        
        Error Handling:
        - Import failure: Caught, proceeds to auto-install
        - Install failure: Caught, displays help, terminates
        - Termination: Uses $PSCmdlet.ThrowTerminatingError() for proper error record
        
        Error Record Details:
        - ErrorId: 'DependencyLoadFailure'
        - Category: NotInstalled
        - TargetObject: 'PwshSpectreConsole'
        - Exception: Generic exception with message
        
        User Experience:
        - Success: Silent operation (unless -Verbose)
        - First run: Brief delay during auto-install
        - Failure: Friendly ASCII art + manual installation instructions
        
        Verbose Messages:
        - "Checking for PwshSpectreConsole module"
        - "PwshSpectreConsole loaded successfully"
        - "PwshSpectreConsole module not found. Attempting to install..."
        - "PwshSpectreConsole installed and loaded successfully"
        - "Dependency check complete"
        
        Warning Messages:
        - "PwshSpectreConsole module not found. Attempting to install..."
        
        Related Functions:
        - Show-SadFace: Called on installation failure
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
        } catch {
            Write-Warning 'PwshSpectreConsole module not found. Attempting to install...'
            
            try {
                # Try to install using Install-PSResource (PSResourceGet)
                Install-PSResource -Name PwshSpectreConsole -Repository PSGallery -TrustRepository -ErrorAction Stop
                Import-Module PwshSpectreConsole -ErrorAction Stop
                Write-Verbose 'PwshSpectreConsole installed and loaded successfully'
            } catch {
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
