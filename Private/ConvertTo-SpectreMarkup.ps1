function ConvertTo-SpectreMarkup {
    <#
    .SYNOPSIS
        Converts markdown formatting to Spectre Console markup.

    .DESCRIPTION
        Transforms common markdown inline formatting (bold, italic, code, strikethrough)
        into Spectre Console markup tags for rich terminal rendering.

    .PARAMETER Text
        The text containing markdown formatting to convert.

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is **bold** and *italic* text"

        Returns: "This is [bold]bold[/] and [italic]italic[/] text"

    .NOTES
        Conversion order matters to handle overlapping patterns correctly.
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

        # Convert code blocks first (backticks) to avoid conflicts with other patterns
        # Inline code: `code` -> [grey on grey15]code[/]
        $result = $result -replace '`([^`]+)`', '[grey on grey15]$1[/]'

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
