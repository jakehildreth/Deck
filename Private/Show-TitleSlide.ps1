function Show-TitleSlide {
    <#
    .SYNOPSIS
        Renders a title slide with large figlet text.

    .DESCRIPTION
        Displays a full-screen title slide containing a # heading rendered as large
        figlet text. Title slides are the opening slides of a presentation, designed
        to make a strong visual impact with large, centered text.
        
        The rendering process:
        1. Extracts # heading text from slide content
        2. Detects inline color tags for color override
        3. Loads font file from h1 setting (default: Spectre's built-in font)
        4. Creates centered figlet text with specified color
        5. Calculates padding to vertically center content
        6. Renders in bordered panel filling terminal height
        
        Title slides use the h1 font setting (also accepts aliases: titleFont, h1Font).
        Font files must be in .flf (FIGlet) format and located in the Fonts directory.
        
        Title slides should contain ONLY a # heading with no other content. Additional
        content will not be displayed.

    .PARAMETER Slide
        The slide object containing a # heading. Must match pattern: ^#\s+(.+)$

    .PARAMETER Settings
        The presentation settings hashtable containing:
        - foreground: Default text color
        - background: Slide background color
        - border: Border color
        - borderStyle: Border style
        - h1: Font name for # headings (default: built-in Spectre font)
        - h1Color: Optional color override for # headings

    .PARAMETER IsFirstSlide
        Switch indicating this is the first slide in the presentation.
        Reserved for potential future features (e.g., logo display).

    .PARAMETER CurrentSlide
        The current slide number for pagination display.

    .PARAMETER TotalSlides
        The total number of slides in the presentation for pagination.

    .EXAMPLE
        Show-TitleSlide -Slide $slideObject -Settings $settings

        Renders a title slide with large centered figlet text.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 1
            Content = '# Welcome to Deck'
        }
        $settings = @{ h1 = 'default'; foreground = 'Cyan1'; border = 'Blue' }
        Show-TitleSlide -Slide $slide -Settings $settings -IsFirstSlide

        Renders the first slide of a presentation with default font and cyan text.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 1
            Content = '# <magenta>PowerShell Rocks!</magenta>'
        }
        Show-TitleSlide -Slide $slide -Settings $settings

        Renders a title slide with inline color override (magenta text).

    .EXAMPLE
        $settings = @{ h1 = 'small'; h1Color = 'Yellow'; border = 'Green' }
        Show-TitleSlide -Slide $slide -Settings $settings

        Renders a title slide using the 'small' font file and yellow color from settings.

    .OUTPUTS
        None. Renders directly to the terminal console using PwshSpectreConsole.

    .NOTES
        Font Configuration:
        - h1 setting specifies font name without .flf extension
        - Fonts loaded from ../Fonts/ directory relative to script
        - 'default' uses Spectre.Console's built-in font
        - Custom fonts must be valid FIGlet (.flf) format
        
        Font Aliases:
        - h1, titleFont, h1Font all map to the same setting
        - Normalized by ConvertFrom-DeckMarkdown during parsing
        
        Color Priority:
        - Inline tags: <color>text</color> or <span style="color:name">text</span>
        - h1Color setting in frontmatter
        - foreground setting as fallback
        
        Content Rules:
        - MUST contain exactly one # heading
        - NO additional content after heading
        - Use ## for section slides instead
        - Use ### for content slides with headers
        
        Visual Design:
        - Content vertically centered in panel
        - Figlet text horizontally centered
        - Panel fills entire terminal height
        - Border color from settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter()]
        [switch]$IsFirstSlide,

        [Parameter(Mandatory = $false)]
        [int]$CurrentSlide = 1,

        [Parameter(Mandatory = $false)]
        [int]$TotalSlides = 1
    )

    process {
        try {
            # Extract the # heading text
            if ($Slide.Content -match '^#\s+(.+)$') {
                $titleText = $Matches[1].Trim()
                Write-Verbose "  Title: $titleText"
            } else {
                throw "Title slide does not contain a valid # heading"
            }

            # Check for color tags in heading text and extract color
            $headingColor = $null
            if ($titleText -match '<(\w+)>.*?</\1>') {
                $headingColor = $Matches[1]
                Write-Verbose "  Extracted color from tag: $headingColor"
            } elseif ($titleText -match "<span\s+style=['""]color:(\w+)['""]>.*?</span>") {
                $headingColor = $Matches[1]
                Write-Verbose "  Extracted color from span: $headingColor"
            }
            
            # Strip HTML tags from title text
            $titleText = $titleText -replace "<span\s+style=['""]color:\w+['""]>(.*?)</span>", '$1'
            $titleText = $titleText -replace '<(\w+)>(.*?)</\1>', '$2'

            # Get colors and styles from settings
            $colorName = if ($headingColor) { 
                $headingColor 
            } elseif ($Settings.h1Color) { 
                $Settings.h1Color 
            } else { 
                $Settings.foreground 
            }
            $figletColor = Get-SpectreColorFromSettings -ColorName $colorName -SettingName 'Figlet'
            $borderInfo = Get-BorderStyleFromSettings -Settings $Settings

            # Create figlet text object with optional font from settings
            $figletParams = @{
                Text = $titleText
                Color = $figletColor
                Justification = 'Center'
            }
            if ($Settings.h1 -and $Settings.h1 -ne 'default') {
                $fontPath = if (Test-Path $Settings.h1) {
                    $Settings.h1
                } else {
                    Join-Path $PSScriptRoot "../Fonts/$($Settings.h1).flf"
                }
                Write-Verbose "  h1 font setting: $($Settings.h1)"
                Write-Verbose "  Constructed font path: $fontPath"
                Write-Verbose "  Font file exists: $(Test-Path $fontPath)"
                if (Test-Path $fontPath) {
                    $figletParams['FontPath'] = $fontPath
                    Write-Verbose "  Using h1 font: $($Settings.h1)"
                } else {
                    Write-Warning "Font file not found: $fontPath"
                }
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
            
            # Add help text header for first slide, otherwise pagination
            if ($IsFirstSlide) {
                $panel.Header = [Spectre.Console.PanelHeader]::new("[grey39]press ? for help[/]")
            } elseif ($Settings.pagination -eq $true) {
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
                'TitleSlideRenderFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Slide
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Title slide rendered"
    }
}
