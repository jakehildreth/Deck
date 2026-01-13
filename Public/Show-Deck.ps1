function Show-Deck {
    <#
    .SYNOPSIS
        Displays a Markdown file as an interactive terminal presentation.

    .DESCRIPTION
        Converts a Markdown file into a live terminal-based presentation with rich
        formatting, colors, and ASCII art. Navigate through slides using arrow keys,
        space, or enter.

    .PARAMETER Path
        Path or URL to the Markdown file containing the presentation.
        Supports both local file paths and web URLs (http/https).

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
        Show-Deck -Path https://example.com/presentation.md

        Displays the presentation from a web URL.

    .EXAMPLE
        Show-Deck -Path ./presentation.md -Foreground Cyan1 -Background Black

        Displays the presentation with custom colors.

    .NOTES
        Requires PwshSpectreConsole module for terminal rendering.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ 
            if ($_ -match '^https?://') {
                # Web URL - just validate format
                return $true
            } else {
                # Local path - validate file exists
                Test-Path $_ -PathType Leaf
            }
        })]
        [string]$Path,

        [Parameter()]
        [string]$Background,

        [Parameter()]
        [string]$Foreground,

        [Parameter()]
        [string]$Border,

        [Parameter()]
        [switch]$Strict
    )

    begin {
        Write-Verbose "Starting presentation from: $Path"
        
        Import-DeckDependency
    }

    process {
        try {
            # Handle web URLs by downloading to temp file
            $pathToLoad = $Path
            $tempFile = $null
            
            if ($Path -match '^https?://') {
                Write-Verbose "Downloading markdown from web URL: $Path"
                try {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    $tempFile = [System.IO.Path]::ChangeExtension($tempFile, '.md')
                    
                    $webClient = [System.Net.WebClient]::new()
                    $webClient.DownloadFile($Path, $tempFile)
                    $webClient.Dispose()
                    
                    $pathToLoad = $tempFile
                    Write-Verbose "Downloaded to temporary file: $tempFile"
                } catch {
                    if ($tempFile -and (Test-Path $tempFile)) {
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    }
                    throw "Failed to download markdown from URL: $_"
                }
            }
            
            $presentation = ConvertFrom-DeckMarkdown -Path $pathToLoad
            Write-Verbose "Loaded $($presentation.Slides.Count) slides"

            if ($PSBoundParameters.ContainsKey('Background')) {
                $presentation.Settings.background = $Background
            }
            if ($PSBoundParameters.ContainsKey('Foreground')) {
                $presentation.Settings.foreground = $Foreground
            }
            if ($PSBoundParameters.ContainsKey('Border')) {
                $presentation.Settings.border = $Border
            }

            # Pre-validate image slide content heights (only in Strict mode)
            if ($Strict) {
                $windowWidth = $Host.UI.RawUI.WindowSize.Width
                $windowHeight = $Host.UI.RawUI.WindowSize.Height - 1
                $contentWidth = [math]::Floor($windowWidth * 0.6)
                $validationErrors = [System.Collections.Generic.List[string]]::new()
                
                for ($i = 0; $i -lt $presentation.Slides.Count; $i++) {
                $slide = $presentation.Slides[$i]
                    $slideNum = $i + 1
                    
                    # Detect slide type and validate
                    if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                        # Title slide - validate figlet height
                        $titleMatch = [regex]::Match($slide.Content, '^\s*#\s+(.+?)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                        if ($titleMatch.Success) {
                            $titleText = $titleMatch.Groups[1].Value.Trim()
                            $smallFontPath = Join-Path $PSScriptRoot '../Fonts/small.flf'
                            if (Test-Path $smallFontPath) {
                                $font = [Spectre.Console.FigletFont]::Load($smallFontPath)
                                $figlet = [Spectre.Console.FigletText]::new($font, $titleText)
                            } else {
                                $figlet = [Spectre.Console.FigletText]::new($titleText)
                            }
                            $figlet.Justification = [Spectre.Console.Justify]::Center
                            
                            $testSize = Get-SpectreRenderableSize -Renderable $figlet -ContainerWidth $windowWidth
                            if ($testSize.Height -gt $windowHeight - 4) {
                                $validationErrors.Add("Slide #${slideNum} (Title): Content height ($($testSize.Height)) exceeds viewport height ($windowHeight)")
                            }
                        }
                    } elseif ($slide.Content -match '^\s*##\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                        # Section slide - validate figlet height
                        $sectionMatch = [regex]::Match($slide.Content, '^\s*##\s+(.+?)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
                        if ($sectionMatch.Success) {
                            $sectionText = $sectionMatch.Groups[1].Value.Trim()
                            $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                            if (Test-Path $miniFontPath) {
                                $font = [Spectre.Console.FigletFont]::Load($miniFontPath)
                                $figlet = [Spectre.Console.FigletText]::new($font, $sectionText)
                            } else {
                                $figlet = [Spectre.Console.FigletText]::new($sectionText)
                            }
                            $figlet.Justification = [Spectre.Console.Justify]::Center
                            
                            $testSize = Get-SpectreRenderableSize -Renderable $figlet -ContainerWidth $windowWidth
                            if ($testSize.Height -gt $windowHeight - 4) {
                                $validationErrors.Add("Slide #${slideNum} (Section): Content height ($($testSize.Height)) exceeds viewport height ($windowHeight)")
                            }
                        }
                    } elseif ($slide.Content -match '\|\|\|') {
                        # Multi-column slide - basic check (harder to validate precisely)
                        $columns = $slide.Content -split '\|\|\|'
                        foreach ($col in $columns) {
                            $convertedLines = ($col.Trim() -split "`r?`n") | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }
                            $testText = [Spectre.Console.Markup]::new(($convertedLines -join "`n"))
                            $testSize = Get-SpectreRenderableSize -Renderable $testText -ContainerWidth ([math]::Floor($windowWidth / $columns.Count))
                            if ($testSize.Height -gt $windowHeight - 4) {
                                $validationErrors.Add("Slide #${slideNum} (Multi-column): Column content exceeds viewport height ($windowHeight)")
                                break
                            }
                        }
                    } elseif ($slide.Content -match '!\[[^\]]*\]\([^)]+\)' -and ($slide.Content -replace '!\[[^\]]*\]\([^)]+\)(?:\{width=\d+\})?', '').Trim().Length -gt 0) {
                        # Image slide validation
                        $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
                        $imageMatch = [regex]::Match($slide.Content, $imagePattern)
                        $imagePath = $imageMatch.Groups[2].Value
                        
                        # Check if the image is inside a code fence (skip validation for example code)
                        $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
                        $isInCodeBlock = $false
                        foreach ($codeMatch in [regex]::Matches($slide.Content, $codeBlockPattern)) {
                            if ($imageMatch.Index -ge $codeMatch.Index -and $imageMatch.Index -lt ($codeMatch.Index + $codeMatch.Length)) {
                                $isInCodeBlock = $true
                                break
                            }
                        }
                        
                        # Check if image file exists (skip for web URLs and code examples)
                        if (-not $isInCodeBlock) {
                            $isWebUrl = $imagePath -match '^https?://'
                            if (-not $isWebUrl) {
                                $imagePathResolved = $imagePath
                                if (-not [System.IO.Path]::IsPathRooted($imagePath)) {
                                    $markdownDir = Split-Path -Parent $Path
                                    $imagePathResolved = Join-Path $markdownDir $imagePath
                                }
                                
                                if (-not (Test-Path $imagePathResolved)) {
                                    $validationErrors.Add("Slide #${slideNum} (Image): Image file not found: $imagePath")
                                }
                            }
                        }
                        
                        $textContent = $slide.Content.Remove($imageMatch.Index, $imageMatch.Length).Trim()
                        
                        $hasHeader = $textContent -match '^###\s+(.+?)(?:\r?\n|$)'
                        $headerText = if ($hasHeader) { $Matches[1].Trim() } else { $null }
                        $bodyContent = if ($hasHeader) { $textContent -replace '^###\s+.+?(\r?\n|$)', '' } else { $textContent }
                        $bodyContent = $bodyContent.Trim()
                        
                        if ($hasHeader -or $bodyContent) {
                            $testRenderables = [System.Collections.Generic.List[object]]::new()
                            
                            if ($hasHeader) {
                                $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                                if (Test-Path $miniFontPath) {
                                    $font = [Spectre.Console.FigletFont]::Load($miniFontPath)
                                    $testFiglet = [Spectre.Console.FigletText]::new($font, $headerText)
                                } else {
                                    $testFiglet = [Spectre.Console.FigletText]::new($headerText)
                                }
                                $testFiglet.Justification = [Spectre.Console.Justify]::Left
                                $testRenderables.Add($testFiglet)
                            }
                            
                            if ($bodyContent) {
                                $convertedLines = ($bodyContent -split "`r?`n") | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }
                                $testMarkup = [Spectre.Console.Markup]::new(($convertedLines -join "`n"))
                                $testRenderables.Add($testMarkup)
                            }
                            
                            $testRows = [Spectre.Console.Rows]::new([object[]]$testRenderables.ToArray())
                            $testPanel = [Spectre.Console.Panel]::new($testRows)
                            $testPanel.Padding = [Spectre.Console.Padding]::new(4, 1, 4, 1)
                            
                            $testSize = Get-SpectreRenderableSize -Renderable $testPanel -ContainerWidth $contentWidth
                            
                            if ($testSize.Height -gt $windowHeight) {
                                $validationErrors.Add("Slide #${slideNum} (Image): Content height ($($testSize.Height)) exceeds viewport height ($windowHeight)")
                            }
                        }
                    } else {
                        # Content slide validation
                        $testRenderables = [System.Collections.Generic.List[object]]::new()
                        
                        # Check for header
                        if ($slide.Content -match '^###\s+(.+?)(?:\r?\n|$)') {
                            $headerText = $Matches[1].Trim()
                            $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                            if (Test-Path $miniFontPath) {
                                $font = [Spectre.Console.FigletFont]::Load($miniFontPath)
                                $testFiglet = [Spectre.Console.FigletText]::new($font, $headerText)
                            } else {
                                $testFiglet = [Spectre.Console.FigletText]::new($headerText)
                            }
                            $testFiglet.Justification = [Spectre.Console.Justify]::Center
                            $testRenderables.Add($testFiglet)
                            
                            $bodyContent = $slide.Content -replace '^###\s+.+?(\r?\n|$)', ''
                        } else {
                            $bodyContent = $slide.Content
                        }
                        
                        if ($bodyContent.Trim()) {
                            $convertedLines = ($bodyContent.Trim() -split "`r?`n") | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }
                            $testMarkup = [Spectre.Console.Markup]::new(($convertedLines -join "`n"))
                            $testRenderables.Add($testMarkup)
                        }
                        
                        if ($testRenderables.Count -gt 0) {
                            $testRows = [Spectre.Console.Rows]::new([object[]]$testRenderables.ToArray())
                            $testPanel = [Spectre.Console.Panel]::new($testRows)
                            $testPanel.Padding = [Spectre.Console.Padding]::new(4, 1, 4, 1)
                            
                            $testSize = Get-SpectreRenderableSize -Renderable $testPanel -ContainerWidth $windowWidth
                            
                            if ($testSize.Height -gt $windowHeight) {
                                $validationErrors.Add("Slide #${slideNum} (Content): Content height ($($testSize.Height)) exceeds viewport height ($windowHeight)")
                            }
                        }
                    }
                }
                
                # If there are validation errors, fail with a detailed report
                if ($validationErrors.Count -gt 0) {
                    $errorReport = "Strict mode validation failed with $($validationErrors.Count) error(s):`n"
                    foreach ($error in $validationErrors) {
                        $errorReport += "  - $error`n"
                    }
                    $exception = [System.InvalidOperationException]::new($errorReport)
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        $exception,
                        'StrictModeValidationFailed',
                        [System.Management.Automation.ErrorCategory]::InvalidData,
                        $Path
                    )
                    $PSCmdlet.ThrowTerminatingError($errorRecord)
                }
            }

            Write-Host "`e[?25l" -NoNewline

            $currentSlide = 0
                $totalSlides = $presentation.Slides.Count
                $shouldExit = $false
                $visibleBullets = @{}
                $windowWidth = $Host.UI.RawUI.WindowSize.Width
                $windowHeight = $Host.UI.RawUI.WindowSize.Height - 1

                while ($true) {
                    # Clear screen by moving to top-left and drawing blank lines
                    Write-Host "`e[H" -NoNewline
                    for ($i = 0; $i -lt $windowHeight; $i++) {
                        Write-Host (' ' * $windowWidth)
                    }
                    Write-Host "`e[H" -NoNewline

                $slide = $presentation.Slides[$currentSlide]
                
                # Add source file path to slide for image resolution
                if (-not $slide.PSObject.Properties['SourceFile']) {
                    Add-Member -InputObject $slide -NotePropertyName 'SourceFile' -NotePropertyValue $presentation.SourcePath -Force
                }
                
                # Initialize visible bullets for this slide if not set
                if (-not $visibleBullets.ContainsKey($currentSlide)) {
                    $visibleBullets[$currentSlide] = 0
                }
                
                # Merge slide-specific overrides with presentation settings
                $slideSettings = $presentation.Settings.Clone()
                if ($slide.PSObject.Properties['Overrides'] -and $slide.Overrides) {
                    foreach ($key in $slide.Overrides.Keys) {
                        $slideSettings[$key] = $slide.Overrides[$key]
                        Write-Verbose "  Applied override: $key = $($slide.Overrides[$key])"
                    }
                }
                
                # Detect slide type based on content
                if ($slide.Content -match '^\s*#\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Title slide: Only has # heading, no other content
                    Write-Verbose "Rendering title slide $($currentSlide + 1)/$totalSlides"
                    Show-TitleSlide -Slide $slide -Settings $slideSettings -IsFirstSlide:($currentSlide -eq 0) -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                } elseif ($slide.Content -match '^\s*##\s+.+$' -and $slide.Content -notmatch '\n[^#]') {
                    # Section slide: Only has ## heading, no other content
                    Write-Verbose "Rendering section slide $($currentSlide + 1)/$totalSlides"
                    Show-SectionSlide -Slide $slide -Settings $slideSettings -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                } elseif ($slide.Content -match '\|\|\|') {
                    # Multi-column slide: Contains ||| delimiter
                    Write-Verbose "Rendering multi-column slide $($currentSlide + 1)/$totalSlides"
                    Show-MultiColumnSlide -Slide $slide -Settings $slideSettings -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                } elseif ($slide.Content -match '!\[[^\]]*\]\([^)]+\)' -and ($slide.Content -replace '!\[[^\]]*\]\([^)]+\)(?:\{width=\d+\})?', '').Trim().Length -gt 0) {
                    # Image slide: Contains an image AND has text content besides the image
                    # But first check if the image is inside a code block (skip if it's example code)
                    $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
                    $imageMatch = [regex]::Match($slide.Content, $imagePattern)
                    $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
                    $isInCodeBlock = $false
                    foreach ($codeMatch in [regex]::Matches($slide.Content, $codeBlockPattern)) {
                        if ($imageMatch.Index -ge $codeMatch.Index -and $imageMatch.Index -lt ($codeMatch.Index + $codeMatch.Length)) {
                            $isInCodeBlock = $true
                            break
                        }
                    }
                    
                    if ($isInCodeBlock) {
                        # Treat as content slide since image is just example code
                        Write-Verbose "Rendering content slide $($currentSlide + 1)/$totalSlides with $($visibleBullets[$currentSlide]) bullets"
                        Show-ContentSlide -Slide $slide -Settings $slideSettings -VisibleBullets $visibleBullets[$currentSlide] -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                    } else {
                        # Real image slide
                        Write-Verbose "Rendering image slide $($currentSlide + 1)/$totalSlides with $($visibleBullets[$currentSlide]) bullets"
                        Show-ImageSlide -Slide $slide -Settings $slideSettings -VisibleBullets $visibleBullets[$currentSlide] -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                    }
                } else {
                    # Content slide: May have ### heading or just content
                    Write-Verbose "Rendering content slide $($currentSlide + 1)/$totalSlides with $($visibleBullets[$currentSlide]) bullets"
                    Show-ContentSlide -Slide $slide -Settings $slideSettings -VisibleBullets $visibleBullets[$currentSlide] -CurrentSlide ($currentSlide + 1) -TotalSlides $totalSlides
                }

                # Get user input
                $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                $action = Get-SlideNavigation -KeyInfo $key

                # Handle help key
                if ($key.Character -eq '?') {
                    Clear-Host
                    
                    # Create help table with keys as cells
                    $helpData = @(
                        [PSCustomObject]@{ Forward = "Right"; Backward = "Left"; Exit = "Esc"; Help = "?" }
                        [PSCustomObject]@{ Forward = "Down"; Backward = "Up"; Exit = "q"; Help = "" }
                        [PSCustomObject]@{ Forward = "Space"; Backward = "Backspace"; Exit = "Ctrl+C"; Help = "" }
                        [PSCustomObject]@{ Forward = "Enter"; Backward = "p"; Exit = ""; Help = "" }
                        [PSCustomObject]@{ Forward = "n"; Backward = "PgUp"; Exit = ""; Help = "" }
                        [PSCustomObject]@{ Forward = "PgDn"; Backward = ""; Exit = ""; Help = "" }
                    )
                    
                    $properties = @(
                        @{ Name = "Forward"; Expression = { $_.Forward }; Alignment = "Center" }
                        @{ Name = "Backward"; Expression = { $_.Backward }; Alignment = "Center" }
                        @{ Name = "Exit"; Expression = { $_.Exit }; Alignment = "Center" }
                        @{ Name = "Help"; Expression = { $_.Help }; Alignment = "Center" }
                    )
                    
                    # Calculate vertical padding for centering
                    $windowHeight = $Host.UI.RawUI.WindowSize.Height
                    $contentHeight = $helpData.Count + 4  # rows + border lines + title + prompt
                    $topPadding = [math]::Max(0, [math]::Floor(($windowHeight - $contentHeight) / 2))
                    
                    # Add blank lines for vertical centering
                    Write-Host ("`n" * $topPadding) -NoNewline
                    
                    # Create table and prompt as renderables
                    $tableRenderable = $helpData | Format-SpectreTable -Property $properties -Border Rounded -Title "Navigation Controls" | Format-SpectreAligned -HorizontalAlignment Center
                    $promptRenderable = "`n[dim]Press any key to return to Deck...[/]" | Format-SpectreAligned -HorizontalAlignment Center
                    
                    # Combine and output
                    @($tableRenderable, $promptRenderable) | Format-SpectreRows | Out-SpectreHost
                    
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
                        } elseif ($currentSlide -lt $totalSlides - 1) {
                            # Move to next slide and reset bullets to 0
                            $currentSlide++
                            $visibleBullets[$currentSlide] = 0
                            Write-Verbose "Advanced to slide $($currentSlide + 1)"
                        } else {
                            # On last slide, trying to go forward shows end screen
                            Write-Host "`e[H" -NoNewline
                            
                            # Center text vertically and horizontally
                            $windowHeight = $Host.UI.RawUI.WindowSize.Height
                            $windowWidth = $Host.UI.RawUI.WindowSize.Width
                            
                            $line1 = "End of Deck"
                            $line2 = "Press ESC or q to Exit"
                            
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
                            
                            # Wait for ESC, q, or backward navigation
                            do {
                                $exitKey = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                                $exitAction = Get-SlideNavigation -KeyInfo $exitKey
                                
                                if ($exitAction -eq 'Previous') {
                                    # Go back to last slide
                                    Write-Verbose "Returning to last slide from end screen"
                                    break
                                } elseif ($exitAction -eq 'Exit') {
                                    # Exit was pressed (Esc, q, or Ctrl+C)
                                    Write-Verbose "User exited from end screen"
                                    $shouldExit = $true
                                    break
                                }
                            } while ($true)
                            
                            # Break out of main navigation loop if exit was requested
                            if ($shouldExit) {
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
                        } elseif ($currentSlide -gt 0) {
                            # Move to previous slide and show all bullets
                            $currentSlide--
                            $prevSlide = $presentation.Slides[$currentSlide]
                            if ($prevSlide.PSObject.Properties['TotalProgressiveBullets']) {
                                $visibleBullets[$currentSlide] = $prevSlide.TotalProgressiveBullets
                            } else {
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
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'PresentationFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Path
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        } finally {
            # Clean up temp file if we downloaded from web
            if ($tempFile -and (Test-Path $tempFile)) {
                Write-Verbose "Cleaning up temporary file: $tempFile"
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
            
            # Show cursor again
            Write-Host "`e[?25h" -NoNewline  # Show cursor
        }
    }

    end {
        Write-Verbose "Show-Deck complete"
    }
}
