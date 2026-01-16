function Show-ContentSlide {
    <#
    .SYNOPSIS
        Renders a content slide with optional header and body text.

    .DESCRIPTION
        Displays a content slide that may contain a ### heading rendered as smaller
        figlet text followed by content. If no ### heading is present, only content is shown.
        Content headers use the configured h3 font setting (also accepts aliases: headerFont, h3Font).

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
        [int]$VisibleBullets = [int]::MaxValue,

        [Parameter(Mandatory = $false)]
        [int]$CurrentSlide = 1,

        [Parameter(Mandatory = $false)]
        [int]$TotalSlides = 1
    )

    begin {
        Write-Verbose "Rendering content slide #$($Slide.Number)"
    }

    process {
        try {
            # Get terminal dimensions
            $dimensions = Get-TerminalDimensions
            $windowWidth = $dimensions.Width
            $windowHeight = $dimensions.Height

            # Determine if slide has a header and extract content
            $hasHeader = $false
            $headerText = $null
            $bodyContent = $null

            if ($Slide.Content -match '^###\s+(.+?)(?:\r?\n|$)') {
                $hasHeader = $true
                $headerText = $Matches[1].Trim()
                Write-Verbose "  Header: $headerText"
                
                # Check for color tags in heading text and extract color
                $headingColor = $null
                if ($headerText -match '<(\w+)>.*?</\1>') {
                    $headingColor = $Matches[1]
                    Write-Verbose "  Extracted color from tag: $headingColor"
                } elseif ($headerText -match "<span\s+style=['""]color:(\w+)['""]>.*?</span>") {
                    $headingColor = $Matches[1]
                    Write-Verbose "  Extracted color from span: $headingColor"
                }
                
                # Strip HTML tags from header text
                $headerText = $headerText -replace "<span\s+style=['""]color:\w+['""]>(.*?)</span>", '$1'
                $headerText = $headerText -replace '<(\w+)>(.*?)</\1>', '$2'
                
                # Extract content after header
                $bodyContent = $Slide.Content -replace '^###\s+.+?(\r?\n|$)', ''
                $bodyContent = $bodyContent.Trim()
            } else {
                # No header, use all content
                $bodyContent = $Slide.Content.Trim()
            }

            # Parse code blocks and images FIRST before any bullet filtering
            $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $segments = [System.Collections.Generic.List[object]]::new()
            $lastIndex = 0
            $progressiveBulletCount = 0
            
            if ($bodyContent) {
                # Collect all matches (code blocks and images) and sort by position
                $allMatches = [System.Collections.Generic.List[object]]::new()
                
                foreach ($match in [regex]::Matches($bodyContent, $codeBlockPattern)) {
                    $allMatches.Add(@{
                        Type = 'Code'
                        Match = $match
                        Index = $match.Index
                        Length = $match.Length
                        Language = $match.Groups[1].Value
                        Content = $match.Groups[2].Value.Trim()
                    })
                }
                
                foreach ($match in [regex]::Matches($bodyContent, $imagePattern)) {
                    $width = if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 0 }
                    $allMatches.Add(@{
                        Type = 'Image'
                        Match = $match
                        Index = $match.Index
                        Length = $match.Length
                        AltText = $match.Groups[1].Value
                        Path = $match.Groups[2].Value
                        Width = $width
                    })
                }
                
                # Sort by position in document
                $allMatches = $allMatches | Sort-Object -Property Index
                
                # Build segments
                foreach ($item in $allMatches) {
                    # Add text before this item
                    if ($item.Index -gt $lastIndex) {
                        $textBefore = $bodyContent.Substring($lastIndex, $item.Index - $lastIndex).Trim()
                        if ($textBefore) {
                            $segments.Add(@{ Type = 'Text'; Content = $textBefore })
                        }
                    }
                    
                    # Add the item (code or image)
                    if ($item.Type -eq 'Code') {
                        $segments.Add(@{ Type = 'Code'; Language = $item.Language; Content = $item.Content })
                    } else {
                        $segments.Add(@{ Type = 'Image'; AltText = $item.AltText; Path = $item.Path; Width = $item.Width })
                    }
                    
                    $lastIndex = $item.Index + $item.Length
                }
                
                # Add remaining text after last item
                if ($lastIndex -lt $bodyContent.Length) {
                    $textAfter = $bodyContent.Substring($lastIndex).Trim()
                    if ($textAfter) {
                        $segments.Add(@{ Type = 'Text'; Content = $textAfter })
                    }
                }
                
                # If no code blocks or images found, treat entire content as text
                if ($segments.Count -eq 0) {
                    $segments.Add(@{ Type = 'Text'; Content = $bodyContent })
                }
                
                # Now filter bullets ONLY in text segments
                # Use a single counter across all segments to track visible bullets
                $filteredSegments = [System.Collections.Generic.List[object]]::new()
                $globalVisibleBullets = 0
                
                foreach ($segment in $segments) {
                    if ($segment.Type -eq 'Code' -or $segment.Type -eq 'Image') {
                        # Code blocks and images pass through unchanged
                        $filteredSegments.Add($segment)
                    } else {
                        # Filter bullets in text segments
                        $lines = $segment.Content -split "`r?`n"
                        $filteredLines = [System.Collections.Generic.List[string]]::new()
                        
                        foreach ($line in $lines) {
                            # Check if line is a progressive bullet (*)
                            if ($line -match '^\s*\*\s+') {
                                $progressiveBulletCount++
                                if ($globalVisibleBullets -lt $VisibleBullets) {
                                    $filteredLines.Add($line)
                                    $globalVisibleBullets++
                                } else {
                                    # Add blank line placeholder for hidden progressive bullets
                                    $filteredLines.Add("")
                                }
                            } else {
                                # All other lines (including - bullets) are always shown
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
                    # Strip HTML color tags before measuring length (rendered length, not raw)
                    $maxLength = ($lines | ForEach-Object {
                        # Remove <colorname>text</colorname> tags
                        $stripped = $_ -replace '<([a-zA-Z][a-zA-Z0-9]*)>(.*?)</\1>', '$2'
                        # Remove <span style="color:colorname">text</span> tags
                        $stripped = $stripped -replace '<span\s+style=[''"]color:\s*([a-zA-Z][a-zA-Z0-9]*)[''"]>(.*?)</span>', '$2'
                        $stripped.Length
                    } | Measure-Object -Maximum).Maximum
                    Add-Member -InputObject $Slide -NotePropertyName 'MaxLineLength' -NotePropertyValue $maxLength -Force
                }
            }
            
            # Get border and colors
            $borderInfo = Get-BorderStyleFromSettings -Settings $Settings
            $colorName = if ($hasHeader -and $headingColor) { 
                $headingColor 
            } elseif ($Settings.h3Color) { 
                $Settings.h3Color 
            } else { 
                $Settings.foreground 
            }
            $figletColor = Get-SpectreColorFromSettings -ColorName $colorName -SettingName 'Figlet'

            # Build the renderable content
            $renderables = [System.Collections.Generic.List[object]]::new()
            
            # Add header figlet if present
            if ($hasHeader) {
                # Create header figlet with optional font from settings
                $figletParams = @{
                    Text = $headerText
                    Color = $figletColor
                    Justification = 'Center'
                }
                # Default to 'mini' font if h3 is 'default', otherwise use specified font
                $fontName = if ($Settings.h3 -eq 'default') { 'mini' } else { $Settings.h3 }
                $fontPath = if (Test-Path $fontName) {
                    $fontName
                } else {
                    Join-Path $PSScriptRoot "../Fonts/$fontName.flf"
                }
                if (Test-Path $fontPath) {
                    $figletParams['FontPath'] = $fontPath
                    Write-Verbose "  Using h3 font: $fontName"
                }
                $figlet = New-FigletText @figletParams
                $renderables.Add($figlet)
            }

            # Add body content with code block and image support
            if ($bodyContent) {
                # Render each segment (already parsed and filtered above)
                foreach ($segment in $filteredSegments) {
                    if ($segment.Type -eq 'Code') {
                        # Render code block in a panel with dark background
                        Write-Verbose "  Code block: $($segment.Language)"
                        
                        # Create markup text for the code
                        $codeMarkup = [Spectre.Console.Markup]::Escape($segment.Content)
                        $codeText = [Spectre.Console.Markup]::new("$codeMarkup")
                        
                        # Put code in a panel
                        $codePanel = [Spectre.Console.Panel]::new($codeText)
                        $codePanel.Border = [Spectre.Console.BoxBorder]::Rounded
                        $codePanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                        
                        # Add language label if specified
                        if ($segment.Language) {
                            $codePanel.Header = [Spectre.Console.PanelHeader]::new($segment.Language)
                        }
                        
                        # Center code blocks in single-column content slides
                        $centeredCodePanel = Format-SpectreAligned -Data $codePanel -HorizontalAlignment Center
                        
                        $renderables.Add($centeredCodePanel)
                    } elseif ($segment.Type -eq 'Image') {
                        # Render image
                        Write-Verbose "  Image: $($segment.Path)"
                        
                        try {
                            # Resolve relative paths
                            $imagePath = $segment.Path
                            if (-not [System.IO.Path]::IsPathRooted($imagePath)) {
                                $markdownDir = Split-Path -Parent $Slide.SourceFile
                                $imagePath = Join-Path $markdownDir $imagePath
                            }
                            
                            # Calculate max width (default to 80% of available width)
                            $availableWidth = $windowWidth - 8  # Account for panel padding
                            $maxWidth = if ($segment.Width -gt 0) {
                                [math]::Min($segment.Width, $availableWidth)
                            } else {
                                [math]::Floor($availableWidth * 0.8)
                            }
                            
                            # Load and render image
                            $image = Get-SpectreImage -ImagePath $imagePath -MaxWidth $maxWidth
                            
                            # Center the image
                            $centeredImage = Format-SpectreAligned -Data $image -HorizontalAlignment Center
                            $renderables.Add($centeredImage)
                            
                        } catch {
                            # Show alt text in a styled box on failure
                            Write-Warning "Failed to load image: $($segment.Path) - $($_.Exception.Message)"
                            
                            $altText = if ($segment.AltText) { $segment.AltText } else { "Image not available" }
                            $errorMarkup = [Spectre.Console.Markup]::new("[yellow]$([Spectre.Console.Markup]::Escape($altText))[/]")
                            
                            $errorPanel = [Spectre.Console.Panel]::new($errorMarkup)
                            $errorPanel.Border = [Spectre.Console.BoxBorder]::Rounded
                            $errorPanel.Header = [Spectre.Console.PanelHeader]::new("Image Failed")
                            $errorPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                            
                            $centeredError = Format-SpectreAligned -Data $errorPanel -HorizontalAlignment Center
                            $renderables.Add($centeredError)
                        }
                    } else {
                        # Render text content with centering
                        $lines = $segment.Content -split "`r?`n"
                        
                        # Use stored max line length for consistent alignment during bullet reveal
                        if ($Slide.PSObject.Properties['MaxLineLength']) {
                            $maxLineLength = $Slide.MaxLineLength
                        } else {
                            $maxLineLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
                        }
                        
                        # Calculate padding to center the block within the panel
                        $availableWidth = $windowWidth - 8  # Account for panel padding (4 left + 4 right)
                        $leftPadding = [math]::Max(0, [math]::Floor(($availableWidth - $maxLineLength) / 2))
                        
                        # Convert markdown formatting to Spectre markup
                        $convertedLines = $lines | ForEach-Object {
                            ConvertTo-SpectreMarkup -Text $_
                        }
                        
                        # Rebuild content with padding
                        $paddedLines = $convertedLines | ForEach-Object {
                            (" " * $leftPadding) + $_
                        }
                        $paddedContent = $paddedLines -join "`n"
                        
                        # Create markup text instead of plain text to support formatting
                        $text = [Spectre.Console.Markup]::new($paddedContent)
                        $renderables.Add($text)
                    }
                }
            }

            # Combine renderables into a Rows layout
            $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
            
            # Measure the actual height of the rendered content
            # (blank placeholder lines maintain consistent height for progressive bullets)
            # Account for horizontal padding (4 left + 4 right = 8 total)
            $availableWidth = $windowWidth - 8
            $contentSize = Get-SpectreRenderableSize -Renderable $rows -ContainerWidth $availableWidth
            $actualContentHeight = $contentSize.Height
            
            # Calculate padding - be more conservative with bottom padding for images
            # Sixel images may need extra space that isn't accounted for in the size calculation
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualContentHeight - $borderHeight
            
            # If slide contains images, reduce bottom padding slightly to prevent cutoff
            $hasImages = $filteredSegments | Where-Object { $_.Type -eq 'Image' }
            if ($hasImages) {
                # Add buffer for image rendering
                $remainingSpace = $remainingSpace - 1
            }
            
            $topPadding = [math]::Max(0, [math]::Ceiling($remainingSpace / 2.0))
            $bottomPadding = [math]::Max(1, $remainingSpace - $topPadding)
            
            Write-Verbose "  Content height: $actualContentHeight, top padding: $topPadding, bottom padding: $bottomPadding"
            
            # Create panel with internal padding
            $panel = [Spectre.Console.Panel]::new($rows)
            $panel.Expand = $true
            $panel.Padding = [Spectre.Console.Padding]::new(4, $topPadding, 4, $bottomPadding)
            
            # Add border style and color
            if ($borderInfo.Style) {
                $panel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
            }
            if ($borderInfo.Color) {
                $panel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
            }
            
            # Add pagination header if enabled
            if ($Settings.pagination -eq $true) {
                $paginationParams = @{
                    CurrentSlide = $CurrentSlide
                    TotalSlides = $TotalSlides
                    Style = $Settings.paginationStyle
                }
                if ($borderInfo.Color) {
                    $paginationParams['Color'] = $borderInfo.Color
                }
                $paginationText = Get-PaginationText @paginationParams
                $panel.Header = [Spectre.Console.PanelHeader]::new($paginationText)
                $panel.Header.Justification = [Spectre.Console.Justify]::Right
            }
            
            # Render panel
            Out-SpectreHost $panel
        } catch {
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
