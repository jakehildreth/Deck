function ConvertTo-CodeBlockSegments {
    <#
    .SYNOPSIS
        Parses text content into segments of text and code blocks.

    .DESCRIPTION
        Splits content into an ordered array of segments, each identified as either
        'Text' or 'Code'. This enables separate rendering logic for prose content
        versus code examples.
        
        The parser identifies fenced code blocks using the ``` delimiter and extracts:
        - Language identifier (optional, for syntax highlighting)
        - Code content (preserving whitespace and formatting)
        - Surrounding text segments
        
        This segmentation allows slide renderers to:
        - Apply syntax highlighting to code blocks
        - Escape special characters in code
        - Preserve code formatting (indentation, newlines)
        - Apply markdown conversion only to text segments
        - Filter bullets without affecting code examples
        
        If no code blocks are found, the entire content is returned as a single
        text segment.

    .PARAMETER Content
        The text content to parse. Can be empty string or $null.
        Supports both Unix (LF) and Windows (CRLF) line endings.

    .EXAMPLE
        $segments = ConvertTo-CodeBlockSegments -Content $bodyContent
        foreach ($segment in $segments) {
            if ($segment.Type -eq 'Code') {
                # Render code block with syntax highlighting
                Write-Host "Language: $($segment.Language)"
                Write-Host $segment.Content -ForegroundColor Gray
            } else {
                # Render text with markdown conversion
                $markup = ConvertTo-SpectreMarkup -Text $segment.Content
                Write-SpectreHost $markup
            }
        }

        Demonstrates typical usage pattern in slide renderers.

    .EXAMPLE
        $content = @'
Here is some text.

```powershell
Get-Process | Where-Object CPU -gt 100
```

And more text after.
'@
        $segments = ConvertTo-CodeBlockSegments -Content $content
        $segments.Count  # Returns: 3 (text, code, text)

        Parses content with one code block and text before/after.

    .EXAMPLE
        $content = @'
```python
def hello():
    print("Hello, World!")
```

```javascript
console.log("Hello!");
```
'@
        $segments = ConvertTo-CodeBlockSegments -Content $content
        foreach ($seg in $segments | Where-Object Type -eq 'Code') {
            Write-Host "Found $($seg.Language) code block"
        }

        Demonstrates multiple code blocks with different languages.

    .EXAMPLE
        $emptyContent = ""
        $segments = ConvertTo-CodeBlockSegments -Content $emptyContent
        $segments.Count  # Returns: 0

        Returns empty array for empty content.

    .OUTPUTS
        System.Object[]
        
        Returns an array of hashtables, each containing:
        - Type: 'Text' or 'Code'
        - Content: The text or code content
        - Language: (Code segments only) Optional language identifier
        
        Segments are ordered by appearance in source content.

    .NOTES
        Code Block Syntax:
        - Opening: ``` or ```language
        - Content: Everything between delimiters (whitespace preserved)
        - Closing: ```
        - Language is optional, used for syntax highlighting hints
        
        Regex Pattern:
        - Pattern: (?s)```(\w+)?\r?\n(.*?)\r?\n```
        - (?s): Dot matches newlines (DOTALL mode)
        - (\w+)?: Optional word characters for language
        - \r?\n: Flexible line ending handling (LF or CRLF)
        - (.*?): Non-greedy content capture
        
        Segment Structure:
        Text segment:
        @{
            Type = 'Text'
            Content = 'Text content'
        }
        
        Code segment:
        @{
            Type = 'Code'
            Language = 'powershell'  # Optional, may be empty
            Content = 'Code content'
        }
        
        Empty Content Handling:
        - Null or empty string: Returns empty array
        - Whitespace only: Returns single text segment with whitespace
        
        Use Cases:
        - Content slide rendering with mixed prose and code
        - Image slide left panel content parsing
        - Multi-column content with code examples
        - Bullet filtering while preserving code blocks
        
        Limitations:
        - Does not handle nested code blocks
        - Does not validate code block syntax
        - Language identifier must be single word (no spaces)
        - Unclosed code blocks may cause unexpected parsing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    if (-not $Content) {
        return @()
    }

    $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
    $segments = [System.Collections.Generic.List[object]]::new()
    $lastIndex = 0
    
    foreach ($match in [regex]::Matches($Content, $codeBlockPattern)) {
        # Add text before code block
        if ($match.Index -gt $lastIndex) {
            $textBefore = $Content.Substring($lastIndex, $match.Index - $lastIndex).Trim()
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
    if ($lastIndex -lt $Content.Length) {
        $textAfter = $Content.Substring($lastIndex).Trim()
        if ($textAfter) {
            $segments.Add(@{ Type = 'Text'; Content = $textAfter })
        }
    }
    
    # If no code blocks found, treat entire content as text
    if ($segments.Count -eq 0) {
        $segments.Add(@{ Type = 'Text'; Content = $Content })
    }
    
    return $segments.ToArray()
}
