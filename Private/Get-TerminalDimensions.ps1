function Get-TerminalDimensions {
    <#
    .SYNOPSIS
        Gets the terminal window dimensions.

    .EXAMPLE
        $dimensions = Get-TerminalDimensions
        $width = $dimensions.Width
        $height = $dimensions.Height
    #>
    [CmdletBinding()]
    param()

    return @{
        Width = $Host.UI.RawUI.WindowSize.Width
        Height = $Host.UI.RawUI.WindowSize.Height - 1
    }
}
