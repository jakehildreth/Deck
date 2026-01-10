function Show-TitleSlide {
    <#
    .SYNOPSIS
        Renders a title slide with large figlet text.

    .DESCRIPTION
        Displays a full-screen title slide containing a # heading rendered as large
        figlet text. Title slides are centered and use the configured titleFont setting.

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
        [switch]$IsFirstSlide
    )

    begin {
        Write-Verbose "Rendering title slide #$($Slide.Number)"
    }

    process {
        try {
            # Extract the # heading text
            if ($Slide.Content -match '^#\s+(.+)$') {
                $titleText = $Matches[1].Trim()
                Write-Verbose "  Title: $titleText"
            }
            else {
                throw "Title slide does not contain a valid # heading"
            }

            # Clear the screen
            Clear-Host

            # Convert colors to Spectre.Console.Color
            $figletColor = $null
            if ($Settings.foreground) {
                $colorName = (Get-Culture).TextInfo.ToTitleCase($Settings.foreground.ToLower())
                Write-Verbose "  Figlet color: $colorName"
                try {
                    $figletColor = [Spectre.Console.Color]::$colorName
                }
                catch {
                    Write-Warning "Invalid color '$($Settings.foreground)', using default"
                }
            }

            $borderColor = $null
            if ($Settings.border) {
                $borderColorName = (Get-Culture).TextInfo.ToTitleCase($Settings.border.ToLower())
                Write-Verbose "  Border color: $borderColorName"
                try {
                    $borderColor = [Spectre.Console.Color]::$borderColorName
                }
                catch {
                    Write-Warning "Invalid border color '$($Settings.border)', using default"
                }
            }

            # Determine border style
            $borderStyle = 'Rounded'
            if ($Settings.borderStyle) {
                $borderStyle = (Get-Culture).TextInfo.ToTitleCase($Settings.borderStyle.ToLower())
                Write-Verbose "  Border style: $borderStyle"
            }

            # Create figlet text object
            $figlet = [Spectre.Console.FigletText]::new($titleText)
            $figlet.Justification = [Spectre.Console.Justify]::Center
            if ($figletColor) {
                $figlet.Color = $figletColor
            }

            # Create panel with internal padding calculated to fill terminal height
            # Account for Out-SpectreHost adding a trailing newline
            $windowHeight = $Host.UI.RawUI.WindowSize.Height - 2
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            
            # Measure actual figlet height
            $figletSize = Get-SpectreRenderableSize -Renderable $figlet -ContainerWidth $windowWidth
            $actualFigletHeight = $figletSize.Height
            
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualFigletHeight - $borderHeight
            $topPadding = [math]::Max(0, [math]::Floor($remainingSpace / 2))
            $bottomPadding = [math]::Max(0, $remainingSpace - $topPadding)
            
            $panel = [Spectre.Console.Panel]::new($figlet)
            $panel.Expand = $true
            $panel.Padding = [Spectre.Console.Padding]::new(4, $topPadding, 4, $bottomPadding)
            
            # Add border style
            if ($borderStyle) {
                $panel.Border = [Spectre.Console.BoxBorder]::$borderStyle
            }
            
            # Add border color
            if ($borderColor) {
                $panel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
            }
            
            # Add help text title for first slide
            if ($IsFirstSlide) {
                $panel.Header = [Spectre.Console.PanelHeader]::new("[grey39]press ? for help[/]")
            }
            
            # Render panel
            Out-SpectreHost $panel
        }
        catch {
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
