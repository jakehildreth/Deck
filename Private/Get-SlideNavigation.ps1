function Get-SlideNavigation {
    <#
    .SYNOPSIS
        Processes keyboard input and returns navigation action.

    .DESCRIPTION
        Reads a ConsoleKeyInfo object from keyboard input and determines the appropriate
        navigation action for presentation control. Maps multiple keys to standard actions
        for intuitive navigation.
        
        This function implements the navigation state machine for Deck presentations,
        translating physical key presses into logical navigation commands. It supports
        multiple keys for each action to accommodate different user preferences and
        keyboard layouts.
        
        The function is called in the main presentation loop after each ReadKey() call
        to determine what action to take (advance slide, go back, exit, etc.).

    .PARAMETER KeyInfo
        The KeyInfo object from $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').
        Contains VirtualKeyCode, Character, and ControlKeyState properties.

    .EXAMPLE
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        $action = Get-SlideNavigation -KeyInfo $key
        switch ($action) {
            'Next' { # Advance to next slide or reveal next bullet }
            'Previous' { # Go back to previous slide }
            'Exit' { # Exit presentation }
            'None' { # Unhandled key, ignore }
        }

        Standard usage pattern in presentation loop.

    .EXAMPLE
        # Simulate right arrow key press
        $key = [System.Management.Automation.Host.KeyInfo]::new(
            0, 39, $false, $false, $false
        )
        $action = Get-SlideNavigation -KeyInfo $key
        # Returns: 'Next'

        Demonstrates programmatic key simulation for testing.

    .EXAMPLE
        # Check multiple navigation keys
        $testKeys = @(
            @{ Code = 39; Expected = 'Next' },     # Right arrow
            @{ Code = 37; Expected = 'Previous' }, # Left arrow
            @{ Code = 27; Expected = 'Exit' }      # Escape
        )
        foreach ($test in $testKeys) {
            $key = [System.Management.Automation.Host.KeyInfo]::new(
                0, $test.Code, $false, $false, $false
            )
            $result = Get-SlideNavigation -KeyInfo $key
            Write-Host "Key $($test.Code): $result (expected: $($test.Expected))"
        }

        Demonstrates comprehensive navigation key testing.

    .OUTPUTS
        System.String
        
        Returns one of four navigation actions:
        - 'Next': Advance to next slide or reveal next bullet
        - 'Previous': Return to previous slide
        - 'Exit': Close presentation
        - 'None': Unrecognized key, no action

    .NOTES
        Navigation Key Mapping:
        
        Next (Forward) - VirtualKeyCode or Character:
        - Right Arrow (39)
        - Down Arrow (40)
        - Space (32)
        - Enter (13)
        - Page Down (34)
        - 'n' character
        
        Previous (Backward) - VirtualKeyCode or Character:
        - Left Arrow (37)
        - Up Arrow (38)
        - Backspace (8)
        - Page Up (33)
        - 'p' character
        
        Exit (Quit) - VirtualKeyCode or Character:
        - Escape (27)
        - 'q' character
        - Ctrl+C (character 'c' with Ctrl pressed)
        
        Design Rationale:
        - Arrow keys: Intuitive directional navigation
        - Space/Enter: Common presentation advancing keys
        - n/p: Vim-style navigation (next/previous)
        - Page Up/Down: Standard document navigation
        - q/Escape: Common quit keys
        - Ctrl+C: Standard terminal interrupt
        
        KeyInfo Properties:
        - VirtualKeyCode: Numeric key code (Win32 virtual key code)
        - Character: Character representation of key
        - ControlKeyState: Flags for Ctrl, Alt, Shift modifiers
        
        Bullet Reveal:
        - 'Next' action reveals one bullet at a time on content slides
        - Once all bullets shown, 'Next' advances to next slide
        - 'Previous' always goes to previous slide (no bullet hiding in reverse)
        
        Unhandled Keys:
        - Return 'None' for any unrecognized input
        - Presentation loop typically ignores 'None' actions
        - Allows future extension for additional commands
        
        Help Key:
        - '?' character shows help screen (handled in main loop, not here)
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
