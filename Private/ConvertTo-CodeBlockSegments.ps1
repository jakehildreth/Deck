function ConvertTo-CodeBlockSegments {
    <#
    .SYNOPSIS
        Parses text content into segments of text and code blocks.

    .PARAMETER Content
        The text content to parse.

    .EXAMPLE
        $segments = ConvertTo-CodeBlockSegments -Content $bodyContent
        foreach ($segment in $segments) {
            if ($segment.Type -eq 'Code') {
                # Render code block
            } else {
                # Render text
            }
        }
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
