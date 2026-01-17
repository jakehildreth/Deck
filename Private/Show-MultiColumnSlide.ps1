function Show-MultiColumnSlide {
    <#
    .SYNOPSIS
        Renders a slide with multiple columns of content.

    .DESCRIPTION
        Displays a slide split into 2, 3, 4, or more columns arranged side-by-side.
        Content is divided using the ||| delimiter (three pipe characters). Each column
        can contain text, code blocks, and markdown formatting.
        
        The rendering process:
        1. Detects optional ### heading and renders as centered figlet text
        2. Splits body content at each ||| delimiter
        3. Parses code blocks in each column independently
        4. Converts markdown formatting to Spectre markup
        5. Renders columns with equal width distribution
        
        Columns are automatically sized to evenly divide the terminal width. For example,
        2 columns get 50% each, 3 columns get 33% each, etc.
        
        The optional ### heading appears above all columns as centered figlet text.
        Heading color can be overridden using HTML color tags.

    .PARAMETER Slide
        The slide object containing content with ||| delimiters separating columns.

    .PARAMETER Settings
        The presentation settings hashtable containing:
        - foreground: Default text color
        - background: Slide background color
        - border: Border color
        - borderStyle: Border style
        - h3: Font for optional ### heading
        - h3Color: Optional color override for heading

    .PARAMETER CurrentSlide
        The current slide number for pagination display.

    .PARAMETER TotalSlides
        The total number of slides in the presentation for pagination.

    .EXAMPLE
        Show-MultiColumnSlide -Slide $slideObject -Settings $settings

        Renders a multi-column slide with content split by ||| delimiters.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 4
            Content = @'
### Feature Comparison

**Basic**
- Feature A
- Feature B

|||

**Pro**
- Feature A
- Feature B
- Feature C

|||

**Enterprise**
- All features
- Priority support
- Custom integration
'@
        }
        Show-MultiColumnSlide -Slide $slide -Settings $settings

        Demonstrates 3-column slide with heading and bullet lists in each column.

    .EXAMPLE
        $slide = [PSCustomObject]@{
            Number = 7
            Content = @'
Before:

```powershell
Get-Process
```

|||

After:

```powershell
Get-Process | Where-Object CPU -gt 100
```
'@
        }
        Show-MultiColumnSlide -Slide $slide -Settings $settings

        Demonstrates 2-column slide comparing code examples side-by-side.

    .OUTPUTS
        None. Renders directly to the terminal console using PwshSpectreConsole.

    .NOTES
        Column Layout:
        - 2 columns: 50% width each
        - 3 columns: 33% width each
        - 4+ columns: Evenly divided (may be tight on narrow terminals)
        
        Column Delimiter:
        - Use exactly three pipe characters: |||
        - Must be on its own line
        - Whitespace around delimiter is trimmed
        
        Column Content:
        - Markdown formatting supported (bold, italic, code, strikethrough)
        - Code blocks with syntax highlighting
        - Bullet lists (both - and * styles)
        - Plain text paragraphs
        
        Heading Support:
        - Optional ### heading renders above columns
        - Heading uses h3 font (default: 'mini')
        - Heading centered across full slide width
        - Color override via <color>text</color> or <span style="color:name">text</span>
        
        Best Practices:
        - Keep column content balanced for visual appeal
        - Avoid excessive text in narrow columns
        - Test on target terminal width
        - Use 2-3 columns for best readability
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter(Mandatory = $false)]
        [int]$CurrentSlide = 1,

        [Parameter(Mandatory = $false)]
        [int]$TotalSlides = 1
    )

    begin {
        Write-Verbose "Rendering multi-column slide #$($Slide.Number)"
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

            # Split content into columns at ||| delimiter
            $columnDelimiter = '\|\|\|'
            $columns = $bodyContent -split $columnDelimiter
            $columns = $columns | ForEach-Object { $_.Trim() }
            
            Write-Verbose "  Detected $($columns.Count) columns"

            # Get border color and style
            $borderInfo = Get-BorderStyleFromSettings -Settings $Settings

            # Build the renderable content
            $renderables = [System.Collections.Generic.List[object]]::new()
            
            # Add header figlet if present
            if ($hasHeader) {
                # Convert color name to Spectre.Console.Color
                $colorName = if ($headingColor) { 
                    $headingColor 
                } elseif ($Settings.h3Color) { 
                    $Settings.h3Color 
                } else { 
                    $Settings.foreground 
                }
                $figletColor = Get-SpectreColorFromSettings -ColorName $colorName -SettingName 'Header'

                # Create figlet for header with optional font from settings
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

            # Create column renderables
            $columnRenderables = [System.Collections.Generic.List[object]]::new()
            
            foreach ($columnContent in $columns) {
                if ($columnContent) {
                    # Parse code blocks in this column
                    $columnSegments = ConvertTo-CodeBlockSegments -Content $columnContent
                        
                    # Parse code blocks in this column
                    $columnSegments = ConvertTo-CodeBlockSegments -Content $columnContent
                    
                    # Build renderables for this column
                    $columnParts = [System.Collections.Generic.List[object]]::new()
                    
                    foreach ($segment in $columnSegments) {
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
                            
                            $columnParts.Add($codePanel)
                        } else {
                            # Render text
                            $textLines = $segment.Content -split "`r?`n" | ForEach-Object {
                                ConvertTo-SpectreMarkup -Text $_
                            }
                            $textMarkup = [Spectre.Console.Markup]::new(($textLines -join "`n"))
                            $columnParts.Add($textMarkup)
                        }
                    }
                    
                    # Combine column parts into Rows if multiple, otherwise use single part
                    if ($columnParts.Count -gt 1) {
                        $columnRenderable = [Spectre.Console.Rows]::new([object[]]$columnParts.ToArray())
                    } else {
                        $columnRenderable = $columnParts[0]
                    }
                    
                    $columnRenderables.Add($columnRenderable)
                } else {
                    # Empty column
                    $columnRenderables.Add([Spectre.Console.Text]::new(""))
                }
            }

            # Create columns layout using Grid for equal-width columns
            # Grid provides explicit control over column widths
            $columnCount = $columnRenderables.Count
            
            Write-Verbose "  Creating $columnCount equal-width columns using Grid"
            
            # Create a Grid with equal-width columns
            $grid = [Spectre.Console.Grid]::new()
            
            # Add columns to the grid (one GridColumn per content column)
            for ($i = 0; $i -lt $columnCount; $i++) {
                $gridColumn = [Spectre.Console.GridColumn]::new()
                $gridColumn.NoWrap = $false
                $gridColumn.Padding = [Spectre.Console.Padding]::new(2, 0, 2, 0)  # Horizontal padding
                $grid.AddColumn($gridColumn) | Out-Null
            }
            
            # Add content as a single row with all columns
            $grid.AddRow($columnRenderables.ToArray()) | Out-Null
            
            # Measure grid height BEFORE wrapping in alignment
            # This ensures accurate measurement without Format-SpectreAligned interference
            $renderablesForMeasurement = [System.Collections.Generic.List[object]]::new($renderables)
            $renderablesForMeasurement.Add($grid)
            $rowsForMeasurement = [Spectre.Console.Rows]::new([object[]]$renderablesForMeasurement.ToArray())
            
            # Measure the actual height of the rendered content
            # Account for horizontal padding (4 left + 4 right = 8 total)
            $availableWidth = $windowWidth - 8
            $contentSize = Get-SpectreRenderableSize -Renderable $rowsForMeasurement -ContainerWidth $availableWidth
            $actualContentHeight = $contentSize.Height
            
            # Now center the grid for display
            $centeredGrid = Format-SpectreAligned -Data $grid -HorizontalAlignment Center
            $renderables.Add($centeredGrid)

            # Combine renderables into a Rows layout for rendering
            $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
            
            # Calculate padding
            # Add safety buffer if content contains code blocks (measurement might be slightly off)
            $hasCodeBlocks = $columnRenderables | ForEach-Object { $_ } | Where-Object { $_ -is [Spectre.Console.Panel] }
            $heightBuffer = if ($hasCodeBlocks) { 2 } else { 0 }
            
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualContentHeight - $borderHeight - $heightBuffer
            $topPadding = [math]::Max(0, [math]::Ceiling($remainingSpace / 2.0))
            $bottomPadding = [math]::Max(0, $remainingSpace - $topPadding)
            
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
                'MultiColumnSlideRenderFailed',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Slide
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose "Multi-column slide rendered"
    }
}
