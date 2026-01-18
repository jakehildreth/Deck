function Get-SpectreColorFromSettings {
    <#
    .SYNOPSIS
        Converts a color name from settings to a Spectre.Console.Color object.

    .DESCRIPTION
        Resolves color name strings from presentation settings into Spectre.Console.Color
        enum values. Handles case-insensitive matching, validation, and fallback behavior.
        
        Color names are normalized to TitleCase to match Spectre.Console.Color enum
        format (e.g., 'cyan' → 'Cyan', 'magenta1' → 'Magenta1'). Invalid color names
        trigger a warning and return $null for graceful degradation.
        
        This defensive approach ensures presentations continue even with typos or
        invalid color configurations.

    .PARAMETER ColorName
        The color name from settings (e.g., 'cyan', 'Magenta1', 'BLUE').
        Can be $null or empty, which returns $null.

    .PARAMETER SettingName
        The name of the setting for error/warning messages (e.g., 'border', 'foreground').
        Provides context when warning about invalid colors.

    .EXAMPLE
        $color = Get-SpectreColorFromSettings -ColorName 'cyan' -SettingName 'border'
        # Returns: [Spectre.Console.Color]::Cyan

        Standard usage with valid lowercase color name.

    .EXAMPLE
        $color = Get-SpectreColorFromSettings -ColorName 'Magenta1' -SettingName 'h1Color'
        # Returns: [Spectre.Console.Color]::Magenta1

        Color names with numbers are supported (Spectre's extended palette).

    .EXAMPLE
        $color = Get-SpectreColorFromSettings -ColorName 'InvalidColor' -SettingName 'foreground'
        # Outputs warning: "Invalid foreground color 'InvalidColor', using default"
        # Returns: $null

        Invalid color names trigger warning and return null for fallback handling.

    .EXAMPLE
        $color = Get-SpectreColorFromSettings -ColorName $null -SettingName 'background'
        # Returns: $null (no warning)

        Null or empty color names return null silently.

    .EXAMPLE
        $settings = @{ foreground = 'CYAN'; background = 'black' }
        $fgColor = Get-SpectreColorFromSettings -ColorName $settings.foreground -SettingName 'foreground'
        $bgColor = Get-SpectreColorFromSettings -ColorName $settings.background -SettingName 'background'
        # Both succeed despite different casing

        Demonstrates case-insensitive color resolution.

    .OUTPUTS
        Spectre.Console.Color or $null
        
        Returns a Spectre.Console.Color enum value if valid, otherwise $null.

    .NOTES
        Supported Colors:
        Spectre.Console supports a wide palette including:
        - Basic colors: Black, White, Red, Green, Blue, Yellow, Aqua, Fuchsia, Grey, 
          Lime, Maroon, Navy, Olive, Purple, Silver, Teal, Violet
        - Mapped colors: Cyan → Cyan1, Magenta → Magenta1 (plain versions don't exist)
        - Extended: Grey0-Grey100, Red1-Red3, Green1-Green4, Blue1-Blue3, etc.
        - Dark variants: DarkRed, DarkGreen, DarkBlue, DarkCyan, DarkMagenta, etc.
        - Named: CornflowerBlue, DeepPink, HotPink, IndianRed, LightCoral, etc.
        
        Color Mapping:
        Cyan and Magenta are special cases - Spectre.Console doesn't have plain "Cyan" 
        or "Magenta", only numbered variants (Cyan1-3, Magenta1-3) and Dark variants.
        These are automatically mapped to their brightest numbered equivalents with
        verbose logging showing the mapping.
        
        Case Handling:
        - Input: Any case (cyan, CYAN, Cyan)
        - Normalized: TitleCase (Cyan)
        - Matching: Case-sensitive against Spectre.Console.Color enum
        
        Error Handling:
        - Null/empty input: Returns $null silently
        - Invalid name: Writes warning, returns $null
        - Caller should provide fallback color when $null returned
        
        Verbose Output:
        - Logs normalized color name when verbose enabled
        - Format: "  {SettingName} color: {NormalizedName}"
        
        Common Usage Pattern:
        ```powershell
        $color = Get-SpectreColorFromSettings -ColorName $Settings.border -SettingName 'border'
        if ($color) {
            $panel.BorderStyle = [Spectre.Console.Style]::new($color)
        } else {
            # Use default color
            $panel.BorderStyle = [Spectre.Console.Style]::new([Spectre.Console.Color]::White)
        }
        ```
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$ColorName,

        [Parameter(Mandatory = $true)]
        [string]$SettingName
    )

    if (-not $ColorName) {
        return $null
    }

    $titleCaseName = (Get-Culture).TextInfo.ToTitleCase($ColorName.ToLower())
    
    # Map common color names that don't exist in Spectre.Console to closest equivalents
    # Only Cyan and Magenta need mapping - most basic colors (Red, Green, Blue, Yellow, etc.) exist natively
    $colorMap = @{
        'Magenta' = 'Magenta1'
        'Cyan'    = 'Cyan1'
    }
    
    if ($colorMap.ContainsKey($titleCaseName)) {
        $mappedName = $colorMap[$titleCaseName]
        Write-Verbose "  $SettingName color: $titleCaseName → $mappedName (mapped)"
        $titleCaseName = $mappedName
    } else {
        Write-Verbose "  $SettingName color: $titleCaseName"
    }
    
    try {
        return [Spectre.Console.Color]::$titleCaseName
    } catch {
        Write-Warning "Invalid $SettingName color '$ColorName', using default"
        return $null
    }
}
