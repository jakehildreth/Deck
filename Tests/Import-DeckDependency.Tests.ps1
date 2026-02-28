BeforeAll {
    . $PSScriptRoot/../Private/Import-DeckDependency.ps1
    . $PSScriptRoot/../Private/Show-SadFace.ps1
}

Describe 'Import-DeckDependency' {
    Context 'When TextMate is available' {
        It 'Should import TextMate successfully' {
            { Import-DeckDependency } | Should -Not -Throw
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
