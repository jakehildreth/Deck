function Import-DeckDependency {
    <#
    .SYNOPSIS
        Imports TextMate module (and its PwshSpectreConsole dependency) with automatic installation fallback.

    .DESCRIPTION
        Attempts to import the TextMate module required for syntax-highlighted code block rendering.
        TextMate transitively loads PwshSpectreConsole, so all Spectre types and cmdlets remain available.
        Implements a three-tier loading strategy:
        
        1. Try Import-Module (module already installed)
        2. Try Install-PSResource + Import-Module (auto-install from PSGallery)
        3. Show-SadFace + Terminate (installation failed, show help)
        
        This function ensures Deck presentations work out of the box by automatically
        handling the TextMate dependency without user intervention in most cases.
        
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
        # VERBOSE: Checking for TextMate module
        # VERBOSE: TextMate loaded successfully

        Verbose output shows loading progress.

    .OUTPUTS
        None. Loads module into session or terminates script on failure.

    .NOTES
        Dependency Requirements:
        - Module: TextMate (which transitively loads PwshSpectreConsole)
        - Repository: PSGallery (default PowerShell repository)
        - Required for: Syntax-highlighted code block rendering + all terminal rendering in Deck
        
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
        - TargetObject: 'TextMate'
        - Exception: Generic exception with message
        
        User Experience:
        - Success: Silent operation (unless -Verbose)
        - First run: Brief delay during auto-install
        - Failure: Friendly ASCII art + manual installation instructions
        
        Verbose Messages:
        - "Checking for TextMate module"
        - "TextMate loaded successfully"
        - "TextMate module not found. Attempting to install..."
        - "TextMate installed and loaded successfully"
        - "Dependency check complete"
        
        Warning Messages:
        - "TextMate module not found. Attempting to install..."
        
        Related Functions:
        - Show-SadFace: Called on installation failure
    #>
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose 'Checking for TextMate module'
    }

    process {
        # Check if module is already loaded in the current session
        $loadedModule = Get-Module -Name TextMate
        
        if ($loadedModule) {
            Write-Verbose 'TextMate is already loaded in the session'
            return
        }
        
        # Check if module is installed
        $module = Get-Module -ListAvailable -Name TextMate | Select-Object -First 1
        
        if (-not $module) {
            Write-Warning 'TextMate module not found. Attempting to install...'
            
            try {
                # Try to install using Install-PSResource (PSResourceGet)
                Install-PSResource -Name TextMate -Repository PSGallery -TrustRepository -ErrorAction Stop
                Write-Verbose 'TextMate installed successfully'
            } catch {
                # Installation failed - show sad face and exit
                Show-SadFace
                
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('Failed to install TextMate module'),
                    'DependencyInstallFailure',
                    [System.Management.Automation.ErrorCategory]::NotInstalled,
                    'TextMate'
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
        
        # Now import the module (it was installed but not loaded)
        try {
            Import-Module TextMate -ErrorAction Stop
            Write-Verbose 'TextMate loaded successfully'
        } catch {
            # Import failed even though module exists
            Show-SadFace
            
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Failed to import TextMate module. The module is installed but cannot be loaded.'),
                'DependencyImportFailure',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                'TextMate'
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose 'Dependency check complete'
    }
}
