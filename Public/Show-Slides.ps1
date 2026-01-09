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
        Accepts named colors or hex values (e.g., 'black', '#1a1a1a').

    .PARAMETER Foreground
        Override the foreground color from the Markdown frontmatter.
        Accepts named colors or hex values (e.g., 'white', '#FFFFFF').

    .PARAMETER Border
        Override the border color from the Markdown frontmatter.
        Accepts named colors or hex values (e.g., 'magenta', '#FF00FF').

    .EXAMPLE
        Show-Slides -Path ./presentation.md

        Displays the presentation from the specified Markdown file.

    .EXAMPLE
        Show-Slides -Path ./presentation.md -Foreground cyan -Background black

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
        [string]$Background,

        [Parameter()]
        [string]$Foreground,

        [Parameter()]
        [string]$Border
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
                $presentation.Settings.background = $Background
            }
            if ($PSBoundParameters.ContainsKey('Foreground')) {
                $presentation.Settings.foreground = $Foreground
            }
            if ($PSBoundParameters.ContainsKey('Border')) {
                $presentation.Settings.border = $Border
            }

            # Simple presentation loop - just show first slide for now (Phase 3)
            $currentSlide = 0

            while ($true) {
                $slide = $presentation.Slides[$currentSlide]
                
                # Detect slide type based on content
                if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Title slide: Only has # heading
                    Write-Verbose "Rendering title slide #$($slide.Number)"
                    Show-TitleSlide -Slide $slide -Settings $presentation.Settings
                }
                else {
                    # For now, just display raw content (will implement other types in later phases)
                    Clear-Host
                    Write-Host $slide.Content -ForegroundColor $presentation.Settings.foreground
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
