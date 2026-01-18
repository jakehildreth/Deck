function Show-SadFace {
    <#
    .SYNOPSIS
        Displays sad ASCII art with installation instructions.

    .DESCRIPTION
        Shows a friendly sad face ASCII art along with clear, helpful instructions
        for manually installing PwshSpectreConsole. Called when automatic dependency
        loading fails in Import-DeckDependency.
        
        Uses Write-Host with colors for visual appeal since PwshSpectreConsole
        (the normal rendering engine) is unavailable at this point.
        
        Provides installation commands for both PSResourceGet (modern) and
        PowerShellGet v2 (legacy) to support different PowerShell versions.

    .EXAMPLE
        Show-SadFace
        
        Displays the sad face ASCII art and installation help to console.

    .OUTPUTS
        None. Writes directly to host console using Write-Host.

    .NOTES
        Display Components:
        - ASCII art sad face (red color)
        - "OH NO! Something went wrong!" header (yellow)
        - Explanation of the problem (white)
        - Primary installation command (green, for PSResourceGet)
        - Alternative installation command (green, for PowerShellGet v2)
        - Encouragement to try again (white)
        
        Color Scheme:
        - Red: ASCII art (sad face)
        - Yellow: Error header
        - White: Explanatory text
        - Cyan: Section headers
        - Green: Command examples
        
        Installation Commands:
        Primary (PSResourceGet):
        Install-PSResource -Name PwshSpectreConsole -Repository PSGallery
        
        Alternative (PowerShellGet v2):
        Install-Module -Name PwshSpectreConsole -Repository PSGallery
        
        Why Write-Host:
        - Cannot use PwshSpectreConsole (the module we're trying to install!)
        - Cannot use standard output streams (would interfere with error handling)
        - Write-Host ensures message displays regardless of redirections
        - Color support for better user experience
        
        Called By:
        - Import-DeckDependency on installation failure
        
        User Experience:
        - Friendly, non-threatening error message
        - Clear actionable steps
        - Multiple installation options for compatibility
        - Positive tone ("try running Deck again!")
        
        Terminal Compatibility:
        - Works in any PowerShell host (Windows PowerShell, PowerShell Core)
        - Color support detected automatically by Write-Host
        - Fallback to plain text if colors unsupported

    .LINK
        https://www.powershellgallery.com/packages/PwshSpectreConsole
    #>
    [CmdletBinding()]
    param()

    process {
        Write-Host ""
        Write-Host " ▄▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▄" -ForegroundColor Red
        Write-Host " █                █" -ForegroundColor Red
        Write-Host " █  ▀▄▀     ▀▄▀   █" -ForegroundColor Red
        Write-Host " █  ▀ ▀     ▀ ▀   █" -ForegroundColor Red
        Write-Host " █     ▀▄▄▀       █" -ForegroundColor Red
        Write-Host " █     ▄▄▄▄▄      █" -ForegroundColor Red
        Write-Host " █    ▀     ▀▀▄   █" -ForegroundColor Red
        Write-Host " ▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▀" -ForegroundColor Red
        Write-Host ""
        Write-Host "  OH NO! Something went wrong!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  The Deck module requires PwshSpectreConsole to run." -ForegroundColor White
        Write-Host "  Unfortunately, we couldn't install it automatically." -ForegroundColor White
        Write-Host ""
        Write-Host "  To fix this, please run:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    Install-PSResource -Name PwshSpectreConsole -Repository PSGallery" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Or if you're using PowerShellGet v2:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    Install-Module -Name PwshSpectreConsole -Repository PSGallery" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Then try running Deck again!" -ForegroundColor White
        Write-Host ""
    }
}
