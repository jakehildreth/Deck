function New-CodeBlockPanel {
    <#
    .SYNOPSIS
        Creates a Spectre.Console Panel renderable for a code block, with optional syntax highlighting.

    .DESCRIPTION
        Builds a bordered panel containing code content. When the TextMate module is available
        and the specified language is supported, code is syntax-highlighted via Format-TextMate.
        Otherwise, falls back to plain monochrome rendering using Spectre.Console.Markup with
        escaped content.

        The panel uses a Rounded border style with consistent padding (2 horizontal, 1 vertical)
        and optionally displays the language name as a panel header.

    .PARAMETER Content
        The raw code text to render inside the panel.

    .PARAMETER Language
        The language identifier for syntax highlighting (e.g., 'powershell', 'csharp', 'python').
        Used as the panel header label and passed to Format-TextMate for tokenization.
        When empty or unsupported, rendering falls back to plain monochrome text.

    .PARAMETER Centered
        When specified, wraps the panel in Format-SpectreAligned with Center horizontal alignment.

    .EXAMPLE
        New-CodeBlockPanel -Content 'Get-Process | Select-Object -First 5' -Language 'powershell'

        Returns a syntax-highlighted panel with a 'powershell' header.

    .EXAMPLE
        New-CodeBlockPanel -Content 'some code' -Language 'brainfuck'

        Returns a plain monochrome panel (unsupported language fallback) with a 'brainfuck' header.

    .EXAMPLE
        New-CodeBlockPanel -Content '$x = 1' -Language 'powershell' -Centered

        Returns a centered, syntax-highlighted panel.

    .OUTPUTS
        Spectre.Console.IRenderable. A Panel (or aligned Panel) renderable for composition into slide layouts.

    .NOTES
        Requires TextMate module (loaded transitively via Import-DeckDependency).
        Falls back gracefully when TextMate or the requested language grammar is unavailable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Content,

        [Parameter()]
        [string]$Language,

        [Parameter()]
        [switch]$Centered
    )

    process {
        # Determine if we can syntax-highlight this language
        $useHighlighting = $false
        if ($Language) {
            try {
                $useHighlighting = Test-TextMate -Language $Language
            } catch {
                Write-Verbose "Test-TextMate failed for language '$Language': $_"
                $useHighlighting = $false
            }
        }

        if ($useHighlighting) {
            Write-Verbose "Syntax highlighting code block with language: $Language"
            $formatParams = @{
                Language = $Language
            }
            # Markdown language uses a specialized renderer that renders the markdown
            # rather than showing raw source. Use -Alternate to force the standard
            # tokenizer so code blocks display raw markdown with syntax highlighting.
            if ($Language -eq 'markdown') {
                $formatParams['Alternate'] = $true
            }
            $codeRenderable = $Content | Format-TextMate @formatParams
        } else {
            Write-Verbose "Falling back to plain text for code block (language: $Language)"
            $escapedContent = [Spectre.Console.Markup]::Escape($Content)
            $codeRenderable = [Spectre.Console.Markup]::new($escapedContent)
        }

        # Wrap in a panel with rounded border and consistent padding
        $codePanel = [Spectre.Console.Panel]::new($codeRenderable)
        $codePanel.Border = [Spectre.Console.BoxBorder]::Rounded
        $codePanel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)

        if ($Language) {
            $codePanel.Header = [Spectre.Console.PanelHeader]::new($Language)
        }

        if ($Centered) {
            $codePanel = Format-SpectreAligned -Data $codePanel -HorizontalAlignment Center
        }

        $codePanel
    }
}
