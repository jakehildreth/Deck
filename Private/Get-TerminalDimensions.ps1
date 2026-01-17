function Get-TerminalDimensions {
    <#
    .SYNOPSIS
        Gets the terminal window dimensions.

    .DESCRIPTION
        Retrieves the current terminal width and height from the PowerShell host,
        adjusting the height by -1 to provide a safe rendering area that prevents
        unwanted scrolling.
        
        The height adjustment accounts for the cursor line and prevents content from
        pushing past the visible terminal area, which would cause the display to scroll
        and break the slide presentation appearance.
        
        This is a critical function for slide renderers to calculate available space
        for content, figlet text, images, and panels.

    .EXAMPLE
        $dimensions = Get-TerminalDimensions
        $width = $dimensions.Width
        $height = $dimensions.Height
        Write-Host "Terminal: ${width}x${height}"

        Basic usage to get terminal dimensions.

    .EXAMPLE
        $dimensions = Get-TerminalDimensions
        $contentWidth = [math]::Floor($dimensions.Width * 0.8)
        $padding = ($dimensions.Width - $contentWidth) / 2
        # Use for centering content

        Calculate content width as percentage of terminal width.

    .EXAMPLE
        $dimensions = Get-TerminalDimensions
        if ($dimensions.Width -lt 80) {
            Write-Warning "Terminal width is less than recommended 80 columns"
        }
        if ($dimensions.Height -lt 24) {
            Write-Warning "Terminal height is less than recommended 24 rows"
        }

        Validate minimum terminal dimensions for presentation.

    .OUTPUTS
        System.Collections.Hashtable
        
        Returns a hashtable with two keys:
        - Width: Terminal width in columns (characters)
        - Height: Terminal height in rows (lines) minus 1 for safe rendering

    .NOTES
        Height Adjustment:
        - Raw height: $Host.UI.RawUI.WindowSize.Height
        - Returned height: Raw height - 1
        - Reason: Prevent scrolling when content fills screen
        - Critical for maintaining slide presentation appearance
        
        Width Considerations:
        - Typically 80-200+ columns depending on terminal size
        - Affects figlet text wrapping and layout
        - Multi-column slides divide width evenly
        - Image slides use 60/40 width split
        
        Usage in Slide Renderers:
        - Calculate available space for content
        - Determine figlet text wrapping
        - Size panels to fill terminal
        - Calculate padding for vertical centering
        - Split width for multi-column layouts
        
        Dynamic Resizing:
        - Dimensions are queried on each slide render
        - Supports terminal resize during presentation
        - No caching of dimensions
        
        Typical Terminal Sizes:
        - Default: 80x24
        - Modern: 120x30 or larger
        - Full HD: 238x58 (1920x1080 with typical font)
        - Minimum recommended: 80x24
        
        Related Functions:
        - All Show-*Slide functions call this for layout calculations
        - Used in -Strict validation mode
    #>
    [CmdletBinding()]
    param()

    return @{
        Width = $Host.UI.RawUI.WindowSize.Width
        Height = $Host.UI.RawUI.WindowSize.Height - 1
    }
}
