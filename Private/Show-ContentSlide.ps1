function Show-ContentSlide {
    <#
    .SYNOPSIS
        Renders a content slide with optional header and body text.

    .DESCRIPTION
        Displays a content slide that may contain a ### heading rendered as smaller
        figlet text followed by content. If no ### heading is present, only content is shown.

    .PARAMETER Slide
        The slide object containing the content to render.

    .PARAMETER Settings
        The presentation settings hashtable containing colors, fonts, and styling options.

    .EXAMPLE
        Show-ContentSlide -Slide $slideObject -Settings $settings

    .NOTES
        Content slides are the most common slide type for displaying information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    begin {
        Write-Verbose "Rendering content slide #$($Slide.Number)"
    }

    process {
        try {
            # Clear the screen
            Clear-Host

            # Check if slide has a ### header
            if ($Slide.Content -match '^###\s+(.+?)(?:\r?\n|$)') {
                $headerText = $Matches[1].Trim()
                Write-Verbose "  Header: $headerText"

                # Convert color name to Spectre.Console.Color
                $figletColor = $null
                if ($Settings.foreground) {
                    $colorName = (Get-Culture).TextInfo.ToTitleCase($Settings.foreground.ToLower())
                    Write-Verbose "  Header color: $colorName"
                    try {
                        $figletColor = [Spectre.Console.Color]::$colorName
                    }
                    catch {
                        Write-Warning "Invalid color '$($Settings.foreground)', using default"
                    }
                }

                # Render the header using Spectre figlet
                if ($figletColor) {
                    Write-SpectreFigletText -Text $headerText -Color $figletColor
                }
                else {
                    Write-SpectreFigletText -Text $headerText
                }

                # Extract content after header (everything after the ### line)
                $content = $Slide.Content -replace '^###\s+.+?(\r?\n|$)', ''
                $content = $content.Trim()
            }
            else {
                # No header, use all content
                $content = $Slide.Content.Trim()
            }

            # Render content if present
            if ($content) {
                Write-Verbose "  Content length: $($content.Length) characters"
                Write-Host "`n$content" -ForegroundColor $Settings.foreground
            }
        }
        catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'ContentSlideRenderFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Slide
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Content slide rendered"
    }
}
