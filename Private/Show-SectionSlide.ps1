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
            }
            else {
                throw "Section slide does not contain a valid ## heading"
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

            # Create figlet text object with small font if available
            $smallFontPath = Join-Path $PSScriptRoot '../Fonts/small.flf'
            if (Test-Path $smallFontPath) {
                $figlet = [Spectre.Console.FigletText]::new([Spectre.Console.FigletFont]::Load($smallFontPath), $sectionText)
            }
            else {
                $figlet = [Spectre.Console.FigletText]::new($sectionText)
            }
            $figlet.Justification = [Spectre.Console.Justify]::Center
            if ($figletColor) {
                $figlet.Color = $figletColor
            }

            # Create panel with border
            $panel = [Spectre.Console.Panel]::new($figlet)
            $panel.Expand = $true
            
            # Set border style
            try {
                $panel.Border = [Spectre.Console.BoxBorder]::$borderStyle
            }
            catch {
                Write-Warning "Invalid border style '$borderStyle', using Rounded"
                $panel.Border = [Spectre.Console.BoxBorder]::Rounded
            }
            
            # Set border color
            if ($borderColor) {
                $panel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
            }

            # Center vertically - add padding to push content toward middle
            $windowHeight = $Host.UI.RawUI.WindowSize.Height
            $verticalPadding = [math]::Max(0, [math]::Floor($windowHeight / 3))
            Write-Host ("`n" * $verticalPadding) -NoNewline

            # Render the panel
            [Spectre.Console.AnsiConsole]::Write($panel)
        }
        catch {
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
