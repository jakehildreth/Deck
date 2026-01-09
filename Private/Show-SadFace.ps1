function Show-SadFace {
    <#
    .SYNOPSIS
        Displays sad ASCII art with installation instructions.

    .DESCRIPTION
        Shows a sad face ASCII art along with helpful instructions for manually installing
        PwshSpectreConsole. Called when automatic dependency loading fails.

    .EXAMPLE
        Show-SadFace
        Displays the sad face and installation help.

    .OUTPUTS
        None. Writes directly to host.

    .NOTES
        This function cannot use PwshSpectreConsole since it's called when that module fails to load.
    #>
    [CmdletBinding()]
    param()

    process {
        Write-Host ""
        Write-Host "    ___________" -ForegroundColor Red
        Write-Host "   /           \" -ForegroundColor Red
        Write-Host "  /   O     O   \" -ForegroundColor Red
        Write-Host " |               |" -ForegroundColor Red
        Write-Host " |      ___      |" -ForegroundColor Red
        Write-Host " |     /   \     |" -ForegroundColor Red
        Write-Host "  \    \___/    /" -ForegroundColor Red
        Write-Host "   \___________/" -ForegroundColor Red
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
