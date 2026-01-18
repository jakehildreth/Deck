function ConvertFrom-DeckMarkdown {
    <#
    .SYNOPSIS
        Parses markdown file for slide presentation data.

    .DESCRIPTION
        Extracts YAML frontmatter settings and splits markdown content into individual
        slides for presentation rendering. This is the core parsing engine that converts
        raw markdown into a structured presentation object.
        
        The parser performs several operations:
        1. Extracts YAML frontmatter (--- delimited) for global settings
        2. Normalizes font and color property aliases to canonical names
        3. Splits content by horizontal rules (---, ***, ___) while preserving code blocks
        4. Parses per-slide override comments (pagination, paginationStyle)
        5. Filters out empty slides and handles intentionally blank slides
        6. Tracks line numbers for error reporting
        
        Horizontal rules inside code fences are protected and not treated as slide
        delimiters. Code blocks are temporarily replaced with placeholders during
        parsing to ensure they remain intact.

    .PARAMETER Path
        Path to the markdown file to parse. Must be a valid file path that exists.
        Both relative and absolute paths are supported.

    .EXAMPLE
        $presentation = ConvertFrom-DeckMarkdown -Path ".\presentation.md"
        $presentation.Settings.foreground
        $presentation.Slides.Count

        Parses a markdown file and returns the presentation object with settings
        and slide array.

    .EXAMPLE
        $presentation = ConvertFrom-DeckMarkdown -Path ".\slides.md"
        foreach ($slide in $presentation.Slides) {
            Write-Host "Slide $($slide.Number): $($slide.Content.Substring(0, 50))"
        }

        Parses markdown and iterates through all slides to display a summary.

    .EXAMPLE
        $presentation = ConvertFrom-DeckMarkdown -Path ".\demo.md" -Verbose
        
        Parses markdown with verbose output showing frontmatter parsing, font alias
        normalization, and slide detection details.

    .OUTPUTS
        PSCustomObject
        
        Returns an object with three properties:
        - Settings: Hashtable containing all presentation settings (colors, fonts, borders, pagination)
        - Slides: Array of slide objects, each containing Number, Content, IsBlank, LineNumber, and Overrides
        - SourcePath: Original file path for reference

    .NOTES
        Supported Frontmatter Keys:
        - background, foreground, border: Color names (e.g., 'Black', 'Cyan1')
        - header, footer: Optional text for header/footer areas
        - pagination: Boolean to enable/disable slide numbers
        - paginationStyle: Style of pagination (minimal, fraction, text, progress, dots)
        - borderStyle: Border style (rounded, square, double, heavy, none)
        - h1, h2, h3: Font names for title, section, and content headings
        - h1Color, h2Color, h3Color: Colors for each heading level
        
        Font Property Aliases (all normalized to h1/h2/h3):
        - titleFont, h1Font → h1
        - sectionFont, h2Font → h2
        - headerFont, h3Font → h3
        
        Color Property Aliases (all normalized to h1Color/h2Color/h3Color):
        - titleColor, h1FontColor → h1Color
        - sectionColor, h2FontColor → h2Color
        - headerColor, h3FontColor → h3Color
        
        Per-Slide Overrides (HTML comments):
        - <!-- pagination: true/false -->
        - <!-- paginationStyle: minimal/fraction/text/progress/dots -->
        
        Special Slide Handling:
        - Empty slides are automatically skipped
        - Slides with <!-- intentionally blank --> comment are preserved as blank
        - No delimiters: Entire file treated as single slide with warning
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path
    )

    begin {
        Write-Verbose "Starting markdown parsing for: $Path"
        
        # Default settings
        $defaultSettings = @{
            background      = 'black'
            foreground      = 'white'
            border          = 'magenta'
            header          = $null
            footer          = $null
            pagination      = $false
            paginationStyle = 'minimal'
            borderStyle     = 'rounded'
            'h1'            = 'default'
            'h2'            = 'default'
            'h3'            = 'default'
            'h1Color'       = $null
            'h2Color'       = $null
            'h3Color'       = $null
        }
    }

    process {
        try {
            # Read the entire file
            $content = Get-Content -Path $Path -Raw
            
            # Extract YAML frontmatter
            $settings = $defaultSettings.Clone()
            $markdownContent = $content
            $contentStartLine = 1
            
            if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$') {
                $yamlContent = $Matches[1]
                $markdownContent = $Matches[2]
                
                # Calculate how many lines the frontmatter takes
                $frontmatterLines = ($yamlContent -split '\r?\n').Count + 2  # +2 for the --- delimiters
                $contentStartLine = $frontmatterLines + 1
                
                Write-Verbose "Found YAML frontmatter, parsing settings"
                
                # Parse YAML (simple key: value format)
                foreach ($line in ($yamlContent -split '\r?\n')) {
                    if ($line -match '^\s*([^:]+):\s*(.+?)\s*$') {
                        $key = $Matches[1].Trim()
                        $value = $Matches[2].Trim()
                        
                        # Remove quotes if present
                        $value = $value -replace '^["'']|["'']$', ''
                        
                        # Convert boolean strings
                        if ($value -eq 'true') {
                            $value = $true
                        } elseif ($value -eq 'false') {
                            $value = $false
                        }
                        
                        # Normalize font property aliases to canonical names
                        # titleFont/h1Font/h1 → h1, sectionFont/h2Font/h2 → h2, headerFont/h3Font/h3 → h3
                        if ($key -in @('titleFont', 'h1Font')) {
                            $key = 'h1'
                            Write-Verbose "  Normalized font alias to: h1"
                        } elseif ($key -in @('sectionFont', 'h2Font')) {
                            $key = 'h2'
                            Write-Verbose "  Normalized font alias to: h2"
                        } elseif ($key -in @('headerFont', 'h3Font')) {
                            $key = 'h3'
                            Write-Verbose "  Normalized font alias to: h3"
                        }
                        
                        # Normalize color property aliases
                        # titleColor/h1FontColor/h1Color → h1Color, etc.
                        if ($key -in @('titleColor', 'h1FontColor')) {
                            $key = 'h1Color'
                            Write-Verbose "  Normalized color alias to: h1Color"
                        } elseif ($key -in @('sectionColor', 'h2FontColor')) {
                            $key = 'h2Color'
                            Write-Verbose "  Normalized color alias to: h2Color"
                        } elseif ($key -in @('headerColor', 'h3FontColor')) {
                            $key = 'h3Color'
                            Write-Verbose "  Normalized color alias to: h3Color"
                        }
                        
                        # Store in settings
                        if ($settings.ContainsKey($key)) {
                            $settings[$key] = $value
                            Write-Verbose "  Setting: $key = $value"
                        } else {
                            Write-Warning "Unknown setting in frontmatter: $key"
                        }
                    }
                }
            } else {
                Write-Verbose "No YAML frontmatter found, using defaults"
            }
            
            # Split markdown into slides by horizontal rules (---, ***, ___)
            # BUT exclude horizontal rules inside code fences
            Write-Verbose "Splitting markdown into slides"
            
            # First, find all code blocks and replace them with placeholders
            $codeBlockPattern = '(?s)```.*?```'
            $codeBlocks = @{}
            $codeBlockIndex = 0
            $protectedContent = $markdownContent
            
            foreach ($match in [regex]::Matches($markdownContent, $codeBlockPattern)) {
                $placeholder = "___CODEBLOCK_${codeBlockIndex}___"
                $codeBlocks[$placeholder] = $match.Value
                $protectedContent = $protectedContent.Replace($match.Value, $placeholder)
                $codeBlockIndex++
            }
            
            # Now split by horizontal rules (which won't match rules inside code blocks)
            $slidePattern = '(?m)^(?:---|___|\*\*\*)[ \t]*\r?$'
            $slideContents = $protectedContent -split $slidePattern
            
            # Restore code blocks in each slide
            for ($i = 0; $i -lt $slideContents.Count; $i++) {
                foreach ($placeholder in $codeBlocks.Keys) {
                    $slideContents[$i] = $slideContents[$i].Replace($placeholder, $codeBlocks[$placeholder])
                }
            }
            
            # Check if any delimiters were found
            $noDelimiters = ($slideContents.Count -eq 1)
            if ($noDelimiters) {
                Write-Warning "No slide delimiters found. Treating entire content as single slide."
            }
            
            # Filter out empty slides and trim whitespace
            $slides = @()
            $slideNumber = 1
            $currentLineInContent = $contentStartLine
            
            foreach ($slideContent in $slideContents) {
                $trimmed = $slideContent.Trim()
                
                # Calculate line number in original file for this slide
                $slideStartLine = $currentLineInContent
                $slideLineCount = ($slideContent -split '\r?\n').Count
                $currentLineInContent += $slideLineCount + 1  # +1 for the delimiter line
                
                if ([string]::IsNullOrWhiteSpace($trimmed)) {
                    Write-Verbose "  Skipping empty slide section"
                    continue
                }
                
                # Check for intentionally blank slides
                if ($trimmed -match '<!--\s*intentionally\s+blank\s*-->') {
                    Write-Verbose "  Slide $slideNumber : Intentionally blank"
                    $slides += [PSCustomObject]@{
                        Number          = $slideNumber
                        Content         = $trimmed
                        IsBlank         = $true
                        LineNumber      = $slideStartLine
                    }
                    $slideNumber++
                    continue
                }
                
                Write-Verbose "  Slide $slideNumber : $(($trimmed -split '\r?\n')[0].Substring(0, [Math]::Min(50, ($trimmed -split '\r?\n')[0].Length)))..."
                
                # Parse pagination overrides from HTML comments (but not inside code blocks)
                # First, temporarily replace code blocks with placeholders
                $tempContent = $trimmed
                $codeBlockMatches = [regex]::Matches($tempContent, '(?s)```.*?```')
                $codeBlockPlaceholders = @{}
                $placeholderIndex = 0
                foreach ($match in $codeBlockMatches) {
                    $placeholder = "___CODEBLOCK_PLACEHOLDER_${placeholderIndex}___"
                    $codeBlockPlaceholders[$placeholder] = $match.Value
                    $tempContent = $tempContent.Replace($match.Value, $placeholder)
                    $placeholderIndex++
                }
                
                # Now parse overrides from content without code blocks
                $overrides = @{}
                if ($tempContent -match '<!--\s*pagination:\s*(true|false)\s*-->') {
                    $overrides['pagination'] = $Matches[1] -eq 'true'
                    Write-Verbose "    Override: pagination = $($overrides['pagination'])"
                }
                if ($tempContent -match '<!--\s*paginationStyle:\s*(\w+)\s*-->') {
                    $overrides['paginationStyle'] = $Matches[1]
                    Write-Verbose "    Override: paginationStyle = $($overrides['paginationStyle'])"
                }
                
                # Parse font overrides with alias normalization
                if ($tempContent -match '<!--\s*(?:titleFont|h1Font|h1):\s*([\w\-,.]+)\s*-->') {
                    $overrides['h1'] = $Matches[1]
                    Write-Verbose "    Override: h1 = $($overrides['h1'])"
                }
                if ($tempContent -match '<!--\s*(?:sectionFont|h2Font|h2):\s*([\w\-,.]+)\s*-->') {
                    $overrides['h2'] = $Matches[1]
                    Write-Verbose "    Override: h2 = $($overrides['h2'])"
                }
                if ($tempContent -match '<!--\s*(?:headerFont|h3Font|h3):\s*([\w\-,.]+)\s*-->') {
                    $overrides['h3'] = $Matches[1]
                    Write-Verbose "    Override: h3 = $($overrides['h3'])"
                }
                
                # Parse color overrides with alias normalization
                if ($tempContent -match '<!--\s*(?:titleColor|h1FontColor|h1Color):\s*(\w+)\s*-->') {
                    $overrides['h1Color'] = $Matches[1]
                    Write-Verbose "    Override: h1Color = $($overrides['h1Color'])"
                }
                if ($tempContent -match '<!--\s*(?:sectionColor|h2FontColor|h2Color):\s*(\w+)\s*-->') {
                    $overrides['h2Color'] = $Matches[1]
                    Write-Verbose "    Override: h2Color = $($overrides['h2Color'])"
                }
                if ($tempContent -match '<!--\s*(?:headerColor|h3FontColor|h3Color):\s*(\w+)\s*-->') {
                    $overrides['h3Color'] = $Matches[1]
                    Write-Verbose "    Override: h3Color = $($overrides['h3Color'])"
                }
                
                # Parse border overrides
                if ($tempContent -match '<!--\s*border:\s*(\w+)\s*-->') {
                    $overrides['border'] = $Matches[1]
                    Write-Verbose "    Override: border = $($overrides['border'])"
                }
                if ($tempContent -match '<!--\s*borderStyle:\s*(\w+)\s*-->') {
                    $overrides['borderStyle'] = $Matches[1]
                    Write-Verbose "    Override: borderStyle = $($overrides['borderStyle'])"
                }
                
                # Remove HTML comments from display content
                $contentWithoutComments = $trimmed -replace '<!--\s*pagination:\s*(true|false)\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*paginationStyle:\s*(\w+)\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:titleFont|h1Font|h1):\s*[\w\-,.]+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:sectionFont|h2Font|h2):\s*[\w\-,.]+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:headerFont|h3Font|h3):\s*[\w\-,.]+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:titleColor|h1FontColor|h1Color):\s*\w+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:sectionColor|h2FontColor|h2Color):\s*\w+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*(?:headerColor|h3FontColor|h3Color):\s*\w+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*border:\s*\w+\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*borderStyle:\s*\w+\s*-->\r?\n?', ''
                
                # Trim content after removing comments to eliminate blank lines
                $contentWithoutComments = $contentWithoutComments.Trim()
                
                $slides += [PSCustomObject]@{
                    Number          = $slideNumber
                    Content         = $contentWithoutComments
                    IsBlank         = $false
                    LineNumber      = $slideStartLine
                    Overrides       = $overrides
                }
                $slideNumber++
            }
            
            Write-Verbose "Found $($slides.Count) slides"
            
            # Return parsed data
            [PSCustomObject]@{
                Settings   = $settings
                Slides     = $slides
                SourcePath = $Path
            }
        } catch {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'MarkdownParsingFailed',
                [System.Management.Automation.ErrorCategory]::ParserError,
                $Path
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    end {
        Write-Verbose 'Markdown parsing complete'
    }
}
