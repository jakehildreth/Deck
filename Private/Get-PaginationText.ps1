function Get-PaginationText {
    <#
    .SYNOPSIS
        Generates pagination text for slide numbers.

    .DESCRIPTION
        Creates formatted pagination text based on the current slide number, total
        slides, and configured pagination style. Supports multiple visual styles
        from minimal numeric display to progress bars and dot indicators.
        
        Pagination text appears in slide footers when pagination is enabled,
        providing visual feedback about presentation progress and position.

    .PARAMETER CurrentSlide
        The current slide number (1-based). Must be between 1 and TotalSlides.

    .PARAMETER TotalSlides
        The total number of slides in the presentation. Must be greater than 0.

    .PARAMETER Style
        The pagination style to use. Default: 'minimal'
        
        Valid values:
        - minimal: Just the slide number (e.g., "3")
        - fraction: Fraction format (e.g., "3/10")
        - text: Full text (e.g., "Slide 3 of 10")
        - progress: Progress bar (e.g., "████░░░░░░")
        - dots: Dot indicators (e.g., "○ ○ ● ○ ○")

    .PARAMETER Color
        Optional Spectre.Console.Color for the pagination text. If not specified,
        uses terminal default color.

    .EXAMPLE
        Get-PaginationText -CurrentSlide 3 -TotalSlides 10
        # Returns: "3"

        Minimal style (default) shows just the slide number.

    .EXAMPLE
        Get-PaginationText -CurrentSlide 5 -TotalSlides 20 -Style fraction
        # Returns: "5/20"

        Fraction style shows current/total format.

    .EXAMPLE
        Get-PaginationText -CurrentSlide 7 -TotalSlides 15 -Style text
        # Returns: "Slide 7 of 15"

        Text style provides full descriptive format.

    .EXAMPLE
        Get-PaginationText -CurrentSlide 3 -TotalSlides 10 -Style progress
        # Returns: "███░░░░░░░" (30% filled)

        Progress bar with 10 blocks, 3 filled (30% complete).

    .EXAMPLE
        Get-PaginationText -CurrentSlide 3 -TotalSlides 5 -Style dots
        # Returns: "○ ○ ● ○ ○"

        Dot indicators with current position highlighted.

    .EXAMPLE
        $color = [Spectre.Console.Color]::Cyan1
        Get-PaginationText -CurrentSlide 5 -TotalSlides 10 -Style minimal -Color $color
        # Returns: "[Cyan1]5[/]"

        Pagination text with color markup applied.

    .OUTPUTS
        System.String
        
        Returns formatted pagination text, optionally wrapped in Spectre Console
        color markup tags.

    .NOTES
        Style Details:
        
        minimal:
        - Format: "{CurrentSlide}"
        - Example: "5"
        - Most compact, ideal for minimalist presentations
        
        fraction:
        - Format: "{CurrentSlide}/{TotalSlides}"
        - Example: "5/10"
        - Shows progress at a glance
        
        text:
        - Format: "Slide {CurrentSlide} of {TotalSlides}"
        - Example: "Slide 5 of 10"
        - Most explicit, good for accessibility
        
        progress:
        - Format: 10-character bar with filled/empty blocks
        - Filled: █ (U+2588 Full Block)
        - Empty: ░ (U+2591 Light Shade)
        - Example: "█████░░░░░" (5/10 = 50%)
        - Visual progress indication
        
        dots:
        - Format: Dots for each slide, filled dot for current
        - Filled: ● (U+25CF Black Circle)
        - Empty: ○ (U+25CB White Circle)
        - Example: "○ ○ ● ○ ○" (slide 3 of 5)
        - Best for shorter presentations (<=20 slides)
        - Can become wide with many slides
        
        Color Application:
        - Applied to entire pagination text
        - Uses Spectre Console markup: [color]text[/]
        - Color must be valid Spectre.Console.Color
        
        Usage in Presentations:
        - Enabled via 'pagination: true' in frontmatter
        - Style set via 'paginationStyle: style' in frontmatter
        - Typically displayed in slide footer
        - Updated on each slide transition
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$CurrentSlide,

        [Parameter(Mandatory = $true)]
        [int]$TotalSlides,

        [Parameter(Mandatory = $false)]
        [ValidateSet('minimal', 'fraction', 'text', 'progress', 'dots')]
        [string]$Style = 'minimal',

        [Parameter(Mandatory = $false)]
        [Spectre.Console.Color]$Color
    )

    $paginationText = switch ($Style) {
        'minimal' {
            "$CurrentSlide"
        }
        'fraction' {
            "$CurrentSlide/$TotalSlides"
        }
        'text' {
            "Slide $CurrentSlide of $TotalSlides"
        }
        'progress' {
            $barLength = 10
            $filled = [math]::Floor(($CurrentSlide / $TotalSlides) * $barLength)
            $empty = $barLength - $filled
            $filledChar = [char]0x2588  # █
            $emptyChar = [char]0x2591   # ░
            "$($filledChar.ToString() * $filled)$($emptyChar.ToString() * $empty)"
        }
        'dots' {
            $dots = @()
            for ($i = 1; $i -le $TotalSlides; $i++) {
                if ($i -eq $CurrentSlide) {
                    $dots += [char]0x25CF  # ●
                } else {
                    $dots += [char]0x25CB  # ○
                }
            }
            $dots -join ' '
        }
        default {
            "$CurrentSlide"
        }
    }

    # Apply color if specified
    if ($Color) {
        $colorCode = [Spectre.Console.Color]::$($Color.ToString())
        $paginationText = "[$($colorCode)]$paginationText[/]"
    }

    return $paginationText
}
