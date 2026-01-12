function ConvertTo-SpectreMarkup {
    <#
    .SYNOPSIS
        Converts markdown formatting to Spectre Console markup.

    .DESCRIPTION
        Transforms common markdown inline formatting (bold, italic, code, strikethrough, colors)
        into Spectre Console markup tags for rich terminal rendering.

    .PARAMETER Text
        The text containing markdown formatting to convert.

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is **bold** and *italic* text"

        Returns: "This is [bold]bold[/] and [italic]italic[/] text"

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is <span style='color:red'>red text</span>"

        Returns: "This is [red]red text[/]"

    .NOTES
        Conversion order matters to handle overlapping patterns correctly.
        Supports HTML color tags: <span style="color:colorname">text</span> and <colorname>text</colorname>.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    process {
        $result = $Text

        # Escape markdown image syntax before other conversions to prevent Spectre from parsing it
        # ![alt](url) or ![alt](url){width=N} -> escaped brackets
        $result = $result -replace '!\[([^\]]*)\]\(([^)]+)\)(\{width=\d+\})?', '![[${1}]]($2)$3'

        # Convert code blocks FIRST (backticks) to protect code from other formatting
        # Inline code: `code` -> [grey on grey15]escaped_code[/]
        # Escape angle brackets in code to prevent them being parsed as HTML/color tags
        $result = [regex]::Replace($result, '`([^`]+)`', {
            param($match)
            $codeContent = $match.Groups[1].Value
            # Escape angle brackets and square brackets
            $codeContent = $codeContent -replace '<', '&lt;'
            $codeContent = $codeContent -replace '>', '&gt;'
            $codeContent = $codeContent -replace '\[', '&#91;'
            $codeContent = $codeContent -replace '\]', '&#93;'
            "[grey on grey15]$codeContent[/]"
        })

        # Convert HTML color tags to Spectre markup
        # <span style="color:colorname">text</span> -> [colorname]text[/]
        $result = $result -replace '<span\s+style=[''"]color:\s*([a-zA-Z][a-zA-Z0-9]*)[''"]>([^<]*?)</span>', '[$1]$2[/]'
        
        # Convert simple color tags: <colorname>text</colorname> -> [colorname]text[/]
        $result = $result -replace '<([a-zA-Z][a-zA-Z0-9]*)>([^<]*?)</\1>', '[$1]$2[/]'

        # Bold: **text** or __text__ -> [bold]text[/]
        $result = $result -replace '\*\*([^\*]+)\*\*', '[bold]$1[/]'
        $result = $result -replace '__([^_]+)__', '[bold]$1[/]'

        # Italic: *text* or _text_ -> [italic]text[/]
        # Must come after bold to avoid conflicts
        $result = $result -replace '(?<!\*)\*(?!\*)([^\*]+)(?<!\*)\*(?!\*)', '[italic]$1[/]'
        $result = $result -replace '(?<!_)_(?!_)([^_]+)(?<!_)_(?!_)', '[italic]$1[/]'

        # Strikethrough: ~~text~~ -> [strikethrough]text[/]
        $result = $result -replace '~~([^~]+)~~', '[strikethrough]$1[/]'

        return $result
    }
}
