function ConvertTo-SpectreMarkup {
    <#
    .SYNOPSIS
        Converts markdown formatting to Spectre Console markup.

    .DESCRIPTION
        Transforms common markdown inline formatting into Spectre Console markup tags
        for rich terminal rendering. This enables markdown text to display with colors,
        bold, italic, and other formatting in the terminal.
        
        The conversion process handles:
        1. Protection of inline code blocks (backticks) from markup conversion
        2. HTML color tags (<color>text</color> and <span style="color:name">text</span>)
        3. Bold formatting (**text** or __text__)
        4. Italic formatting (*text* or _text_)
        5. Strikethrough formatting (~~text~~)
        6. Inline code styling with grey on grey15 background
        
        Conversion order matters to prevent conflicts between overlapping patterns.
        Code blocks are protected first using placeholders, then restored after all
        other conversions to prevent markdown inside code examples from being parsed.
        
        Image markdown syntax ![alt](url) is escaped to prevent Spectre.Console from
        attempting to parse it.

    .PARAMETER Text
        The text containing markdown formatting to convert. Can be empty string.
        Accepts pipeline input.

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is **bold** and *italic* text"

        Returns: "This is [bold]bold[/] and [italic]italic[/] text"

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "Use `Get-Process` to list processes"

        Returns: "Use [grey on grey15]Get-Process[/] to list processes"
        Inline code is styled with grey text on dark grey background.

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is <red>red text</red> and <cyan>cyan text</cyan>"

        Returns: "This is [red]red text[/] and [cyan]cyan text[/]"

    .EXAMPLE
        ConvertTo-SpectreMarkup -Text "This is <span style='color:magenta'>magenta</span>"

        Returns: "This is [magenta]magenta[/]"

    .EXAMPLE
        "Hello **world**" | ConvertTo-SpectreMarkup

        Demonstrates pipeline input. Returns: "Hello [bold]world[/]"

    .EXAMPLE
        $lines = @(
            "**Bold** text",
            "*Italic* text",
            "~~Strikethrough~~ text"
        )
        $lines | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }

        Converts multiple lines with different formatting types.

    .OUTPUTS
        System.String
        
        Returns the input text with markdown formatting converted to Spectre Console
        markup tags ([bold], [italic], [color], etc.).

    .NOTES
        Conversion Order (important to prevent conflicts):
        1. Escape image syntax (![...](...) → ![[...]](...))  
        2. Extract and protect inline code blocks with placeholders
        3. Convert HTML color tags to Spectre markup
        4. Convert bold (**text** and __text__)
        5. Convert italic (*text* and _text_)
        6. Convert strikethrough (~~text~~)
        7. Restore protected code blocks
        
        Markdown Patterns Supported:
        - Bold: **text** or __text__ → [bold]text[/]
        - Italic: *text* or _text_ → [italic]text[/]
        - Code: `text` → [grey on grey15]text[/] (with proper escaping)
        - Strikethrough: ~~text~~ → [strikethrough]text[/]
        - HTML color: <color>text</color> → [color]text[/]
        - Span color: <span style="color:name">text</span> → [name]text[/]
        
        Code Block Protection:
        - Inline code content is escaped using [Spectre.Console.Markup]::Escape()
        - Prevents special characters in code from being interpreted as markup
        - Temporarily replaced with placeholders during other conversions
        - Restored after all pattern matching complete
        
        Image Syntax Escaping:
        - ![alt](url) → ![[alt]](url)
        - Prevents Spectre.Console from parsing image references
        - Preserves image syntax for display as text
        
        Color Names:
        - Must match Spectre.Console.Color names (case-insensitive)
        - Examples: Red, Green, Blue, Cyan1, Magenta1, Yellow, White, Black
        - Invalid colors may cause rendering issues
        
        Not Supported:
        - Nested formatting (e.g., ***bold italic***)
        - Per-character coloring
        - Links [text](url) - displayed as-is
        - Block-level markdown (headers, lists, etc.) - handled by slide renderers
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
        # Use placeholders to prevent color tag regex from matching code content
        $codeBlocks = @{}
        $codeIndex = 0
        $result = [regex]::Replace($result, '`([^`]+)`', {
            param($match)
            $codeContent = $match.Groups[1].Value
            # Use Spectre's built-in escaping
            $escapedContent = [Spectre.Console.Markup]::Escape($codeContent)
            $codeMarkup = "[grey on grey15]$escapedContent[/]"
            # Store in placeholder
            $placeholder = "___INLINECODE_${codeIndex}___"
            $codeBlocks[$placeholder] = $codeMarkup
            $codeIndex++
            return $placeholder
        })

        # Convert HTML color tags to Spectre markup
        # <span style="color:colorname">text</span> -> [colorname]text[/]
        $result = $result -replace '<span\s+style=[''"]color:\s*([a-zA-Z][a-zA-Z0-9]*)[''"]>(.*?)</span>', '[$1]$2[/]'
        
        # Convert simple color tags: <colorname>text</colorname> -> [colorname]text[/]
        $result = $result -replace '<([a-zA-Z][a-zA-Z0-9]*)>(.*?)</\1>', '[$1]$2[/]'

        # Bold: **text** or __text__ -> [bold]text[/]
        $result = $result -replace '\*\*([^\*]+)\*\*', '[bold]$1[/]'
        $result = $result -replace '__([^_]+)__', '[bold]$1[/]'

        # Italic: *text* or _text_ -> [italic]text[/]
        # Must come after bold to avoid conflicts
        $result = $result -replace '(?<!\*)\*(?!\*)([^\*]+)(?<!\*)\*(?!\*)', '[italic]$1[/]'
        $result = $result -replace '(?<!_)_(?!_)([^_]+)(?<!_)_(?!_)', '[italic]$1[/]'

        # Strikethrough: ~~text~~ -> [strikethrough]text[/]
        $result = $result -replace '~~([^~]+)~~', '[strikethrough]$1[/]'

        # Restore code block placeholders
        foreach ($placeholder in $codeBlocks.Keys) {
            $result = $result.Replace($placeholder, $codeBlocks[$placeholder])
        }

        return $result
    }
}
