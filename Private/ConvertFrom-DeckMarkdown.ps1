function ConvertFrom-DeckMarkdown {
    <#
    .SYNOPSIS
        Parses markdown file for slide presentation data.

    .DESCRIPTION
        Extracts YAML frontmatter settings and parses the markdown content into individual slides.
        Returns a structured object containing global settings and slide data.

    .PARAMETER Path
        Path to the markdown file to parse.

    .EXAMPLE
        ConvertFrom-DeckMarkdown -Path ".\presentation.md"
        Parses the markdown file and returns slide data.

    .OUTPUTS
        PSCustomObject with Settings and Slides properties.

    .NOTES
        Handles YAML frontmatter extraction and slide splitting by horizontal rules.
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
            $allLines = Get-Content -Path $Path
            
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
                
                # Remove HTML comments from display content
                $contentWithoutComments = $trimmed -replace '<!--\s*pagination:\s*(true|false)\s*-->\r?\n?', ''
                $contentWithoutComments = $contentWithoutComments -replace '<!--\s*paginationStyle:\s*(\w+)\s*-->\r?\n?', ''
                
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
