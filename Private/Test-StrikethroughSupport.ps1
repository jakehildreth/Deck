function Test-StrikethroughSupport {
    <#
    .SYNOPSIS
        Detects whether the current terminal likely supports strikethrough rendering.

    .DESCRIPTION
        Spectre.Console exposes no capability flag for strikethrough, so support is
        inferred from terminal environment variables. Returns $true when a terminal
        known to render DECORATIONS Strikethrough is detected.

        Detection heuristics (any match = supported):
        - WT_SESSION set            -> Windows Terminal
        - TERM_PROGRAM matches      -> iTerm.app, WezTerm, vscode, ghostty, Apple_Terminal
        - TERM contains             -> xterm-256color, screen-256color, tmux-256color

        Override the result by setting DECK_STRIKETHROUGH to 'true' or 'false'.

    .EXAMPLE
        if (-not (Test-StrikethroughSupport)) { Write-Warning 'No strikethrough' }

        Warns when the terminal is not known to support strikethrough.

    .EXAMPLE
        $env:DECK_STRIKETHROUGH = 'false'
        Test-StrikethroughSupport   # returns $false regardless of terminal

        Forces the unsupported path via the override variable.

    .OUTPUTS
        System.Boolean. $true when strikethrough is likely supported.

    .NOTES
        This is a heuristic. A terminal that reports xterm-256color may still not
        render strikethrough; the DECK_STRIKETHROUGH override exists for that case.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    # Explicit override wins over detection
    if ($env:DECK_STRIKETHROUGH) {
        return $env:DECK_STRIKETHROUGH -eq 'true'
    }

    if ($env:WT_SESSION) { return $true }

    if ($env:TERM_PROGRAM -match '^(iTerm\.app|WezTerm|vscode|ghostty|Apple_Terminal)$') { return $true }

    if ($env:TERM -match '(xterm|screen|tmux)-256color') { return $true }

    return $false
}
