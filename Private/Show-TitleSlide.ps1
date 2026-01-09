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
        [hashtable]$Settings
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

            # Render the title using Spectre figlet
            # Note: PwshSpectreConsole's Write-SpectreFigletText handles centering automatically
            if ($figletColor) {
                Write-SpectreFigletText -Text $titleText -Color $figletColor
            }
            else {
                Write-SpectreFigletText -Text $titleText
            }
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
