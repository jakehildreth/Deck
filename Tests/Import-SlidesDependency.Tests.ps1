BeforeAll {
    . $PSScriptRoot/../Private/Import-SlidesDependency.ps1
    . $PSScriptRoot/../Private/Show-SadFace.ps1
}

Describe 'Import-SlidesDependency' {
    Context 'When PwshSpectreConsole is available' {
        It 'Should import PwshSpectreConsole successfully' {
            { Import-SlidesDependency } | Should -Not -Throw
        }
    }
}

Describe 'Show-SadFace' {
    Context 'When called' {
        It 'Should not throw errors' {
            { Show-SadFace } | Should -Not -Throw
        }
    }
}
