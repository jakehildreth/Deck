function Get-BorderStyleFromSettings {
    <#
    .SYNOPSIS
        Gets border color and style from settings.

    .DESCRIPTION
        Extracts and normalizes border configuration from presentation settings,
        returning a hashtable with Color and Style properties ready for application
        to Spectre.Console panels and borders.
        
        Converts color names from settings to Spectre.Console.Color objects and
        normalizes border style names to TitleCase for BoxBorder enum matching.
        Provides defensive defaults if settings are missing.

    .PARAMETER Settings
        The presentation settings hashtable containing optional 'border' (color name)
        and 'borderStyle' (style name) keys.

    .EXAMPLE
        $borderInfo = Get-BorderStyleFromSettings -Settings $Settings
        $panel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
        $panel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)

        Typical usage in slide renderers to configure panel borders.

    .EXAMPLE
        $settings = @{ border = 'Cyan1'; borderStyle = 'rounded' }
        $borderInfo = Get-BorderStyleFromSettings -Settings $settings
        # Returns: @{ Color = [Spectre.Console.Color]::Cyan1; Style = 'Rounded' }

        Demonstrates color object conversion and style name normalization.

    .EXAMPLE
        $settings = @{}  # Empty settings
        $borderInfo = Get-BorderStyleFromSettings -Settings $settings
        # Returns: @{ Color = $null; Style = 'Rounded' }

        Shows default behavior with missing settings.

    .OUTPUTS
        System.Collections.Hashtable
        
        Returns a hashtable with two keys:
        - Color: Spectre.Console.Color object or $null
        - Style: String matching BoxBorder enum (TitleCase)

    .NOTES
        Supported Border Styles:
        - Rounded: Smooth corners (╭───╮) - Default
        - Square: Sharp corners (┌───┐)
        - Double: Double lines (╔═══╗)
        - Heavy: Thick lines (┏━━━┓)
        - None: No border
        
        Style Normalization:
        - Input: 'rounded', 'ROUNDED', 'Rounded' all normalize to 'Rounded'
        - Required for matching Spectre.Console.BoxBorder enum values
        - Uses ToTitleCase() for consistent casing
        
        Color Handling:
        - Delegates to Get-SpectreColorFromSettings for color conversion
        - Returns $null if color not specified or invalid
        - Caller should handle $null by using default color
        
        Default Values:
        - Color: $null (caller provides default)
        - Style: 'Rounded'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    $result = @{
        Color = $null
        Style = 'Rounded'
    }

    # Get border color
    if ($Settings.border) {
        $result.Color = Get-SpectreColorFromSettings -ColorName $Settings.border -SettingName 'Border'
    }

    # Get border style
    if ($Settings.borderStyle) {
        $result.Style = (Get-Culture).TextInfo.ToTitleCase($Settings.borderStyle.ToLower())
        Write-Verbose "  Border style: $($result.Style)"
    }

    return $result
}
