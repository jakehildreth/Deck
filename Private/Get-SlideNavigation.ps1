function Get-SlideNavigation {
    <#
    .SYNOPSIS
        Processes keyboard input and returns navigation action.

    .DESCRIPTION
        Reads a ConsoleKeyInfo object and determines the appropriate navigation
        action (Next, Previous, Exit, or None).

    .PARAMETER KeyInfo
        The KeyInfo object from $Host.UI.RawUI.ReadKey().

    .OUTPUTS
        [string] One of: 'Next', 'Previous', 'Exit', 'None'

    .EXAMPLE
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        $action = Get-SlideNavigation -KeyInfo $key
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Host.KeyInfo]
        $KeyInfo
    )

    # Forward navigation
    if ($KeyInfo.VirtualKeyCode -in @(39, 40, 32, 13, 34) -or $KeyInfo.Character -eq 'n') {
        # 39=Right, 40=Down, 32=Space, 13=Enter, 34=PageDown
        return 'Next'
    }

    # Backward navigation
    if ($KeyInfo.VirtualKeyCode -in @(37, 38, 8, 33) -or $KeyInfo.Character -eq 'p') {
        # 37=Left, 38=Up, 8=Backspace, 33=PageUp
        return 'Previous'
    }

    # Exit
    if ($KeyInfo.VirtualKeyCode -eq 27 -or 
        $KeyInfo.Character -eq 'q' -or
        ($KeyInfo.Character -eq 'c' -and $KeyInfo.ControlKeyState -match 'LeftCtrlPressed|RightCtrlPressed')) {
        # 27=Escape, q, c with Ctrl
        return 'Exit'
    }

    # Unhandled
    return 'None'
}
