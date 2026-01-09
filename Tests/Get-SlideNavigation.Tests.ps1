BeforeAll {
    Import-Module "$PSScriptRoot/../Deck.psd1" -Force
    . "$PSScriptRoot/../Private/Get-SlideNavigation.ps1"
}

Describe 'Get-SlideNavigation' {
    Context 'Forward Navigation Keys' {
        It 'Returns Next for Right Arrow key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(39, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }

        It 'Returns Next for Down Arrow key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(40, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }

        It 'Returns Next for Spacebar' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(32, ' ', 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }

        It 'Returns Next for Enter key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(13, [char]13, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }

        It 'Returns Next for N key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(78, 'n', 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }

        It 'Returns Next for Page Down key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(34, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Next'
        }
    }

    Context 'Backward Navigation Keys' {
        It 'Returns Previous for Left Arrow key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(37, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Previous'
        }

        It 'Returns Previous for Up Arrow key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(38, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Previous'
        }

        It 'Returns Previous for Backspace key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(8, [char]8, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Previous'
        }

        It 'Returns Previous for P key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(80, 'p', 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Previous'
        }

        It 'Returns Previous for Page Up key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(33, [char]0, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Previous'
        }
    }

    Context 'Exit Keys' {
        It 'Returns Exit for Escape key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(27, [char]27, 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Exit'
        }

        It 'Returns Exit for Ctrl+C' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(67, 'c', 'LeftCtrlPressed', $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'Exit'
        }
    }

    Context 'Unhandled Keys' {
        It 'Returns None for unhandled key' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(88, 'x', 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'None'
        }

        It 'Returns None for random character' {
            $key = [System.Management.Automation.Host.KeyInfo]::new(90, 'z', 0, $false)
            $result = Get-SlideNavigation -KeyInfo $key
            $result | Should -Be 'None'
        }
    }
}
