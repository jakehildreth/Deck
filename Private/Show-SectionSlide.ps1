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

            # Convert color name to Spectre.Console.Color
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

            # Center vertically - add padding to push content toward middle
            $windowHeight = $Host.UI.RawUI.WindowSize.Height
            $verticalPadding = [math]::Max(0, [math]::Floor($windowHeight / 3))
            Write-Host ("`n" * $verticalPadding) -NoNewline

            # Render the section using Spectre figlet with 'small' font (medium size, centered)
            $fontParams = @{
                Text = $sectionText
                Alignment = 'Center'
            }
            if ($figletColor) {
                $fontParams['Color'] = $figletColor
            }
            
            # Try to use small font, fall back to default if not available
            $smallFontPath = Join-Path $PSScriptRoot '../Fonts/small.flf'
            if (Test-Path $smallFontPath) {
                $fontParams['FigletFontPath'] = $smallFontPath
            }
            
            Write-SpectreFigletText @fontParams
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
