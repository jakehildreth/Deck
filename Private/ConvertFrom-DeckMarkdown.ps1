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
            titleFont       = 'default'
            sectionFont     = 'default'
            headerFont      = 'default'
        }
    }

    process {
        try {
            # Read the entire file
            $content = Get-Content -Path $Path -Raw
            
            # Extract YAML frontmatter
            $settings = $defaultSettings.Clone()
            $markdownContent = $content
            
            if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)$') {
                $yamlContent = $Matches[1]
                $markdownContent = $Matches[2]
                
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
                        }
                        elseif ($value -eq 'false') {
                            $value = $false
                        }
                        
                        # Store in settings
                        if ($settings.ContainsKey($key)) {
                            $settings[$key] = $value
                            Write-Verbose "  Setting: $key = $value"
                        }
                        else {
                            Write-Warning "Unknown setting in frontmatter: $key"
                        }
                    }
                }
            }
            else {
                Write-Verbose "No YAML frontmatter found, using defaults"
            }
            
            # Split markdown into slides by horizontal rules (---, ***, ___)
            Write-Verbose "Splitting markdown into slides"
            $slidePattern = '(?m)^(?:---|___|\*\*\*)[ \t]*$'
            $slideContents = $markdownContent -split $slidePattern
            
            # Check if any delimiters were found
            $noDelimiters = ($slideContents.Count -eq 1)
            if ($noDelimiters) {
                Write-Warning "No slide delimiters found. Treating entire content as single slide."
            }
            
            # Filter out empty slides and trim whitespace
            $slides = @()
            $slideNumber = 1
            
            foreach ($slideContent in $slideContents) {
                $trimmed = $slideContent.Trim()
                
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
                    }
                    $slideNumber++
                    continue
                }
                
                Write-Verbose "  Slide $slideNumber : $(($trimmed -split '\r?\n')[0].Substring(0, [Math]::Min(50, ($trimmed -split '\r?\n')[0].Length)))..."
                
                $slides += [PSCustomObject]@{
                    Number          = $slideNumber
                    Content         = $trimmed
                    IsBlank         = $false
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
        }
        catch {
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
