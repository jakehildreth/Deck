function Show-SectionSlide {
    <#
    .SYNOPSIS
        Renders a section slide with medium figlet text.

    .DESCRIPTION
        Displays a full-screen section slide containing a ## heading rendered as medium
        figlet text. Section slides serve as dividers between major parts of a presentation,
        creating visual breaks and organizing content into logical sections.
        
        The rendering process:
        1. Extracts ## heading text from slide content
        2. Detects inline color tags for color override
        3. Loads font file from h2 setting (default: 'small' font)
        4. Creates centered figlet text with specified color
        5. Calculates padding to vertically center content
        6. Renders in bordered panel filling terminal height
        
        Section slides use the h2 font setting (also accepts aliases: sectionFont, h2Font).
        The default h2 font is 'small', which is smaller than title slides but larger
        than content slide headers.
        
        Section slides should contain ONLY a ## heading with no other content. Additional
        content will not be displayed.

    .PARAMETER Slide
        The slide object containing a ## heading. Must match pattern: ^##\s+(.+)$

    .PARAMETER Settings
        The presentation settings hashtable containing:
        - foreground: Default text color
        - background: Slide background color
        - border: Border color
        - borderStyle: Border style
        - h2: Font name for ## headings (default: 'small')
        - h2Color: Optional color override for ## headings

    .PARAMETER CurrentSlide
        The current slide number for pagination display.

    .PARAMETER TotalSlides
        The total number of slides in the presentation for pagination.

    .EXAMPLE
        Show-SectionSlide -Slide $slideObject -Settings $settings

        Renders a section slide with medium centered figlet text.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 10
            Content = '## Implementation Details'
        }
        $settings = @{ h2 = 'small'; foreground = 'White'; border = 'Blue' }
        Show-SectionSlide -Slide $slide -Settings $settings

        Renders a section slide divider with default 'small' font.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 15
            Content = '## <cyan>Demo Time</cyan>'
        }
        Show-SectionSlide -Slide $slide -Settings $settings

        Renders a section slide with inline color override (cyan text).

    .EXAMPLE
        $settings = @{ h2 = 'mini'; h2Color = 'Green'; border = 'Green' }
        Show-SectionSlide -Slide $slide -Settings $settings

        Renders a section slide using 'mini' font and green color from settings.

    .OUTPUTS
        None. Renders directly to the terminal console using PwshSpectreConsole.

    .NOTES
        Font Configuration:
        - h2 setting specifies font name without .flf extension
        - Default h2 font is 'small' (medium-sized figlet text)
        - Fonts loaded from ../Fonts/ directory relative to script
        - Custom fonts must be valid FIGlet (.flf) format
        
        Font Aliases:
        - h2, sectionFont, h2Font all map to the same setting
        - Normalized by ConvertFrom-DeckMarkdown during parsing
        
        Color Priority:
        - Inline tags: <color>text</color> or <span style="color:name">text</span>
        - h2Color setting in frontmatter
        - foreground setting as fallback
        
        Content Rules:
        - MUST contain exactly one ## heading
        - NO additional content after heading
        - Use # for title slides instead
        - Use ### for content slides with headers
        
        Visual Design:
        - Content vertically centered in panel
        - Figlet text horizontally centered
        - Panel fills entire terminal height
        - Typically smaller than title slides but larger than content headers
        
        Usage Pattern:
        - Opening: Title slide (#)
        - Sections: Section slides (##) to divide major topics
        - Content: Content slides (###) for detailed information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $false)]
        [int]$CurrentSlide = 1,

        [Parameter(Mandatory = $false)]
        [int]$TotalSlides = 1
    )

    begin {
        Write-Verbose "Rendering section slide #$($Slide.Number)"
    }

    process {
        try {
            # Extract the ## heading text
            if ($Slide.Content -match '^##\s+(.+)$') {
                $sectionText = $Matches[1].Trim()
                Write-Verbose "  Section: $sectionText"
            } else {
                throw "Section slide does not contain a valid ## heading"
            }

            # Check for color tags in heading text and extract color
            $headingColor = $null
            if ($sectionText -match '<(\w+)>.*?</\1>') {
                $headingColor = $Matches[1]
                Write-Verbose "  Extracted color from tag: $headingColor"
            } elseif ($sectionText -match "<span\s+style=['""]color:(\w+)['""]>.*?</span>") {
                $headingColor = $Matches[1]
                Write-Verbose "  Extracted color from span: $headingColor"
            }
            
            # Strip HTML tags from section text
            $sectionText = $sectionText -replace "<span\s+style=['""]color:\w+['""]>(.*?)</span>", '$1'
            $sectionText = $sectionText -replace '<(\w+)>(.*?)</\1>', '$2'

            # Get colors and styles from settings
            $colorName = if ($headingColor) { 
                $headingColor 
            } elseif ($Settings.h2Color) { 
                $Settings.h2Color 
            } else { 
                $Settings.foreground 
            }
            $figletColor = Get-SpectreColorFromSettings -ColorName $colorName -SettingName 'Figlet'
            $borderInfo = Get-BorderStyleFromSettings -Settings $Settings

            # Create figlet text object with optional font from settings
            $figletParams = @{
                Text = $sectionText
                Color = $figletColor
                Justification = 'Center'
            }
            # Default to 'small' font if h2 is 'default', otherwise use specified font
            $fontName = if ($Settings.h2 -eq 'default') { 'small' } else { $Settings.h2 }
            $fontPath = if (Test-Path $fontName) {
                $fontName
            } else {
                Join-Path $PSScriptRoot "../Fonts/$fontName.flf"
            }
            if (Test-Path $fontPath) {
                $figletParams['FontPath'] = $fontPath
                Write-Verbose "  Using h2 font: $fontName"
            }
            $figlet = New-FigletText @figletParams

            # Create panel with internal padding calculated to fill terminal height
            # Account for rendering behavior to prevent scrolling
            $dimensions = Get-TerminalDimensions
            $windowHeight = $dimensions.Height
            $windowWidth = $dimensions.Width
            
            # Set panel to expand and measure what we need to fill
            $panel = [Spectre.Console.Panel]::new($figlet)
            $panel.Expand = $true
            
            # Add border style first
            if ($borderInfo.Style) {
                $panel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
            }
            
            # Measure figlet with horizontal padding already applied
            # Horizontal padding is 4 on each side = 8 total
            $contentWidth = $windowWidth - 8
            $figletSize = Get-SpectreRenderableSize -Renderable $figlet -ContainerWidth $contentWidth
            $actualFigletHeight = $figletSize.Height
            
            # Calculate vertical padding needed
            # Total height = border (2) + top padding + content + bottom padding
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualFigletHeight - $borderHeight
            $topPadding = [math]::Max(0, [math]::Ceiling($remainingSpace / 2.0))
            $bottomPadding = [math]::Max(0, $remainingSpace - $topPadding)
            
            $panel.Padding = [Spectre.Console.Padding]::new(4, $topPadding, 4, $bottomPadding)
            
            # Border style already added above
            if ($borderInfo.Style) {
                $panel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
            }
            
            # Add border color
            if ($borderInfo.Color) {
                $panel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
            }
            
            # Add pagination header if enabled
            if ($Settings.pagination -eq $true) {
                $paginationParams = @{
                    CurrentSlide = $CurrentSlide
                    TotalSlides = $TotalSlides
                    Style = $Settings.paginationStyle
                }
                if ($borderInfo.Color) {
                    $paginationParams['Color'] = $borderInfo.Color
                }
                $paginationText = Get-PaginationText @paginationParams
                $panel.Header = [Spectre.Console.PanelHeader]::new($paginationText)
                $panel.Header.Justification = [Spectre.Console.Justify]::Right
            }
            
            # Render panel
            Out-SpectreHost $panel
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'SectionSlideRenderFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Slide
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Section slide rendered"
    }
}
