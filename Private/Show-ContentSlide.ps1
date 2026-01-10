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
            # Account for Out-SpectreHost adding a trailing newline
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            $windowHeight = $Host.UI.RawUI.WindowSize.Height - 2

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

            # Parse and filter bullets based on visibility
            if ($bodyContent) {
                $lines = $bodyContent -split "`r?`n"
                $filteredLines = [System.Collections.Generic.List[string]]::new()
                $progressiveBulletCount = 0
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
                
                # Store total progressive bullet count on the slide object for navigation
                if (-not $Slide.PSObject.Properties['TotalProgressiveBullets']) {
                    Add-Member -InputObject $Slide -NotePropertyName 'TotalProgressiveBullets' -NotePropertyValue $progressiveBulletCount -Force
                }
                
                # Store the full content height for consistent vertical alignment
                # This ensures content doesn't jump as bullets are revealed
                if (-not $Slide.PSObject.Properties['FullContentHeight']) {
                    $fullContentText = $lines -join "`n"
                    $fullText = [Spectre.Console.Text]::new($fullContentText)
                    $fullSize = Get-SpectreRenderableSize -Renderable $fullText -ContainerWidth $windowWidth
                    Add-Member -InputObject $Slide -NotePropertyName 'FullContentHeight' -NotePropertyValue $fullSize.Height -Force
                }
                
                # Store the max line length of all content (including hidden bullets) for consistent horizontal alignment
                if (-not $Slide.PSObject.Properties['MaxLineLength']) {
                    $maxLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
                    Add-Member -InputObject $Slide -NotePropertyName 'MaxLineLength' -NotePropertyValue $maxLength -Force
                }
                
                $bodyContent = $filteredLines -join "`n"
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

            # Add body content as text
            if ($bodyContent) {
                # Manually pad each line to center the block
                $lines = $bodyContent -split "`r?`n"
                
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

            # Combine renderables into a Rows layout
            $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
            
            # Measure the actual height of the rendered content
            # (blank placeholder lines maintain consistent height for progressive bullets)
            $contentSize = Get-SpectreRenderableSize -Renderable $rows -ContainerWidth $windowWidth
            $actualContentHeight = $contentSize.Height
            
            # Calculate padding
            $borderHeight = 2
            $remainingSpace = $windowHeight - $actualContentHeight - $borderHeight
            $topPadding = [math]::Max(0, [math]::Floor($remainingSpace / 2))
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
