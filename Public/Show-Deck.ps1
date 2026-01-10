function Show-Deck {
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
        Show-Deck -Path ./presentation.md

        Displays the presentation from the specified Markdown file.

    .EXAMPLE
        Show-Deck -Path ./presentation.md -Foreground Cyan1 -Background Black

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

            # Hide cursor during presentation using ANSI escape codes
            Write-Host "`e[?25l" -NoNewline  # Hide cursor

            try {
                # Full navigation loop (Phase 6)
                $currentSlide = 0
                $totalSlides = $presentation.Slides.Count
                $shouldExit = $false
                
                # Track visible bullets per slide
                $visibleBullets = @{}

                while ($true) {
                    # Move cursor to top-left and redraw (no clear to reduce flicker)
                    Write-Host "`e[H" -NoNewline

                $slide = $presentation.Slides[$currentSlide]
                
                # Initialize visible bullets for this slide if not set
                if (-not $visibleBullets.ContainsKey($currentSlide)) {
                    $visibleBullets[$currentSlide] = 0
                }
                
                # Detect slide type based on content
                if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Title slide: Only has # heading, no other content
                    Write-Verbose "Rendering title slide $($currentSlide + 1)/$totalSlides"
                    Show-TitleSlide -Slide $slide -Settings $presentation.Settings -IsFirstSlide:($currentSlide -eq 0)
                }
                elseif ($slide.Content -match '^\s*##\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Section slide: Only has ## heading, no other content
                    Write-Verbose "Rendering section slide $($currentSlide + 1)/$totalSlides"
                    Show-SectionSlide -Slide $slide -Settings $presentation.Settings
                }
                else {
                    # Content slide: May have ### heading or just content
                    Write-Verbose "Rendering content slide $($currentSlide + 1)/$totalSlides with $($visibleBullets[$currentSlide]) bullets"
                    Show-ContentSlide -Slide $slide -Settings $presentation.Settings -VisibleBullets $visibleBullets[$currentSlide]
                }

                # Get user input
                $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                $action = Get-SlideNavigation -KeyInfo $key

                # Handle help key
                if ($key.Character -eq '?') {
                    Write-Host "`e[H" -NoNewline
                    
                    # Fill screen with blank lines to clear previous content
                    $windowHeight = $Host.UI.RawUI.WindowSize.Height
                    $windowWidth = $Host.UI.RawUI.WindowSize.Width
                    for ($i = 0; $i -lt $windowHeight; $i++) {
                        Write-Host (" " * $windowWidth)
                    }
                    
                    # Move cursor back to top and render help text
                    Write-Host "`e[H" -NoNewline
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
                        # Check if current slide has hidden bullets
                        if ($slide.PSObject.Properties['TotalProgressiveBullets'] -and 
                            $visibleBullets[$currentSlide] -lt $slide.TotalProgressiveBullets) {
                            # Reveal next bullet
                            $visibleBullets[$currentSlide]++
                            Write-Verbose "Revealed bullet $($visibleBullets[$currentSlide])/$($slide.TotalProgressiveBullets)"
                        }
                        elseif ($currentSlide -lt $totalSlides - 1) {
                            # Move to next slide and reset bullets to 0
                            $currentSlide++
                            $visibleBullets[$currentSlide] = 0
                            Write-Verbose "Advanced to slide $($currentSlide + 1)"
                        }
                        else {
                            # On last slide, trying to go forward shows end screen
                            Write-Host "`e[H" -NoNewline
                            
                            # Center text vertically and horizontally
                            $windowHeight = $Host.UI.RawUI.WindowSize.Height
                            $windowWidth = $Host.UI.RawUI.WindowSize.Width
                            
                            $line1 = "End of Deck"
                            $line2 = "Press ESC to Exit"
                            
                            # Calculate vertical position (center)
                            $verticalPadding = [math]::Floor($windowHeight / 2) - 1
                            
                            # Fill screen with blank lines to clear previous content
                            for ($i = 0; $i -lt $windowHeight; $i++) {
                                Write-Host (" " * $windowWidth)
                            }
                            
                            # Move cursor back to top and render centered text
                            Write-Host "`e[H" -NoNewline
                            
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
                        # Check if current slide has revealed bullets that can be hidden
                        if ($slide.PSObject.Properties['TotalProgressiveBullets'] -and 
                            $visibleBullets[$currentSlide] -gt 0) {
                            # Hide last bullet
                            $visibleBullets[$currentSlide]--
                            Write-Verbose "Hid bullet, now showing $($visibleBullets[$currentSlide])/$($slide.TotalProgressiveBullets)"
                        }
                        elseif ($currentSlide -gt 0) {
                            # Move to previous slide and show all bullets
                            $currentSlide--
                            $prevSlide = $presentation.Slides[$currentSlide]
                            if ($prevSlide.PSObject.Properties['TotalProgressiveBullets']) {
                                $visibleBullets[$currentSlide] = $prevSlide.TotalProgressiveBullets
                            }
                            else {
                                $visibleBullets[$currentSlide] = 0
                            }
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
            
            # Show goodbye message
            Clear-Host
            $windowHeight = $Host.UI.RawUI.WindowSize.Height
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            $message = "Goodbye! <3"
            
            # Center vertically and horizontally
            $verticalPadding = [math]::Floor($windowHeight / 2)
            $horizontalPadding = [math]::Max(0, [math]::Floor(($windowWidth - $message.Length) / 2))
            
            Write-Host ("`n" * $verticalPadding) -NoNewline
            Write-Host (" " * $horizontalPadding) -NoNewline
            Write-Host $message -ForegroundColor Magenta
            
            Start-Sleep -Milliseconds 800
            Clear-Host
            }
            finally {
                # Show cursor again
                Write-Host "`e[?25h" -NoNewline  # Show cursor
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
        Write-Verbose "Show-Deck complete"
    }
}
