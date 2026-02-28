BeforeAll {
    # Dot-source all private functions needed
    Get-ChildItem -Path $PSScriptRoot/../Private/*.ps1 | ForEach-Object { . $_.FullName }
}

Describe 'New-TableRenderable' {
    Context 'Basic table parsing' {
        It 'Should return a renderable for a simple markdown table' {
            $md = @'
| Name | Value |
|------|-------|
| Foo  | 42    |
| Bar  | 99    |
'@
            $result = New-TableRenderable -RawTable $md
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw for a valid table' {
            $md = @'
| A | B | C |
|---|---|---|
| 1 | 2 | 3 |
'@
            { New-TableRenderable -RawTable $md } | Should -Not -Throw
        }
    }

    Context 'Alignment parsing' {
        It 'Should not throw for center-aligned columns' {
            $md = @'
| Col |
|:---:|
| val |
'@
            { New-TableRenderable -RawTable $md } | Should -Not -Throw
        }

        It 'Should not throw for right-aligned columns' {
            $md = @'
| Col |
|----:|
| val |
'@
            { New-TableRenderable -RawTable $md } | Should -Not -Throw
        }

        It 'Should not throw for mixed alignments' {
            $md = @'
| Left | Center | Right |
|:-----|:------:|------:|
| a    | b      | c     |
'@
            { New-TableRenderable -RawTable $md } | Should -Not -Throw
        }
    }

    Context 'Empty cells' {
        It 'Should handle cells with empty values without throwing' {
            $md = @'
| A | B |
|---|---|
|   | x |
| y |   |
'@
            { New-TableRenderable -RawTable $md } | Should -Not -Throw
        }
    }

    Context 'Single row' {
        It 'Should handle a table with only one data row' {
            $md = @'
| Item | Count |
|------|-------|
| only | 1     |
'@
            $result = New-TableRenderable -RawTable $md
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Centering' {
        It 'Should return a renderable when -Centered is specified' {
            $md = @'
| A | B |
|---|---|
| 1 | 2 |
'@
            $result = New-TableRenderable -RawTable $md -Centered
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return a different type when -Centered vs not' {
            $md = @'
| A | B |
|---|---|
| 1 | 2 |
'@
            $plain = New-TableRenderable -RawTable $md
            $centered = New-TableRenderable -RawTable $md -Centered
            $plain.GetType().Name | Should -Not -Be $centered.GetType().Name
        }
    }

    Context 'Edge cases' {
        It 'Should return a Text renderable for malformed input with fewer than 2 lines' {
            $result = New-TableRenderable -RawTable '| just a header |'
            $result | Should -BeOfType [Spectre.Console.Text]
        }
    }
}
