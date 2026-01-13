function Get-PaginationText {
    <#
    .SYNOPSIS
        Generates pagination text for slide numbers.

    .DESCRIPTION
        Creates formatted pagination text based on the current slide, total slides,
        and the configured pagination style.

    .PARAMETER CurrentSlide
        The current slide number (1-based).

    .PARAMETER TotalSlides
        The total number of slides in the presentation.

    .PARAMETER Style
        The pagination style to use:
        - minimal: Just the slide number (e.g., "3")
        - fraction: Fraction format (e.g., "3/10")
        - text: Full text (e.g., "Slide 3 of 10")
        - progress: Progress bar (e.g., "████░░░░░░")
        - dots: Dot indicators (e.g., "○ ○ ● ○ ○")

    .PARAMETER Color
        Optional color for the pagination text.
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
