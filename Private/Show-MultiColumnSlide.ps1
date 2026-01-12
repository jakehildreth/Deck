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
                $figlet.Justification = [Spectre.Console.Justify]::Center
                if ($figletColor) {
                    $figlet.Color = $figletColor
                }
                $renderables.Add($figlet)
            }

            # Create column renderables
            $columnRenderables = [System.Collections.Generic.List[object]]::new()
            
            foreach ($columnContent in $columns) {
                if ($columnContent) {
                    # Parse code blocks in this column
                    $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
                    $columnSegments = [System.Collections.Generic.List[object]]::new()
                    $lastIndex = 0
                    
                    foreach ($match in [regex]::Matches($columnContent, $codeBlockPattern)) {
                        # Add text before code block
                        if ($match.Index -gt $lastIndex) {
                            $textBefore = $columnContent.Substring($lastIndex, $match.Index - $lastIndex).Trim()
                            if ($textBefore) {
                                $columnSegments.Add(@{ Type = 'Text'; Content = $textBefore })
                            }
                        }
                        
                        # Add code block
                        $columnSegments.Add(@{
                            Type = 'Code'
                            Language = $match.Groups[1].Value
                            Content = $match.Groups[2].Value.Trim()
                        })
                        
                        $lastIndex = $match.Index + $match.Length
                    }
                    
                    # Add remaining text after last code block
                    if ($lastIndex -lt $columnContent.Length) {
                        $textAfter = $columnContent.Substring($lastIndex).Trim()
                        if ($textAfter) {
                            $columnSegments.Add(@{ Type = 'Text'; Content = $textAfter })
                        }
                    }
                    
                    # If no code blocks found, treat entire content as text
                    if ($columnSegments.Count -eq 0) {
                        $columnSegments.Add(@{ Type = 'Text'; Content = $columnContent })
                    }
                    
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
                            
                            # Center the entire code panel
                            $centeredCodePanel = Format-SpectreAligned -Data $codePanel -HorizontalAlignment Center
                            
                            $columnParts.Add($centeredCodePanel)
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
            
            # Center the grid horizontally to handle short content
            $centeredGrid = Format-SpectreAligned -Data $grid -HorizontalAlignment Center
            $renderables.Add($centeredGrid)

            # Combine renderables into a Rows layout
            $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
            
            # Measure the actual height of the rendered content
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
