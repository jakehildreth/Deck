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

            # Hide cursor during presentation (if supported)
            $originalCursorSize = $null
            try {
                $originalCursorSize = $Host.UI.RawUI.CursorSize
                $Host.UI.RawUI.CursorSize = 0
            }
            catch {
                Write-Verbose "Cursor hiding not supported on this platform"
            }

            try {
                # Full navigation loop (Phase 6)
                $currentSlide = 0
                $totalSlides = $presentation.Slides.Count
                $shouldExit = $false

                while ($true) {
                    # Clear screen for new slide
                Clear-Host

                $slide = $presentation.Slides[$currentSlide]
                
                # Detect slide type based on content
                if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Title slide: Only has # heading, no other content
                    Write-Verbose "Rendering title slide $($currentSlide + 1)/$totalSlides"
                    Show-TitleSlide -Slide $slide -Settings $presentation.Settings
                }
                elseif ($slide.Content -match '^\s*##\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Section slide: Only has ## heading, no other content
                    Write-Verbose "Rendering section slide $($currentSlide + 1)/$totalSlides"
                    Show-SectionSlide -Slide $slide -Settings $presentation.Settings
                }
                else {
                    # Content slide: May have ### heading or just content
                    Write-Verbose "Rendering content slide $($currentSlide + 1)/$totalSlides"
                    Show-ContentSlide -Slide $slide -Settings $presentation.Settings
                }

                # Show help hint on first slide only, positioned bottom-right
                if ($currentSlide -eq 0) {
                    $helpText = "press ? for help"
                    $windowWidth = $Host.UI.RawUI.WindowSize.Width
                    $windowHeight = $Host.UI.RawUI.WindowSize.Height
                    $cursorPos = $Host.UI.RawUI.CursorPosition
                    $cursorPos.X = $windowWidth - $helpText.Length - 1
                    $cursorPos.Y = $windowHeight - 1
                    $Host.UI.RawUI.CursorPosition = $cursorPos
                    Write-SpectreHost "[grey39]$helpText[/]"
                }

                # Get user input
                $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                $action = Get-SlideNavigation -KeyInfo $key

                # Handle help key
                if ($key.Character -eq '?') {
                    Clear-Host
                    Write-Host "`n  Navigation Controls`n" -ForegroundColor Cyan
                    Write-Host "  Forward:  " -ForegroundColor Gray -NoNewline
                    Write-Host "Right, Down, Space, Enter, n, Page Down" -ForegroundColor White
                    Write-Host "  Backward: " -ForegroundColor Gray -NoNewline
                    Write-Host "Left, Up, Backspace, p, Page Up" -ForegroundColor White
                    Write-Host "  Exit:     " -ForegroundColor Gray -NoNewline
                    Write-Host "Esc, Ctrl+C" -ForegroundColor White
                    Write-Host "`n  Press any key to return to presentation..." -ForegroundColor DarkGray
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                    continue
                }

                # Handle navigation
                switch ($action) {
                    'Next' {
                        if ($currentSlide -lt $totalSlides - 1) {
                            $currentSlide++
                            Write-Verbose "Advanced to slide $($currentSlide + 1)"
                        }
                        else {
                            # On last slide, trying to go forward shows end screen
                            Clear-Host
                            
                            # Center text vertically and horizontally
                            $windowHeight = $Host.UI.RawUI.WindowSize.Height
                            $windowWidth = $Host.UI.RawUI.WindowSize.Width
                            
                            $line1 = "End of Slides"
                            $line2 = "Press ESC to Exit"
                            
                            # Calculate vertical position (center)
                            $verticalPadding = [math]::Floor($windowHeight / 2) - 1
                            
                            # Print vertical padding
                            Write-Host ("`n" * $verticalPadding) -NoNewline
                            
                            # Print first line centered
                            $padding1 = [math]::Max(0, [math]::Floor(($windowWidth - $line1.Length) / 2))
                            Write-Host (" " * $padding1) -NoNewline
                            Write-Host $line1 -ForegroundColor White
                            
                            # Blank line between
                            Write-Host ""
                            
                            # Print second line centered
                            $padding2 = [math]::Max(0, [math]::Floor(($windowWidth - $line2.Length) / 2))
                            Write-Host (" " * $padding2) -NoNewline
                            Write-Host $line2 -ForegroundColor Gray
                            
                            # Wait for ESC or backward navigation
                            do {
                                $exitKey = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                                $exitAction = Get-SlideNavigation -KeyInfo $exitKey
                                
                                if ($exitAction -eq 'Previous') {
                                    # Go back to last slide
                                    Write-Verbose "Returning to last slide from end screen"
                                    break
                                }
                            } while ($exitKey.VirtualKeyCode -ne 27)  # 27 = ESC
                            
                            # If ESC was pressed, exit; if backward nav, continue loop
                            if ($exitKey.VirtualKeyCode -eq 27) {
                                Write-Verbose "User exited from end screen"
                                $shouldExit = $true
                                break
                            }
                        }
                    }
                    'Previous' {
                        if ($currentSlide -gt 0) {
                            $currentSlide--
                            Write-Verbose "Moved back to slide $($currentSlide + 1)"
                        }
                    }
                    'Exit' {
                        Write-Verbose "User requested exit"
                        $shouldExit = $true
                        break
                    }
                    'None' {
                        # Unhandled key, ignore
                        Write-Verbose "Unhandled key: $($key.Key)"
                    }
                }

                # Check if we should exit
                if ($shouldExit) {
                    break
                }
            }

            Write-Verbose "Presentation ended"
            }
            finally {
                # Restore cursor visibility (if it was hidden)
                if ($null -ne $originalCursorSize) {
                    try {
                        $Host.UI.RawUI.CursorSize = $originalCursorSize
                    }
                    catch {
                        Write-Verbose "Could not restore cursor size"
                    }
                }
            }
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
