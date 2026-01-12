function Get-BorderStyleFromSettings {
    <#
    .SYNOPSIS
        Gets border color and style from settings.

    .PARAMETER Settings
        The presentation settings hashtable.

    .EXAMPLE
        $borderInfo = Get-BorderStyleFromSettings -Settings $Settings
        $panel.BorderStyle = [Spectre.Console.Style]::new($borderInfo.Color)
        $panel.Border = [Spectre.Console.BoxBorder]::$borderInfo.Style
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Settings
    )

    $result = @{
        Color = $null
        Style = 'Rounded'
    }

    # Get border color
    if ($Settings.border) {
        $result.Color = Get-SpectreColorFromSettings -ColorName $Settings.border -SettingName 'Border'
    }

    # Get border style
    if ($Settings.borderStyle) {
        $result.Style = (Get-Culture).TextInfo.ToTitleCase($Settings.borderStyle.ToLower())
        Write-Verbose "  Border style: $($result.Style)"
    }

    return $result
}
