function Show-Slides {
    <#
    .SYNOPSIS
        Displays a Markdown file as an interactive terminal presentation.

    .DESCRIPTION
        Converts a Markdown file into a live terminal-based presentation with rich
        formatting, colors, and ASCII art. Navigate through slides using arrow keys,
        space, or enter.

    .PARAMETER Path
        Path to the Markdown file containing the presentation.

    .PARAMETER Background
        Override the background color from the Markdown frontmatter.
        Accepts Spectre.Console.Color values (e.g., 'Black', 'DarkBlue', 'Grey15').

    .PARAMETER Foreground
        Override the foreground color from the Markdown frontmatter.
        Accepts Spectre.Console.Color values (e.g., 'White', 'Cyan1', 'Yellow').

    .PARAMETER Border
        Override the border color from the Markdown frontmatter.
        Accepts Spectre.Console.Color values (e.g., 'Blue', 'Magenta1', 'Green').

    .EXAMPLE
        Show-Slides -Path ./presentation.md

        Displays the presentation from the specified Markdown file.

    .EXAMPLE
        Show-Slides -Path ./presentation.md -Foreground Cyan1 -Background Black

        Displays the presentation with custom colors.

    .NOTES
        Requires PwshSpectreConsole module for terminal rendering.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path,

        [Parameter()]
        [Spectre.Console.Color]$Background,

        [Parameter()]
        [Spectre.Console.Color]$Foreground,

        [Parameter()]
        [Spectre.Console.Color]$Border
    )

    begin {
        Write-Verbose "Starting presentation from: $Path"
        
        # Ensure PwshSpectreConsole is loaded
        Import-SlidesDependency
    }

    process {
        try {
            # Parse the markdown file
            $presentation = ConvertFrom-SlideMarkdown -Path $Path
            Write-Verbose "Loaded $($presentation.Slides.Count) slides"

            # Apply parameter overrides to settings
            if ($PSBoundParameters.ContainsKey('Background')) {
                $presentation.Settings.background = $Background.ToString()
            }
            if ($PSBoundParameters.ContainsKey('Foreground')) {
                $presentation.Settings.foreground = $Foreground.ToString()
            }
            if ($PSBoundParameters.ContainsKey('Border')) {
                $presentation.Settings.border = $Border.ToString()
            }

            # Simple presentation loop - just show first slide for now (Phase 3-4)
            $currentSlide = 0

            while ($true) {
                $slide = $presentation.Slides[$currentSlide]
                
                # Detect slide type based on content
                if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Title slide: Only has # heading, no other content
                    Write-Verbose "Rendering title slide #$($slide.Number)"
                    Show-TitleSlide -Slide $slide -Settings $presentation.Settings
                }
                elseif ($slide.Content -match '^\s*##\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Section slide: Only has ## heading, no other content
                    Write-Verbose "Rendering section slide #$($slide.Number)"
                    Show-SectionSlide -Slide $slide -Settings $presentation.Settings
                }
                else {
                    # Content slide: May have ### heading or just content
                    Write-Verbose "Rendering content slide #$($slide.Number)"
                    Show-ContentSlide -Slide $slide -Settings $presentation.Settings
                }

                # Basic navigation: Press any key to exit
                Write-Host "`n`nPress any key to exit..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                break
            }

            Write-Verbose "Presentation ended"
        }
        catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'PresentationFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Path
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Show-Slides complete"
    }
}
