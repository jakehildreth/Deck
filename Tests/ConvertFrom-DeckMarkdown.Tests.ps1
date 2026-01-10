BeforeAll {
    . $PSScriptRoot/../Private/ConvertFrom-DeckMarkdown.ps1
    
    # Create test markdown files
    $script:testDir = Join-Path $TestDrive 'SlideTests'
    New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
}

Describe 'ConvertFrom-DeckMarkdown' {
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
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.background | Should -Be 'blue'
            $result.Settings.foreground | Should -Be 'yellow'
            $result.Settings.border | Should -Be 'red'
            $result.Settings.pagination | Should -Be $true
        }

        It 'Should extract markdown content without frontmatter' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Slides[0].Content | Should -Not -Match '^---'
            $result.Slides[0].Content | Should -Match '# Test Slide'
        }

        It 'Should preserve default values for unspecified settings' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.paginationStyle | Should -Be 'minimal'
            $result.Settings.borderStyle | Should -Be 'rounded'
        }

        It 'Should return slide objects with properties' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Slides | Should -HaveCount 1
            $result.Slides[0].Number | Should -Be 1
            $result.Slides[0].Content | Should -Not -BeNullOrEmpty
            $result.Slides[0].IsBlank | Should -Be $false
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
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Settings.background | Should -Be 'black'
            $result.Settings.foreground | Should -Be 'white'
            $result.Settings.pagination | Should -Be $false
        }

        It 'Should return all markdown as single slide' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Slides | Should -HaveCount 1
            $result.Slides[0].Content | Should -Match '# Test Slide'
        }

        It 'Should warn about no slide delimiters' {
            $warnings = @()
            ConvertFrom-DeckMarkdown -Path $testFile -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
            $warnings | Should -Not -BeNullOrEmpty
            $warnings[0] | Should -Match 'No slide delimiters found'
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
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.background | Should -Be '#FF0000'
        }

        It 'Should handle quoted strings' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.header | Should -Be 'My Presentation'
        }

        It 'Should handle boolean false' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.pagination | Should -Be $false
        }
    }

    Context 'When file path is invalid' {
        It 'Should throw a validation error' {
            { ConvertFrom-DeckMarkdown -Path 'nonexistent.md' } | Should -Throw
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
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningVariable warnings -WarningAction SilentlyContinue
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Should still parse known settings' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile -WarningAction SilentlyContinue
            $result.Settings.background | Should -Be 'blue'
        }
    }

    Context 'When splitting slides by horizontal rules' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-multiple-slides.md'
            $content = @'
---
background: black
---

# First Slide

---

## Second Slide

---

### Third Slide

Content here
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should split by --- delimiter' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides | Should -HaveCount 3
        }

        It 'Should number slides correctly' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides[0].Number | Should -Be 1
            $result.Slides[1].Number | Should -Be 2
            $result.Slides[2].Number | Should -Be 3
        }

        It 'Should preserve slide content' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides[0].Content | Should -Match '# First Slide'
            $result.Slides[1].Content | Should -Match '## Second Slide'
            $result.Slides[2].Content | Should -Match '### Third Slide'
        }

        It 'Should mark slides as not blank' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides[0].IsBlank | Should -Be $false
            $result.Slides[1].IsBlank | Should -Be $false
            $result.Slides[2].IsBlank | Should -Be $false
        }
    }

    Context 'When splitting by different delimiter types' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-delimiters.md'
            $content = @'
# Slide 1

---

# Slide 2

***

# Slide 3

___

# Slide 4
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should split by ---, ***, and ___ delimiters' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides | Should -HaveCount 4
        }
    }

    Context 'When handling empty slides' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-empty-slides.md'
            $content = @'
# Slide 1

---

---

# Slide 2
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should skip empty slides' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides | Should -HaveCount 2
            $result.Slides[0].Content | Should -Match '# Slide 1'
            $result.Slides[1].Content | Should -Match '# Slide 2'
        }
    }

    Context 'When handling intentionally blank slides' {
        BeforeAll {
            $testFile = Join-Path $script:testDir 'test-blank-slides.md'
            $content = @'
# Slide 1

---

<!-- intentionally blank -->

---

# Slide 2
'@
            Set-Content -Path $testFile -Value $content
        }

        It 'Should include intentionally blank slides' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides | Should -HaveCount 3
        }

        It 'Should mark intentionally blank slides correctly' {
            $result = ConvertFrom-DeckMarkdown -Path $testFile
            $result.Slides[1].IsBlank | Should -Be $true
        }
    }
}
