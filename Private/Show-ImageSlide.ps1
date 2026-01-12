function Show-ImageSlide {
    <#
    .SYNOPSIS
        Renders a slide with content on the left and an image on the right.

    .DESCRIPTION
        Displays a slide with a two-panel layout where the left panel contains text content
        (optionally with a ### heading) and the right panel displays an image. The image is
        automatically sized to fill the available space while maintaining aspect ratio.

    .PARAMETER Slide
        The slide object containing the content and image to render.

    .PARAMETER Settings
        The presentation settings hashtable containing colors, fonts, and styling options.

    .PARAMETER VisibleBullets
        The number of progressive bullets (*) to show. If not specified, all bullets are shown.

    .EXAMPLE
        Show-ImageSlide -Slide $slideObject -Settings $settings

    .EXAMPLE
        Show-ImageSlide -Slide $slideObject -Settings $settings -VisibleBullets 2

    .NOTES
        This slide type requires exactly one image in the markdown using ![alt](path) syntax.
        The image path can be relative to the markdown file or absolute.
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
        Write-Verbose "Rendering image slide #$($Slide.Number)"
    }

    process {
        try {
            # Get terminal dimensions
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            $windowHeight = $Host.UI.RawUI.WindowSize.Height - 1

            # Parse content to separate text from image
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $imageMatch = [regex]::Match($Slide.Content, $imagePattern)
            
            if (-not $imageMatch.Success) {
                throw "Image slide requires an image using ![alt](path) syntax"
            }

            $imagePath = $imageMatch.Groups[2].Value
            $imageAltText = $imageMatch.Groups[1].Value
            $imageWidth = if ($imageMatch.Groups[3].Success) { [int]$imageMatch.Groups[3].Value } else { 0 }

            # Extract text content (everything except the image)
            $textContent = $Slide.Content.Remove($imageMatch.Index, $imageMatch.Length).Trim()

            # Determine if text has a header
            $hasHeader = $false
            $headerText = $null
            $bodyContent = $null

            if ($textContent -match '^###\s+(.+?)(?:\r?\n|$)') {
                $hasHeader = $true
                $headerText = $Matches[1].Trim()
                Write-Verbose "  Header: $headerText"
                
                # Extract content after header
                $bodyContent = $textContent -replace '^###\s+.+?(\r?\n|$)', ''
                $bodyContent = $bodyContent.Trim()
            } else {
                # No header, use all text content
                $bodyContent = $textContent.Trim()
            }

            # Get border color and style
            $borderColor = $null
            if ($Settings.border) {
                $borderColorName = (Get-Culture).TextInfo.ToTitleCase($Settings.border.ToLower())
                Write-Verbose "  Border color: $borderColorName"
                try {
                    $borderColor = [Spectre.Console.Color]::$borderColorName
                } catch {
                    Write-Warning "Invalid border color '$($Settings.border)', using default"
                }
            }
            
            $borderStyle = 'Rounded'
            if ($Settings.borderStyle) {
                $borderStyle = (Get-Culture).TextInfo.ToTitleCase($Settings.borderStyle.ToLower())
                Write-Verbose "  Border style: $borderStyle"
            }

            # Calculate column widths (60% text, 40% image)
            $contentWidth = [math]::Floor($windowWidth * 0.6)
            $imageColumnWidth = $windowWidth - $contentWidth

            # Build left panel (text content)
            $leftRenderables = [System.Collections.Generic.List[object]]::new()
            
            # Add header figlet if present
            if ($hasHeader) {
                $figletColor = $null
                if ($Settings.foreground) {
                    $colorName = (Get-Culture).TextInfo.ToTitleCase($Settings.foreground.ToLower())
                    Write-Verbose "  Header color: $colorName"
                    try {
                        $figletColor = [Spectre.Console.Color]::$colorName
                    } catch {
                        Write-Warning "Invalid color '$($Settings.foreground)', using default"
                    }
                }

                # Create figlet for header
                $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                if (Test-Path $miniFontPath) {
                    $font = [Spectre.Console.FigletFont]::Load($miniFontPath)
                    $figlet = [Spectre.Console.FigletText]::new($font, $headerText)
                } else {
                    $figlet = [Spectre.Console.FigletText]::new($headerText)
                }
                $figlet.Justification = [Spectre.Console.Justify]::Left
                if ($figletColor) {
                    $figlet.Color = $figletColor
                }
                $leftRenderables.Add($figlet)
            }

            # Process body content with code blocks and bullet filtering
            if ($bodyContent) {
                # Parse code blocks first
                $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
                $segments = [System.Collections.Generic.List[object]]::new()
                $lastIndex = 0
                
                foreach ($match in [regex]::Matches($bodyContent, $codeBlockPattern)) {
                    # Add text before code block
                    if ($match.Index -gt $lastIndex) {
                        $textBefore = $bodyContent.Substring($lastIndex, $match.Index - $lastIndex).Trim()
                        if ($textBefore) {
                            $segments.Add(@{ Type = 'Text'; Content = $textBefore })
                        }
                    }
                    
                    # Add code block
                    $segments.Add(@{
                        Type = 'Code'
                        Language = $match.Groups[1].Value
                        Content = $match.Groups[2].Value.Trim()
                    })
                    
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
                
                # Filter bullets ONLY in text segments
                $progressiveBulletCount = 0
                $visibleBulletCount = 0
                
                foreach ($segment in $segments) {
                    if ($segment.Type -eq 'Code') {
                        # Render code block in a panel
                        $codeMarkup = [Spectre.Console.Markup]::Escape($segment.Content)
                        $codeText = [Spectre.Console.Markup]::new($codeMarkup)
                        
                        $codePanel = [Spectre.Console.Panel]::new($codeText)
                        $codePanel.Border = [Spectre.Console.BoxBorder]::Rounded
                        $codePanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                        
                        if ($segment.Language) {
                            $codePanel.Header = [Spectre.Console.PanelHeader]::new($segment.Language)
                        }
                        
                        # Center the entire code panel
                        $centeredCodePanel = Format-SpectreAligned -Data $codePanel -HorizontalAlignment Center
                        
                        $leftRenderables.Add($centeredCodePanel)
                    } else {
                        # Filter bullets in text segments
                        $lines = $segment.Content -split "`r?`n"
                        $filteredLines = [System.Collections.Generic.List[string]]::new()
                        
                        foreach ($line in $lines) {
                            # Check if line is a progressive bullet (*)
                            if ($line -match '^\s*\*\s+') {
                                $progressiveBulletCount++
                                if ($visibleBulletCount -lt $VisibleBullets) {
                                    $filteredLines.Add($line)
                                    $visibleBulletCount++
                                } else {
                                    # Add blank line placeholder for hidden progressive bullets
                                    $filteredLines.Add("")
                                }
                            } else {
                                # All other lines (including - bullets) are always shown
                                $filteredLines.Add($line)
                            }
                        }
                        
                        # Convert markdown formatting to Spectre markup
                        $convertedLines = $filteredLines | ForEach-Object {
                            ConvertTo-SpectreMarkup -Text $_
                        }
                        
                        $textMarkup = [Spectre.Console.Markup]::new(($convertedLines -join "`n"))
                        $leftRenderables.Add($textMarkup)
                    }
                }
                
                # Store total progressive bullet count on the slide object for navigation
                if (-not $Slide.PSObject.Properties['TotalProgressiveBullets']) {
                    Add-Member -InputObject $Slide -NotePropertyName 'TotalProgressiveBullets' -NotePropertyValue $progressiveBulletCount -Force
                }
            }

            # Combine left panel content into rows
            $leftRows = [Spectre.Console.Rows]::new([object[]]$leftRenderables.ToArray())
            
            # Target height is the full viewport
            $targetHeight = $windowHeight
            
            # Create a temporary left panel to measure its natural height
            $tempLeftPanel = [Spectre.Console.Panel]::new($leftRows)
            $tempLeftPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
            if ($borderStyle) {
                $tempLeftPanel.Border = [Spectre.Console.BoxBorder]::$borderStyle
            }
            if ($borderColor) {
                $tempLeftPanel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
            }
            
            # Measure the natural height
            $tempLeftPanelSize = Get-SpectreRenderableSize -Renderable $tempLeftPanel -ContainerWidth $contentWidth
            
            # Add padding to reach full viewport height
            $finalLeftContent = $leftRows
            if ($tempLeftPanelSize.Height -lt $targetHeight) {
                $heightDiff = $targetHeight - $tempLeftPanelSize.Height
                $topPad = [math]::Floor($heightDiff / 2.0)
                $bottomPad = $heightDiff - $topPad
                $finalLeftContent = [Spectre.Console.Padder]::new($leftRows, [Spectre.Console.Padding]::new(0, $topPad, 0, $bottomPad))
            }
            
            # Create final left panel with padded content
            $leftPanelTemp = [Spectre.Console.Panel]::new($finalLeftContent)
            $leftPanelTemp.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
            if ($borderStyle) {
                $leftPanelTemp.Border = [Spectre.Console.BoxBorder]::$borderStyle
            }
            if ($borderColor) {
                $leftPanelTemp.BorderStyle = [Spectre.Console.Style]::new($borderColor)
            }

            # Build right panel (image)
            $rightPanel = $null
            try {
                # Detect if this is a web URL
                $isWebUrl = $imagePath -match '^https?://'
                
                # Resolve relative paths for local files
                $imagePathResolved = $imagePath
                if (-not $isWebUrl -and -not [System.IO.Path]::IsPathRooted($imagePath)) {
                    $markdownDir = Split-Path -Parent $Slide.SourceFile
                    $imagePathResolved = Join-Path $markdownDir $imagePath
                }
                
                # Calculate max width for image (allow for panel padding and border)
                $maxImageWidth = if ($imageWidth -gt 0) {
                    [math]::Min($imageWidth, $imageColumnWidth - 8)
                } else {
                    $imageColumnWidth - 8
                }
                
                # Calculate max height for image (allow for panel padding, border, and some margin)
                # Panel has vertical padding of 1 top + 1 bottom = 2, plus 2 for borders = 4 total
                $maxImageHeight = $targetHeight - 4
                
                # Load image (supports both local paths and web URLs)
                $image = Get-SpectreImage -ImagePath $imagePathResolved -MaxWidth $maxImageWidth -ErrorAction Stop
                
                # Check if image height exceeds available space and reload with height constraint if needed
                $imageSize = Get-SpectreRenderableSize -Renderable $image -ContainerWidth $imageColumnWidth
                if ($imageSize.Height -gt $maxImageHeight) {
                    Write-Verbose "  Image height ($($imageSize.Height)) exceeds max ($maxImageHeight), reloading with height constraint"
                    # Reload image with both width and height constraints
                    # Get-SpectreImage doesn't have MaxHeight, so we need to calculate appropriate MaxWidth
                    # to maintain aspect ratio while fitting within height constraint
                    $aspectRatio = $imageSize.Width / [Math]::Max($imageSize.Height, 1)
                    $constrainedWidth = [math]::Floor($maxImageHeight * $aspectRatio)
                    $constrainedWidth = [math]::Min($constrainedWidth, $maxImageWidth)
                    
                    Write-Verbose "  Reloading with constrained width: $constrainedWidth (aspect ratio: $aspectRatio)"
                    $image = Get-SpectreImage -ImagePath $imagePathResolved -MaxWidth $constrainedWidth -ErrorAction Stop
                }
                
                # Center horizontally first
                $centeredImage = Format-SpectreAligned -Data $image -HorizontalAlignment Center
                
                # Measure centered image to see if we need padding
                $imageTempPanel = [Spectre.Console.Panel]::new($centeredImage)
                $imageTempPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                if ($borderStyle) {
                    $imageTempPanel.Border = [Spectre.Console.BoxBorder]::$borderStyle
                }
                if ($borderColor) {
                    $imageTempPanel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
                }
                $imagePanelSize = Get-SpectreRenderableSize -Renderable $imageTempPanel -ContainerWidth $imageColumnWidth
                
                # Add padding if needed to match target height
                $finalImageContent = $centeredImage
                if ($imagePanelSize.Height -lt $targetHeight) {
                    $heightDiff = $targetHeight - $imagePanelSize.Height
                    $topPad = [math]::Floor($heightDiff / 2.0)
                    $bottomPad = $heightDiff - $topPad
                    $finalImageContent = [Spectre.Console.Padder]::new($centeredImage, [Spectre.Console.Padding]::new(0, $topPad, 0, $bottomPad))
                }
                
                # Create final right panel
                $rightPanel = [Spectre.Console.Panel]::new($finalImageContent)
                $rightPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                if ($borderStyle) {
                    $rightPanel.Border = [Spectre.Console.BoxBorder]::$borderStyle
                }
                if ($borderColor) {
                    $rightPanel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
                }
                
            } catch {
                # Show alt text in a styled box on failure
                $altText = if ($imageAltText) { $imageAltText } else { "Image not available" }
                $errorMarkup = [Spectre.Console.Markup]::new("[yellow]$([Spectre.Console.Markup]::Escape($altText))[/]")
                
                $errorInner = [Spectre.Console.Panel]::new($errorMarkup)
                $errorInner.Border = [Spectre.Console.BoxBorder]::Rounded
                $errorInner.Header = [Spectre.Console.PanelHeader]::new("Image Failed")
                $errorInner.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                
                # Center the error panel horizontally
                $centeredError = Format-SpectreAligned -Data $errorInner -HorizontalAlignment Center
                
                # Measure centered error to see if we need padding
                $errorTempPanel = [Spectre.Console.Panel]::new($centeredError)
                $errorTempPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                if ($borderStyle) {
                    $errorTempPanel.Border = [Spectre.Console.BoxBorder]::$borderStyle
                }
                if ($borderColor) {
                    $errorTempPanel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
                }
                $errorPanelSize = Get-SpectreRenderableSize -Renderable $errorTempPanel -ContainerWidth $imageColumnWidth
                
                # Add padding if needed to match target height
                $finalErrorContent = $centeredError
                if ($errorPanelSize.Height -lt $targetHeight) {
                    $heightDiff = $targetHeight - $errorPanelSize.Height
                    $topPad = [math]::Floor($heightDiff / 2.0)
                    $bottomPad = $heightDiff - $topPad
                    $finalErrorContent = [Spectre.Console.Padder]::new($centeredError, [Spectre.Console.Padding]::new(0, $topPad, 0, $bottomPad))
                }
                
                # Create final right panel
                $rightPanel = [Spectre.Console.Panel]::new($finalErrorContent)
                $rightPanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
                if ($borderStyle) {
                    $rightPanel.Border = [Spectre.Console.BoxBorder]::$borderStyle
                }
                if ($borderColor) {
                    $rightPanel.BorderStyle = [Spectre.Console.Style]::new($borderColor)
                }
            }

            # Use the left panel we already created
            $leftPanel = $leftPanelTemp
            
            # Create a Grid layout with explicit column widths for 60/40 split
            $grid = [Spectre.Console.Grid]::new()
            $leftColumn = [Spectre.Console.GridColumn]::new()
            $leftColumn.Width = $contentWidth
            $grid.AddColumn($leftColumn) | Out-Null
            
            $rightColumn = [Spectre.Console.GridColumn]::new()
            $rightColumn.Width = $imageColumnWidth
            $grid.AddColumn($rightColumn) | Out-Null
            
            $grid.AddRow($leftPanel, $rightPanel) | Out-Null

            # Render directly (no outer padding needed - panels fill viewport)
            Out-SpectreHost $grid
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'ImageSlideRenderFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Slide
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Image slide rendered"
    }
}
