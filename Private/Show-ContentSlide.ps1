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

    .EXAMPLE
        Show-ContentSlide -Slide $slideObject -Settings $settings

    .NOTES
        Content slides are the most common slide type for displaying information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Slide,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    begin {
        Write-Verbose "Rendering content slide #$($Slide.Number)"
    }

    process {
        try {
            # Clear the screen
            Clear-Host

            # Get terminal dimensions
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
            $windowHeight = $Host.UI.RawUI.WindowSize.Height

            # Determine if slide has a header and extract content
            $hasHeader = $false
            $headerText = $null
            $content = $null

            if ($Slide.Content -match '^###\s+(.+?)(?:\r?\n|$)') {
                $hasHeader = $true
                $headerText = $Matches[1].Trim()
                Write-Verbose "  Header: $headerText"
                
                # Extract content after header
                $content = $Slide.Content -replace '^###\s+.+?(\r?\n|$)', ''
                $content = $content.Trim()
            }
            else {
                # No header, use all content
                $content = $Slide.Content.Trim()
            }

            # Calculate total height of slide content
            $headerHeight = 0
            if ($hasHeader) {
                # Mini font is approximately 5 lines tall
                $headerHeight = 5
            }
            
            $contentHeight = 0
            if ($content) {
                $lines = $content -split "`r?`n"
                $contentHeight = $lines.Count
            }
            
            # Add spacing between header and content (1 blank line)
            $spacingHeight = if ($hasHeader -and $content) { 1 } else { 0 }
            
            # Calculate total content height and vertical padding
            $totalContentHeight = $headerHeight + $spacingHeight + $contentHeight
            $verticalPadding = [math]::Max(0, [math]::Floor(($windowHeight - $totalContentHeight) / 2))
            
            Write-Verbose "  Total content height: $totalContentHeight, padding: $verticalPadding"
            
            # Apply vertical padding
            Write-Host ("`n" * $verticalPadding) -NoNewline

            # Render header if present
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

                # Render the header using Spectre figlet with 'mini' font (smallest, centered)
                $fontParams = @{
                    Text = $headerText
                    Alignment = 'Center'
                }
                if ($figletColor) {
                    $fontParams['Color'] = $figletColor
                }
                
                # Try to use mini font, fall back to default if not available
                $miniFontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
                if (Test-Path $miniFontPath) {
                    $fontParams['FigletFontPath'] = $miniFontPath
                }
                
                Write-SpectreFigletText @fontParams
            }

            # Render content if present (centered as a block)
            if ($content) {
                Write-Verbose "  Content length: $($content.Length) characters"
                
                # Add spacing between header and content
                if ($hasHeader) {
                    Write-Host ""
                }
                
                # Find the widest line to center the entire block
                $lines = $content -split "`r?`n"
                $maxLineLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
                
                # Calculate horizontal padding based on the widest line
                $horizontalPadding = [math]::Max(0, [math]::Floor(($windowWidth - $maxLineLength) / 2))
                
                foreach ($line in $lines) {
                    Write-Host (" " * $horizontalPadding) -NoNewline
                    Write-Host $line
                }
            }
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
