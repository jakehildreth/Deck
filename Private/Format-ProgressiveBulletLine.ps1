function Format-ProgressiveBulletLine {
    <#
    .SYNOPSIS
        Converts a raw bullet line to Spectre markup, applying the fade tone.

    .DESCRIPTION
        Centralizes the fade behavior for progressive (*) bullets shared by the
        content, image, and multi-column slide renderers.

        The raw line is first converted to Spectre markup via ConvertTo-SpectreMarkup
        (bullet marker becomes the • glyph, inline colors/bold/links are converted).
        The fade is then applied at the markup stage:

        - No -Fade switch (the newest revealed bullet, or fadeBullets off): the
          converted markup is returned unchanged, full strength.
        - -Fade with no -FadeColor: the converted line is wrapped in the [dim]
          decoration. dim lowers the luminosity of whatever foreground colors the
          line already has, so it composes with inline colors.
        - -Fade with a -FadeColor: inner foreground-color tags are rewritten to the
          fade color so the fixed tone takes precedence over inline colors, then the
          line is wrapped in that color. Any background (` on <color>`) stays
          attached to the rewritten tag, and non-color decorations (bold, italic,
          strikethrough, underline, link) are preserved.

    .PARAMETER Line
        The raw markdown line to convert and optionally fade.

    .PARAMETER Fade
        Switch. When present, the line is faded (revealed-but-older bullets). When
        absent, the line renders at full strength.

    .PARAMETER FadeColor
        The validated fade color name (already resolved via Get-SpectreColorFromSettings).
        When null or empty, the adaptive 'dim' style is used.

    .EXAMPLE
        Format-ProgressiveBulletLine -Line '* first' -Fade

        Returns: "[dim]• first[/]"

    .EXAMPLE
        Format-ProgressiveBulletLine -Line '* <red>alert</red>' -Fade -FadeColor 'grey19'

        Returns: "[grey19]• [grey19]alert[/][/]". The fixed grey overrides the red.

    .EXAMPLE
        Format-ProgressiveBulletLine -Line '* current'

        Returns: "• current". Without -Fade the line is not faded.

    .OUTPUTS
        System.String. Spectre markup for the line.

    .NOTES
        Inner foreground-color replacement targets only color open tags. Decoration
        and link open tags are matched by name and left intact, and closing [/] tags
        are untouched, so markup stays balanced.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line,

        [Parameter(Mandatory = $false)]
        [switch]$Fade,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FadeColor
    )

    process {
        $converted = ConvertTo-SpectreMarkup -Text $Line

        if (-not $Fade.IsPresent) {
            return $converted
        }

        if ([string]::IsNullOrWhiteSpace($FadeColor)) {
            # Adaptive fade: dim composes over existing foreground colors
            return "[dim]$converted[/]"
        }

        # Fixed fade color takes precedence: rewrite inner foreground-color open tags
        # to the fade color, retaining any background (` on <color>`) suffix. The
        # negative lookahead keeps decorations, links, and closing [/] tags intact.
        $recolored = $converted -replace "\[(?!(?:bold|italic|strikethrough|underline|dim|invert|conceal|slowblink|rapidblink|link|/))(?:[a-zA-Z][a-zA-Z0-9]*)(\s+on\s+[^\]]+)?\]", "[$FadeColor`${1}]"
        return "[$FadeColor]$recolored[/]"
    }
}
