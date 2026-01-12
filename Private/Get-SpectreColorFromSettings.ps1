function Get-SpectreColorFromSettings {
    <#
    .SYNOPSIS
        Converts a color name from settings to a Spectre.Console.Color object.

    .PARAMETER ColorName
        The color name from settings (e.g., 'cyan', 'Magenta1').

    .PARAMETER SettingName
        The name of the setting (for error messages).

    .EXAMPLE
        $color = Get-SpectreColorFromSettings -ColorName $Settings.border -SettingName 'border'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$ColorName,

        [Parameter(Mandatory = $true)]
        [string]$SettingName
    )

    if (-not $ColorName) {
        return $null
    }

    $titleCaseName = (Get-Culture).TextInfo.ToTitleCase($ColorName.ToLower())
    Write-Verbose "  $SettingName color: $titleCaseName"
    
    try {
        return [Spectre.Console.Color]::$titleCaseName
    } catch {
        Write-Warning "Invalid $SettingName color '$ColorName', using default"
        return $null
    }
}
