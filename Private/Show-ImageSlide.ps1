function Show-ImageSlide {
    <#
    .SYNOPSIS
        Renders a slide with content on the left and an image on the right.

    .DESCRIPTION
        Displays a slide with a two-panel layout using a 60/40 split: left panel (60%)
        contains text content and the right panel (40%) displays an image. The image is
        automatically sized to fill available space while maintaining aspect ratio.
        
        The rendering process:
        1. Parses content to extract ![alt](path) image reference
        2. Separates text content from image markdown
        3. Detects optional ### heading in text content
        4. Renders left panel with figlet header and body content
        5. Renders right panel with image (supports both local and web URLs)
        6. Filters progressive bullets (*) based on VisibleBullets parameter
        
        Images support both local file paths (relative or absolute) and web URLs
        (http/https). The {width=N} suffix can specify maximum image width in characters.
        
        Left panel supports all content slide features including progressive bullets,
        code blocks, and markdown formatting.

    .PARAMETER Slide
        The slide object containing both text content and an image reference using
        ![alt](path) or ![alt](path){width=N} syntax.

    .PARAMETER Settings
        The presentation settings hashtable containing:
        - foreground: Default text color
        - background: Slide background color
        - border: Border color
        - borderStyle: Border style
        - h3: Font for ### headings in left panel
        - h3Color: Optional color for ### headings

    .PARAMETER VisibleBullets
        The number of progressive bullets (*) to reveal in the left panel content.
        Default is [int]::MaxValue (all bullets shown).

    .PARAMETER CurrentSlide
        The current slide number for pagination display.

    .PARAMETER TotalSlides
        The total number of slides in the presentation for pagination.

    .EXAMPLE
        Show-ImageSlide -Slide $slideObject -Settings $settings

        Renders an image slide with content on left (60%) and image on right (40%).

    .EXAMPLE
        Show-ImageSlide -Slide $slideObject -Settings $settings -VisibleBullets 2

        Renders an image slide showing only the first 2 progressive bullets in the
        left panel content.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 5
            Content = @'
### Product Demo

* Feature one
* Feature two
* Feature three

![Product Screenshot](./images/demo.png){width=80}
'@
        }
        Show-ImageSlide -Slide $slide -Settings $settings

        Demonstrates image slide with heading, progressive bullets, and custom image width.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 6
            Content = @'
Key benefits of our solution.

![Architecture](https://example.com/arch.png)
'@
        }
        Show-ImageSlide -Slide $slide -Settings $settings

        Demonstrates image slide loading image from web URL with no heading.

    .OUTPUTS
        None. Renders directly to the terminal console using PwshSpectreConsole.

    .NOTES
        Layout:
        - Left panel: 60% of terminal width for text content
        - Right panel: 40% of terminal width for image
        - Panels displayed side-by-side using Spectre.Console.Columns
        
        Image Syntax:
        - Standard: ![alt text](path/to/image.png)
        - With width: ![alt text](path/to/image.png){width=80}
        - Web URLs: ![alt text](https://example.com/image.png)
        
        Image Path Resolution:
        - Relative paths: Resolved from markdown file location
        - Absolute paths: Used as-is
        - Web URLs: Downloaded and cached during display
        
        Left Panel Features:
        - Optional ### heading rendered as figlet
        - Progressive bullets (*) with reveal mechanism
        - Regular bullets (-) always visible
        - Code blocks with syntax highlighting
        - Markdown formatting (bold, italic, code, strikethrough)
        
        Requirements:
        - Exactly one ![...](...) image reference per slide
        - Image must not be inside code fence (would be treated as example)
        - Terminal must support image rendering (Kitty, iTerm2, WezTerm, etc.)
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
        Write-Verbose "Rendering image slide #$($Slide.Number)"
    }

    process {
        try {
            # Get terminal dimensions
            $dimensions = Get-TerminalDimensions
            $windowWidth = $dimensions.Width
            $windowHeight = $dimensions.Height

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
                $bodyContent = $textContent -replace '^###\s+.+?(\r?\n|$)', ''
                $bodyContent = $bodyContent.Trim()
            } else {
                # No header, use all text content
                $bodyContent = $textContent.Trim()
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

            # Calculate column widths (60% text, 40% image)
            $contentWidth = [math]::Floor($windowWidth * 0.6)
            $imageColumnWidth = $windowWidth - $contentWidth

            # Build left panel (text content)
            $leftRenderables = [System.Collections.Generic.List[object]]::new()
            
            # Add header figlet if present
            if ($hasHeader) {
                # Create figlet for header with optional font from settings
                $figletParams = @{
                    Text = $headerText
                    Color = $figletColor
                    Justification = 'Left'
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
                        
                        $leftRenderables.Add($codePanel)
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
            if ($borderInfo.Style) {
                $tempLeftPanel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
            }
            if ($borderInfo.Color) {
                $tempLeftPanel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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
            if ($borderInfo.Style) {
                $leftPanelTemp.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
            }
            if ($borderInfo.Color) {
                $leftPanelTemp.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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
                if ($borderInfo.Style) {
                    $imageTempPanel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
                }
                if ($borderInfo.Color) {
                    $imageTempPanel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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
                if ($borderInfo.Style) {
                    $rightPanel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
                }
                if ($borderInfo.Color) {
                    $rightPanel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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
                if ($borderInfo.Style) {
                    $errorTempPanel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
                }
                if ($borderInfo.Color) {
                    $errorTempPanel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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
                if ($borderInfo.Style) {
                    $rightPanel.Border = [Spectre.Console.BoxBorder]::$($borderInfo.Style)
                }
                if ($borderInfo.Color) {
                    $rightPanel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
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

            # Wrap grid in a panel if pagination is enabled, otherwise render directly
            if ($Settings.pagination -eq $true) {
                $outerPanel = [Spectre.Console.Panel]::new($grid)
                $outerPanel.Expand = $true
                $outerPanel.Padding = [Spectre.Console.Padding]::new(0, 0, 0, 0)
                $outerPanel.Border = [Spectre.Console.BoxBorder]::None
                
                $paginationParams = @{
                    CurrentSlide = $CurrentSlide
                    TotalSlides = $TotalSlides
                    Style = $Settings.paginationStyle
                }
                if ($borderInfo.Color) {
                    $paginationParams['Color'] = $borderInfo.Color
                }
                $paginationText = Get-PaginationText @paginationParams
                $outerPanel.Header = [Spectre.Console.PanelHeader]::new($paginationText)
                $outerPanel.Header.Justification = [Spectre.Console.Justify]::Right
                
                Out-SpectreHost $outerPanel
            } else {
                # Render directly (no outer padding needed - panels fill viewport)
                Out-SpectreHost $grid
            }
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
