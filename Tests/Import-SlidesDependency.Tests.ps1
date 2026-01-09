BeforeAll {
    . $PSScriptRoot/../Private/Import-SlidesDependency.ps1
    . $PSScriptRoot/../Private/Show-SadFace.ps1
}

Describe 'Import-SlidesDependency' {
    Context 'When PwshSpectreConsole is available' {
        BeforeAll {
            Mock Import-Module { } -ParameterFilter { $Name -eq 'PwshSpectreConsole' }
        }

        It 'Should import PwshSpectreConsole successfully' {
            { Import-SlidesDependency } | Should -Not -Throw
            Should -Invoke Import-Module -Exactly 1 -ParameterFilter { $Name -eq 'PwshSpectreConsole' }
        }
    }

    Context 'When PwshSpectreConsole is not available but can be installed' {
        BeforeAll {
            Mock Import-Module { throw "Module not found" } -ParameterFilter { $Name -eq 'PwshSpectreConsole' }
            Mock Install-PSResource { }
            Mock Import-Module { } -ParameterFilter { $Name -eq 'PwshSpectreConsole' -and $ErrorAction -eq 'Stop' }
            Mock Show-SadFace { }
        }

        It 'Should attempt to install PwshSpectreConsole' {
            { Import-SlidesDependency -WarningAction SilentlyContinue } | Should -Not -Throw
            Should -Invoke Install-PSResource -Exactly 1
        }
    }

    Context 'When PwshSpectreConsole cannot be loaded or installed' {
        BeforeAll {
            Mock Import-Module { throw "Module not found" }
            Mock Install-PSResource { throw "Installation failed" }
            Mock Show-SadFace { }
        }

        It 'Should call Show-SadFace' {
            { Import-SlidesDependency -WarningAction SilentlyContinue -ErrorAction SilentlyContinue } | Should -Throw
            Should -Invoke Show-SadFace -Exactly 1
        }

        It 'Should throw a terminating error' {
            { Import-SlidesDependency -WarningAction SilentlyContinue } | Should -Throw -ErrorId 'DependencyLoadFailure'
        }
    }
}

Describe 'Show-SadFace' {
    Context 'When called' {
        BeforeAll {
            Mock Write-Host { }
        }

        It 'Should not throw errors' {
            { Show-SadFace } | Should -Not -Throw
        }

        It 'Should write output to host' {
            Show-SadFace
            Should -Invoke Write-Host -AtLeast 10
        }
    }
}
