BeforeAll {
    # Dot-source all private functions needed
    Get-ChildItem -Path $PSScriptRoot/../Private/*.ps1 | ForEach-Object { . $_.FullName }
}

Describe 'New-CodeBlockPanel' {
    Context 'When language is supported by TextMate' {
        It 'Should return a renderable without throwing' {
            { New-CodeBlockPanel -Content 'Get-Process' -Language 'powershell' } | Should -Not -Throw
        }

        It 'Should return a Panel or aligned renderable' {
            $result = New-CodeBlockPanel -Content 'Get-Process' -Language 'powershell'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return a centered renderable when -Centered is specified' {
            $result = New-CodeBlockPanel -Content 'Get-Process' -Language 'powershell' -Centered
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When language is not supported by TextMate' {
        It 'Should fall back to plain text without throwing' {
            { New-CodeBlockPanel -Content 'some code' -Language 'brainfuck' } | Should -Not -Throw
        }

        It 'Should return a Panel renderable for unsupported languages' {
            $result = New-CodeBlockPanel -Content 'some code' -Language 'brainfuck'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Spectre.Console.Panel]
        }
    }

    Context 'When no language is specified' {
        It 'Should return a Panel without a header' {
            $result = New-CodeBlockPanel -Content 'plain code block'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Spectre.Console.Panel]
            $result.Header | Should -BeNullOrEmpty
        }
    }

    Context 'Panel structure' {
        It 'Should use Rounded border style' {
            $result = New-CodeBlockPanel -Content 'test' -Language 'brainfuck'
            $result.Border | Should -Be ([Spectre.Console.BoxBorder]::Rounded)
        }

        It 'Should set language as panel header when language is provided' {
            $result = New-CodeBlockPanel -Content 'test' -Language 'python'
            $result.Header | Should -Not -BeNullOrEmpty
        }
    }
}
