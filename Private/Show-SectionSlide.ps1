function Show-SectionSlide {
    <#
    .SYNOPSIS
        Renders a section slide with medium figlet text.

    .DESCRIPTION
        Displays a full-screen section slide containing a ## heading rendered as medium
        figlet text. Section slides are centered and use the configured sectionFont setting.

    .PARAMETER Slide
        The slide object containing the content to render.

    .PARAMETER Settings
        The presentation settings hashtable containing colors, fonts, and styling options.

    .EXAMPLE
        Show-SectionSlide -Slide $slideObject -Settings $settings

    .NOTES
        Section slides should contain only a single ## heading with no other content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
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

            # Get colors and styles from settings
            $figletColor = Get-SpectreColorFromSettings -ColorName $Settings.foreground -SettingName 'Figlet'
            $borderInfo = Get-BorderStyleFromSettings -Settings $Settings

            # Create figlet text object with small font if available
            $smallFontPath = Join-Path $PSScriptRoot '../Fonts/small.flf'
            $figlet = New-FigletText -Text $sectionText -FontPath $smallFontPath -Color $figletColor -Justification Center

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
