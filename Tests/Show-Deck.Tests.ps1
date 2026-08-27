BeforeAll {
    # Import the module
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $modulePath 'Deck.psd1') -Force
    
    # Create test markdown files
    $script:testDir = Join-Path $TestDrive 'show-deck-tests'
    New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
    
    # Single slide test
    $script:singleSlideFile = Join-Path $script:testDir 'single.md'
    $singleContent = @'
---
background: Black
foreground: White
border: Blue
---

# Test Slide
'@
    Set-Content -Path $script:singleSlideFile -Value $singleContent
    
    # Multi-slide test
    $script:multiSlideFile = Join-Path $script:testDir 'multi.md'
    $multiContent = @'
---
background: Black
foreground: Cyan1
border: Magenta
---

# First Slide

---

## Second Slide

---

### Third Slide

Content here
'@
    Set-Content -Path $script:multiSlideFile -Value $multiContent
}

Describe 'Show-Deck' {
    Context 'Parameter Types' {
        It 'Should accept string for Path parameter' {
            $paramInfo = (Get-Command Show-Deck).Parameters['Path']
            $paramInfo.ParameterType.FullName | Should -Be 'System.String'
        }

        It 'Should accept switch for Strict parameter' {
            $paramInfo = (Get-Command Show-Deck).Parameters['Strict']
            $paramInfo.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter'
        }

        It 'Should accept int for StartSlide parameter' {
            $paramInfo = (Get-Command Show-Deck).Parameters['StartSlide']
            $paramInfo.ParameterType.FullName | Should -Be 'System.Int32'
        }

        It 'Should have only Path as mandatory' {
            $params = (Get-Command Show-Deck).Parameters
            $params['Path'].Attributes.Mandatory | Should -Contain $true
            $params['Strict'].Attributes.Mandatory | Should -Not -Contain $true
            $params['StartSlide'].Attributes.Mandatory | Should -Not -Contain $true
        }
    }

    Context 'File Validation' {
        It 'Should require Path parameter' {
            $paramInfo = (Get-Command Show-Deck).Parameters['Path']
            $paramInfo.Attributes.Mandatory | Should -Contain $true
        }
        
        It 'Should validate file exists' {
            $paramInfo = (Get-Command Show-Deck).Parameters['Path']
            $validateScript = $paramInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateScriptAttribute] }
            $validateScript | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Markdown Parsing' {
        It 'Should parse single slide presentation' {
            # Can't run interactive cmdlet, but can verify the file is valid
            Test-Path $script:singleSlideFile | Should -Be $true
            $content = Get-Content $script:singleSlideFile -Raw
            $content | Should -Match '# Test Slide'
        }
        
        It 'Should parse multi-slide presentation with delimiters' {
            Test-Path $script:multiSlideFile | Should -Be $true
            $content = Get-Content $script:multiSlideFile -Raw
            $content | Should -Match '---'
            ($content -split '---').Count | Should -BeGreaterThan 3
        }
    }
    
    Context 'Slide Type Detection' {
        It 'Should detect title slide pattern' {
            $titlePattern = '^\s*#\s+.+$'
            '# Test Title' | Should -Match $titlePattern
            '## Section' | Should -Not -Match $titlePattern
        }
        
        It 'Should detect section slide pattern' {
            $sectionPattern = '^\s*##\s+.+$'
            '## Test Section' | Should -Match $sectionPattern
            '# Title' | Should -Not -Match $sectionPattern
            '### Header' | Should -Not -Match $sectionPattern
        }
        
        It 'Should detect content slide with header' {
            $headerPattern = '^###\s+(.+?)(?:\r?\n|$)'
            '### Content Header' | Should -Match $headerPattern
            '## Section' | Should -Not -Match $headerPattern
        }
    }

    Context 'StartSlide Validation' {
        It 'Should throw a terminating error when StartSlide exceeds the slide count' {
            # multiSlideFile has 3 slides; 4 is out of range
            { Show-Deck -Path $script:multiSlideFile -StartSlide 4 } | Should -Throw -ErrorId 'StartSlideOutOfRange,Show-Deck'
        }

        It 'Should name the total slide count in the error message' {
            $errorMessage = $null
            try {
                Show-Deck -Path $script:multiSlideFile -StartSlide 99
            } catch {
                $errorMessage = $_.Exception.Message
            }
            $errorMessage | Should -Match '3'
            $errorMessage | Should -Match '99'
        }
    }
}
