function Show-TitleSlide {
    <#
    .SYNOPSIS
        Renders a title slide with large figlet text.

    .DESCRIPTION
        Displays a full-screen title slide containing a # heading rendered as large
        figlet text. Title slides are centered and use the configured h1 font setting
        (also accepts aliases: titleFont, h1Font).

    .PARAMETER Slide
        The slide object containing the content to render.

    .PARAMETER Settings
        The presentation settings hashtable containing colors, fonts, and styling options.

    .EXAMPLE
        Show-TitleSlide -Slide $slideObject -Settings $settings

    .NOTES
        Title slides should contain only a single # heading with no other content.
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

            # Get colors and styles from settings
            $figletColor = Get-SpectreColorFromSettings -ColorName $Settings.foreground -SettingName 'Figlet'
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
