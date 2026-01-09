BeforeAll {
    # Import PwshSpectreConsole first to get the Color type
    Import-Module PwshSpectreConsole -ErrorAction Stop
    
    # Import the module
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $modulePath 'Slides.psd1') -Force
    
    # Create test markdown file
    $script:testDir = Join-Path $TestDrive 'show-slides-tests'
    New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
    
    $script:testFile = Join-Path $script:testDir 'test.md'
    $content = @'
---
background: Black
foreground: White
border: Blue
---

# Test Slide
'@
    Set-Content -Path $script:testFile -Value $content
}

Describe 'Show-Slides' {
    Context 'When using Spectre.Console.Color parameters' {
        It 'Should accept [Spectre.Console.Color] type for Background parameter' {
            $paramInfo = (Get-Command Show-Slides).Parameters['Background']
            $paramInfo.ParameterType.FullName | Should -Be 'Spectre.Console.Color'
        }

        It 'Should accept [Spectre.Console.Color] type for Foreground parameter' {
            $paramInfo = (Get-Command Show-Slides).Parameters['Foreground']
            $paramInfo.ParameterType.FullName | Should -Be 'Spectre.Console.Color'
        }

        It 'Should accept [Spectre.Console.Color] type for Border parameter' {
            $paramInfo = (Get-Command Show-Slides).Parameters['Border']
            $paramInfo.ParameterType.FullName | Should -Be 'Spectre.Console.Color'
        }
        
        It 'Should have optional parameters (not mandatory)' {
            $params = (Get-Command Show-Slides).Parameters
            $params['Background'].Attributes.Mandatory | Should -Contain $false
            $params['Foreground'].Attributes.Mandatory | Should -Contain $false
            $params['Border'].Attributes.Mandatory | Should -Contain $false
        }
    }
}
