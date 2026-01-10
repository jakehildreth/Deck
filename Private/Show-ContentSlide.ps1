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

    .PARAMETER VisibleBullets
        The number of progressive bullets (*) to show. If not specified, all bullets are shown.

    .EXAMPLE
        Show-ContentSlide -Slide $slideObject -Settings $settings

    .EXAMPLE
        Show-ContentSlide -Slide $slideObject -Settings $settings -VisibleBullets 2

    .NOTES
        Content slides are the most common slide type for displaying information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $false)]
        [int]$VisibleBullets = [int]::MaxValue
    )

    begin {
        Write-Verbose "Rendering content slide #$($Slide.Number)"
    }

    process {
        try {
            # Clear the screen
            Clear-Host

            # Get terminal dimensions
            # Account for rendering behavior to prevent scrolling
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            $windowHeight = $Host.UI.RawUI.WindowSize.Height - 1

            # Determine if slide has a header and extract content
            $hasHeader = $false
            $headerText = $null
            $bodyContent = $null

            if ($Slide.Content -match '^###\s+(.+?)(?:\r?\n|$)') {
                $hasHeader = $true
                $headerText = $Matches[1].Trim()
                Write-Verbose "  Header: $headerText"
                
                # Extract content after header
                $bodyContent = $Slide.Content -replace '^###\s+.+?(\r?\n|$)', ''
                $bodyContent = $bodyContent.Trim()
            }
            else {
                # No header, use all content
                $bodyContent = $Slide.Content.Trim()
            }

            # Parse code blocks FIRST before any bullet filtering
            $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
            $segments = [System.Collections.Generic.List[object]]::new()
            $lastIndex = 0
            $progressiveBulletCount = 0
            
            if ($bodyContent) {
                foreach ($match in [regex]::Matches($bodyContent, $codeBlockPattern)) {
                    # Add text before code block
                    if ($match.Index -gt $lastIndex) {
                        $textBefore = $bodyContent.Substring($lastIndex, $match.Index - $lastIndex).Trim()
                        if ($textBefore) {
                            $segments.Add(@{ Type = 'Text'; Content = $textBefore })
                        }
                    }
                    
                    # Add code block (no processing needed)
                    $language = $match.Groups[1].Value
                    $code = $match.Groups[2].Value.Trim()
                    $segments.Add(@{ Type = 'Code'; Language = $language; Content = $code })
                    
                    $lastIndex = $match.Index + $match.Length
                }
                
                # Add remaining text after last code block
                if ($lastIndex -lt $bodyContent.Length) {
                    $textAfter = $bodyContent.Substring($lastIndex).Trim()
                    if ($textAfter) {
                        $segments.Add(@{ Type = 'Text'; Content = $textAfter })
                    }
                }
                
                # If no code blocks found, treat entire content as text
                if ($segments.Count -eq 0) {
                    $segments.Add(@{ Type = 'Text'; Content = $bodyContent })
                }
                
                # Now filter bullets ONLY in text segments
                $filteredSegments = [System.Collections.Generic.List[object]]::new()
                
                foreach ($segment in $segments) {
                    if ($segment.Type -eq 'Code') {
                        # Code blocks pass through unchanged
                        $filteredSegments.Add($segment)
                    }
                    else {
                        # Filter bullets in text segments
                        $lines = $segment.Content -split "`r?`n"
                        $filteredLines = [System.Collections.Generic.List[string]]::new()
                        $visibleProgressiveBullets = 0
                        
                        foreach ($line in $lines) {
                            # Check if line is a progressive bullet (*)
                            if ($line -match '^\s*\*\s+') {
                                $progressiveBulletCount++
                                if ($visibleProgressiveBullets -lt $VisibleBullets) {
                                    $filteredLines.Add($line)
                                    $visibleProgressiveBullets++
                                }
                                else {
                                    # Add blank line placeholder for hidden progressive bullets
                                    $filteredLines.Add("")
                                }
                            }
                            # All other lines (including - bullets) are always shown
                            else {
                                $filteredLines.Add($line)
                            }
                        }
                        
                        $filteredSegments.Add(@{ Type = 'Text'; Content = ($filteredLines -join "`n") })
                    }
                }
                
                # Store total progressive bullet count on the slide object for navigation
                if (-not $Slide.PSObject.Properties['TotalProgressiveBullets']) {
                    Add-Member -InputObject $Slide -NotePropertyName 'TotalProgressiveBullets' -NotePropertyValue $progressiveBulletCount -Force
                }
                
                # Store the full content height for consistent vertical alignment
                if (-not $Slide.PSObject.Properties['FullContentHeight']) {
                    $fullText = [Spectre.Console.Text]::new($bodyContent)
                    $fullSize = Get-SpectreRenderableSize -Renderable $fullText -ContainerWidth $windowWidth
                    Add-Member -InputObject $Slide -NotePropertyName 'FullContentHeight' -NotePropertyValue $fullSize.Height -Force
                }
                
                # Store the max line length of all content for consistent horizontal alignment
                if (-not $Slide.PSObject.Properties['MaxLineLength']) {
                    $lines = $bodyContent -split "`r?`n"
                    $maxLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
                    Add-Member -InputObject $Slide -NotePropertyName 'MaxLineLength' -NotePropertyValue $maxLength -Force
                }
            }
            
            # Get border color and style
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
            
            $borderStyle = 'Rounded'
            if ($Settings.borderStyle) {
                $borderStyle = (Get-Culture).TextInfo.ToTitleCase($Settings.borderStyle.ToLower())
                Write-Verbose "  Border style: $borderStyle"
            }

            # Build the renderable content
            $renderables = [System.Collections.Generic.List[object]]::new()
            
            # Add header figlet if present
            if ($hasHeader) {
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

                # Create figlet for header
                $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                if (Test-Path $miniFontPath) {
                    $font = [Spectre.Console.FigletFont]::Load($miniFontPath)
                    $figlet = [Spectre.Console.FigletText]::new($font, $headerText)
                }
                else {
                    $figlet = [Spectre.Console.FigletText]::new($headerText)
                }
                $figlet.Justification = [Spectre.Console.Justify]::Center
                if ($figletColor) {
                    $figlet.Color = $figletColor
                }
                $renderables.Add($figlet)
            }

            # Add body content with code block support
            if ($bodyContent) {
                # Render each segment (already parsed and filtered above)
                foreach ($segment in $filteredSegments) {
                    if ($segment.Type -eq 'Code') {
                        # Render code block in a panel with dark background
                        Write-Verbose "  Code block: $($segment.Language)"
                        
                        # Create markup text for the code
                        $codeMarkup = [Spectre.Console.Markup]::Escape($segment.Content)
                        $codeText = [Spectre.Console.Markup]::new("[grey on grey11]$codeMarkup[/]")
                        
                        # Put code in a panel
                        $codePanel = [Spectre.Console.Panel]::new($codeText)
                        $codePanel.Border = [Spectre.Console.BoxBorder]::Rounded
                        $codePanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                        
                        # Add language label if specified
                        if ($segment.Language) {
                            $codePanel.Header = [Spectre.Console.PanelHeader]::new($segment.Language)
                        }
                        
                        # Center the entire code panel
                        $centeredCodePanel = Format-SpectreAligned -Data $codePanel -HorizontalAlignment Center
                        
                        $renderables.Add($centeredCodePanel)
                    }
                    else {
                        # Render text content with centering
                        $lines = $segment.Content -split "`r?`n"
                        
                        # Use stored max line length for consistent alignment during bullet reveal
                        if ($Slide.PSObject.Properties['MaxLineLength']) {
                            $maxLineLength = $Slide.MaxLineLength
                        }
                        else {
                            $maxLineLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
                        }
                        
                        # Calculate padding to center the block within the panel
                        $availableWidth = $windowWidth - 8  # Account for panel padding (4 left + 4 right)
                        $leftPadding = [math]::Max(0, [math]::Floor(($availableWidth - $maxLineLength) / 2))
                        
                        # Rebuild content with padding
                        $paddedLines = $lines | ForEach-Object {
                            (" " * $leftPadding) + $_
                        }
                        $paddedContent = $paddedLines -join "`n"
                        
                        # Create text with left justification (padding is already in the string)
                        $text = [Spectre.Console.Text]::new($paddedContent)
                        $text.Justification = [Spectre.Console.Justify]::Left
                        $renderables.Add($text)
                    }
                }
            }

            # Combine renderables into a Rows layout
            $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
            
            # Measure the actual height of the rendered content
            # (blank placeholder lines maintain consistent height for progressive bullets)
            $contentSize = Get-SpectreRenderableSize -Renderable $rows -ContainerWidth $windowWidth
            $actualContentHeight = $contentSize.Height
            
            # Calculate padding
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualContentHeight - $borderHeight
            $topPadding = [math]::Max(0, [math]::Ceiling($remainingSpace / 2.0))
            $bottomPadding = [math]::Max(0, $remainingSpace - $topPadding)
            
            Write-Verbose "  Content height: $actualContentHeight, top padding: $topPadding, bottom padding: $bottomPadding"
            
            # Create panel with internal padding
            $panel = [Spectre.Console.Panel]::new($rows)
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
            
            # Render panel
            Out-SpectreHost $panel
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
