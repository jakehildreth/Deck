function Get-TerminalSyncSupport {
    <#
    .SYNOPSIS
        Detects whether the current terminal supports ANSI synchronized output (mode 2026).

    .DESCRIPTION
        Checks well-known environment variables to determine if the host terminal
        supports the ANSI/DEC synchronized output extension (private mode 2026).
        When supported, wrapping render output in ESC[?2026h / ESC[?2026l causes the
        terminal to buffer all output and flip it atomically, eliminating flicker on
        slide transitions.

        Supported terminals detected:
        - Windows Terminal  (WT_SESSION is set)
        - iTerm2            (TERM_PROGRAM = 'iTerm.app')
        - WezTerm           (TERM_PROGRAM = 'WezTerm')
        - Ghostty           (TERM_PROGRAM = 'ghostty' or TERM = 'xterm-ghostty')
        - Kitty             (TERM = 'xterm-kitty')

        Terminals that do NOT advertise support simply ignore the escape sequences,
        so emitting them on unsupported terminals is safe. This function exists to
        avoid unnecessary overhead rather than for safety.

    .EXAMPLE
        $useSyncOutput = Get-TerminalSyncSupport
        if ($useSyncOutput) { Write-Host "`e[?2026h" -NoNewline }
        # ... clear + render ...
        if ($useSyncOutput) { Write-Host "`e[?2026l" -NoNewline }

        Wrap a render block in synchronized output mode for flicker-free transitions.

    .EXAMPLE
        $useSyncOutput = Get-TerminalSyncSupport
        Write-Verbose "Synchronized output supported: $useSyncOutput"

        Store the result once before the render loop to avoid repeated env var lookups.

    .OUTPUTS
        System.Boolean

        Returns $true if the current terminal is known to support synchronized output
        mode 2026; $false otherwise.

    .NOTES
        Detection uses environment variables rather than DECRQM queries (ESC[?2026$p)
        because querying terminal capabilities in PowerShell requires reading stdin
        asynchronously, which is fragile across platforms and terminal emulators.

        If a terminal supports mode 2026 but is not listed here, the ESC[?2026h/l
        sequences are harmlessly ignored. This function is conservative by design.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    process {
        # Windows Terminal sets WT_SESSION to a GUID when active
        if (-not [string]::IsNullOrEmpty($env:WT_SESSION)) {
            return $true
        }

        # iTerm2, WezTerm, and Ghostty advertise via TERM_PROGRAM
        if ($env:TERM_PROGRAM -in 'iTerm.app', 'WezTerm', 'ghostty') {
            return $true
        }

        # Kitty and Ghostty set unique TERM values
        if ($env:TERM -in 'xterm-kitty', 'xterm-ghostty') {
            return $true
        }

        return $false
    }
}
