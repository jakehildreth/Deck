BeforeAll {
    . $PSScriptRoot/../Private/Get-TerminalSyncSupport.ps1

    $script:origWtSession   = $env:WT_SESSION
    $script:origTermProgram = $env:TERM_PROGRAM
    $script:origTerm        = $env:TERM
}

AfterAll {
    $env:WT_SESSION   = $script:origWtSession
    $env:TERM_PROGRAM = $script:origTermProgram
    $env:TERM         = $script:origTerm
}

Describe 'Get-TerminalSyncSupport' {

    BeforeEach {
        Remove-Item Env:WT_SESSION   -ErrorAction SilentlyContinue
        Remove-Item Env:TERM_PROGRAM -ErrorAction SilentlyContinue
        Remove-Item Env:TERM         -ErrorAction SilentlyContinue
    }

    Context 'Return type' {
        It 'Should return a bool' {
            $result = Get-TerminalSyncSupport
            $result | Should -BeOfType [bool]
        }
    }

    Context 'When running in Windows Terminal' {
        It 'Should return true when WT_SESSION is set to a non-empty value' {
            $env:WT_SESSION = '{a7ebc4d2-1234-4abc-b09f-000000000001}'
            Get-TerminalSyncSupport | Should -BeTrue
        }

        It 'Should return false when WT_SESSION is empty string' {
            $env:WT_SESSION = ''
            Get-TerminalSyncSupport | Should -BeFalse
        }
    }

    Context 'When running in iTerm2' {
        It 'Should return true when TERM_PROGRAM is iTerm.app' {
            $env:TERM_PROGRAM = 'iTerm.app'
            Get-TerminalSyncSupport | Should -BeTrue
        }
    }

    Context 'When running in WezTerm' {
        It 'Should return true when TERM_PROGRAM is WezTerm' {
            $env:TERM_PROGRAM = 'WezTerm'
            Get-TerminalSyncSupport | Should -BeTrue
        }
    }

    Context 'When running in Kitty' {
        It 'Should return true when TERM is xterm-kitty' {
            $env:TERM = 'xterm-kitty'
            Get-TerminalSyncSupport | Should -BeTrue
        }
    }

    Context 'When running in Ghostty' {
        It 'Should return true when TERM is xterm-ghostty' {
            $env:TERM = 'xterm-ghostty'
            Get-TerminalSyncSupport | Should -BeTrue
        }

        It 'Should return true when TERM_PROGRAM is ghostty' {
            $env:TERM_PROGRAM = 'ghostty'
            Get-TerminalSyncSupport | Should -BeTrue
        }
    }

    Context 'When running in an unsupported terminal' {
        It 'Should return false when no known env vars are set' {
            Get-TerminalSyncSupport | Should -BeFalse
        }

        It 'Should return false for Terminal.app (macOS default)' {
            $env:TERM_PROGRAM = 'Apple_Terminal'
            Get-TerminalSyncSupport | Should -BeFalse
        }

        It 'Should return false for VS Code integrated terminal' {
            $env:TERM_PROGRAM = 'vscode'
            Get-TerminalSyncSupport | Should -BeFalse
        }

        It 'Should return false for standard xterm-256color TERM' {
            $env:TERM = 'xterm-256color'
            Get-TerminalSyncSupport | Should -BeFalse
        }

        It 'Should return false for screen TERM' {
            $env:TERM = 'screen'
            Get-TerminalSyncSupport | Should -BeFalse
        }
    }

    Context 'Precedence and edge cases' {
        It 'Should return true when both WT_SESSION and TERM_PROGRAM are set' {
            $env:WT_SESSION   = '{some-guid}'
            $env:TERM_PROGRAM = 'iTerm.app'
            Get-TerminalSyncSupport | Should -BeTrue
        }

        It 'Should return true when WT_SESSION is set regardless of TERM value' {
            $env:WT_SESSION = '{some-guid}'
            $env:TERM       = 'xterm-256color'
            Get-TerminalSyncSupport | Should -BeTrue
        }
    }
}
