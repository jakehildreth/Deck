BeforeAll {
    . $PSScriptRoot/../Private/ConvertFrom-SlideMarkdown.ps1
    
    # Create test markdown files
    $script:testDir = Join-Path $TestDrive 'SlideTests'
    New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
}

Describe 'ConvertFrom-SlideMarkdown' {
    Context 'When parsing markdown with YAML frontmatter' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-with-yaml.md'
            $content = @'
---
background: blue
foreground: yellow
border: red
pagination: true
---

# Test Slide

Content here
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should parse YAML frontmatter correctly' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.background | Should -Be 'blue'
            $result.Settings.foreground | Should -Be 'yellow'
            $result.Settings.border | Should -Be 'red'
            $result.Settings.pagination | Should -Be $true
        }

        It 'Should extract markdown content without frontmatter' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.MarkdownContent | Should -Not -Match '^---'
            $result.MarkdownContent | Should -Match '# Test Slide'
        }

        It 'Should preserve default values for unspecified settings' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.paginationStyle | Should -Be 'minimal'
            $result.Settings.borderStyle | Should -Be 'rounded'
        }
    }

    Context 'When parsing markdown without YAML frontmatter' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-without-yaml.md'
            $content = @'
# Test Slide

Content here
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should use default settings' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.background | Should -Be 'black'
            $result.Settings.foreground | Should -Be 'white'
            $result.Settings.pagination | Should -Be $false
        }

        It 'Should return all markdown content' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.MarkdownContent | Should -Match '# Test Slide'
        }
    }

    Context 'When parsing YAML with different value types' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-value-types.md'
            $content = @'
---
background: "#FF0000"
header: "My Presentation"
pagination: false
paginationStyle: fraction
---

# Content
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should handle hex color values' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.background | Should -Be '#FF0000'
        }

        It 'Should handle quoted strings' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.header | Should -Be 'My Presentation'
        }

        It 'Should handle boolean false' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile
            $result.Settings.pagination | Should -Be $false
        }
    }

    Context 'When file path is invalid' {
        It 'Should throw a validation error' {
            { ConvertFrom-SlideMarkdown -Path 'nonexistent.md' } | Should -Throw
        }
    }

    Context 'When YAML contains unknown keys' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-unknown-keys.md'
            $content = @'
---
background: blue
unknownSetting: value
---

# Content
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should warn about unknown settings' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Should still parse known settings' {
            $result = ConvertFrom-SlideMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.background | Should -Be 'blue'
        }
    }
}
