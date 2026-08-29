function ConvertTo-TableCell {
    <#
    .SYNOPSIS
        Converts a markdown table cell string into Spectre Console markup.

    .DESCRIPTION
        Transforms a single table cell's inline markdown (bold, italic, code,
        strikethrough, HTML color tags, links) into Spectre Console markup via
        ConvertTo-SpectreMarkup. Markdown links [text](url) become clickable
        [link=url]text[/] hyperlinks in terminals that support OSC 8; elsewhere
        Spectre.Console degrades them to plain text.

        Leading list markers are NOT protected: a leading '- ' or '* ' (marker
        followed by whitespace) is treated as a bullet and converts to the bullet
        character, matching body-text behavior. Data like '-5%' (no space after the
        dash) is untouched because the bullet regex requires trailing whitespace.

    .PARAMETER Text
        The raw cell text. May be empty or whitespace.

    .EXAMPLE
        ConvertTo-TableCell -Text '[@jeffhicks](https://techhub.social/@JeffHicks)'

        Returns: '[link=https://techhub.social/@JeffHicks]@jeffhicks[/]'

    .EXAMPLE
        ConvertTo-TableCell -Text '<green>online</green>'

        Returns: '[green]online[/]'

    .EXAMPLE
        ConvertTo-TableCell -Text '- 5%'

        Returns: '• 5%' (leading '- ' is a bullet; use '-5%' for literal data)

    .OUTPUTS
        System.String. The cell content as Spectre Console markup.

    .NOTES
        Bullet conversion is inherited from ConvertTo-SpectreMarkup. Because a cell
        is a single line, the leading-marker regex applies at the start of the cell.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    process {
        # Links, bullets, and inline formatting are all handled by ConvertTo-SpectreMarkup.
        ConvertTo-SpectreMarkup -Text $Text
    }
}
