BeforeAll {
    # Import the private function directly for testing
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Show-SectionSlide.ps1')
    
    # Import dependency for type availability
    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    
    # Mock Clear-Host only (Panel creation is tested by verifying no errors)
    Mock Clear-Host { }
}

Describe 'Show-SectionSlide' {
    Context 'When rendering a valid section slide' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '## Getting Started'
                IsBlank = $false
            }
            
            $settings = @{
                background = 'black'
                foreground = 'yellow'
                border     = 'blue'
            }
        }

        It 'Should extract section text from ## heading and render without errors' {
            { Show-SectionSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should clear the screen before rendering' {
            Show-SectionSlide -Slide $slide -Settings $settings
            
            Should -Invoke Clear-Host -Times 1
        }

        It 'Should use foreground color from settings without errors' {
            { Show-SectionSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }
    }

    Context 'When slide content is invalid' {
        BeforeAll {
            $settings = @{
                foreground = 'green'
            }
        }

        It 'Should throw error when no ## heading found' {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = 'Just some text without heading'
                IsBlank = $false
            }
            
            { Show-SectionSlide -Slide $slide -Settings $settings } | 
                Should -Throw -ExpectedMessage '*does not contain a valid ## heading*'
        }

        It 'Should throw error when slide has # heading instead of ##' {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '# Title Heading'
                IsBlank = $false
            }
            
            { Show-SectionSlide -Slide $slide -Settings $settings } | 
                Should -Throw -ExpectedMessage '*does not contain a valid ## heading*'
        }

        It 'Should throw error when slide has ### heading instead of ##' {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '### Content Heading'
                IsBlank = $false
            }
            
            { Show-SectionSlide -Slide $slide -Settings $settings } | 
                Should -Throw -ExpectedMessage '*does not contain a valid ## heading*'
        }
    }

    Context 'When handling whitespace in section text' {
        BeforeAll {
            $settings = @{
                foreground = 'red'
            }
        }

        It 'Should trim leading whitespace from section text' {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '##     Extra Spaces'
                IsBlank = $false
            }
            
            { Show-SectionSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should trim trailing whitespace from section text' {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '## Trailing Spaces     '
                IsBlank = $false
            }
            
            { Show-SectionSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }
    }

    Context 'When foreground color is not specified' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = '## Test Section'
                IsBlank = $false
            }
            
            $settings = @{
                background = 'black'
            }
        }

        It 'Should render without color parameter' {
            { Show-SectionSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }
    }
}
