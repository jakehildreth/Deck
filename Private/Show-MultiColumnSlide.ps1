function Show-MultiColumnSlide {
    <#
    .SYNOPSIS
        Renders a slide with multiple columns of content.

    .DESCRIPTION
        Displays a slide split into multiple columns. Content is divided using the ||| delimiter.
        Supports 2, 3, 4, or more columns that are evenly spaced across the width.
        Optionally includes a ### heading rendered as figlet text above the columns.

    .PARAMETER Slide
        The slide object containing the content to render.

    .PARAMETER Settings
        The presentation settings hashtable containing colors, fonts, and styling options.

    .EXAMPLE
        Show-MultiColumnSlide -Slide $slideObject -Settings $settings

    .NOTES
        Multi-column slides split content at each ||| delimiter for side-by-side display.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
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
                $figletColor = Get-SpectreColorFromSettings -ColorName $Settings.foreground -SettingName 'Header'

                # Create figlet for header
                $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                $figlet = New-FigletText -Text $headerText -FontPath $miniFontPath -Color $figletColor -Justification Center
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
