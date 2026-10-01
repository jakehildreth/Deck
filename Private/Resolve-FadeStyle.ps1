function Resolve-FadeStyle {
    <#
    .SYNOPSIS
        Resolves the fade settings into a validated fade color name.

    .DESCRIPTION
        Reads fadeBullets and fadeColor from the slide settings and returns an object
        the slide renderers use to fade revealed-but-older progressive bullets.

        fadeColor is validated through Get-SpectreColorFromSettings so an invalid name
        warns once and falls back to the adaptive 'dim' style instead of throwing a
        Spectre markup parse error at render time. When fadeColor is valid, its
        normalized lowercase name is returned for use in markup tags.

    .PARAMETER Settings
        The merged slide settings hashtable.

    .EXAMPLE
        $fade = Resolve-FadeStyle -Settings $Settings
        # $fade.Enabled  -> $true/$false
        # $fade.Color    -> validated color name, or $null for dim

    .OUTPUTS
        PSCustomObject with Enabled ([bool]) and Color ([string] or $null).

    .NOTES
        Returns Enabled = $false when fadeBullets is not set to $true, so callers can
        skip all fade work cheaply.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    process {
        $enabled = $Settings.fadeBullets -eq $true
        $color = $null
        if ($enabled -and -not [string]::IsNullOrWhiteSpace($Settings.fadeColor)) {
            $resolved = Get-SpectreColorFromSettings -ColorName $Settings.fadeColor -SettingName 'fadeColor'
            if ($resolved) {
                $color = $resolved.ToString().ToLower()
            }
            # $null on invalid name -> dim fallback (already warned by the resolver)
        }

        [PSCustomObject]@{
            Enabled = $enabled
            Color   = $color
        }
    }
}
