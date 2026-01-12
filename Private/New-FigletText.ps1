function New-FigletText {
    <#
    .SYNOPSIS
        Creates a Spectre.Console.FigletText object with optional font and color.

    .PARAMETER Text
        The text to render as figlet.

    .PARAMETER FontPath
        Path to a .flf font file. If not provided or file doesn't exist, uses default font.

    .PARAMETER Color
        Optional Spectre.Console.Color for the figlet text.

    .PARAMETER Justification
        Text justification (Left, Center, Right). Default is Center.

    .EXAMPLE
        $figlet = New-FigletText -Text "Hello" -FontPath (Join-Path $PSScriptRoot '../Fonts/mini.flf') -Color $color
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$FontPath,

        [Parameter(Mandatory = $false)]
        [object]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Left', 'Center', 'Right')]
        [string]$Justification = 'Center'
    )

    # Create figlet with font if available
    if ($FontPath -and (Test-Path $FontPath)) {
        $font = [Spectre.Console.FigletFont]::Load($FontPath)
        $figlet = [Spectre.Console.FigletText]::new($font, $Text)
    } else {
        $figlet = [Spectre.Console.FigletText]::new($Text)
    }

    # Set justification
    $figlet.Justification = [Spectre.Console.Justify]::$Justification

    # Set color if provided
    if ($Color) {
        $figlet.Color = $Color
    }

    return $figlet
}
