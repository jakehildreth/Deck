BeforeAll {
    # Import the private function directly for testing
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Show-ContentSlide.ps1')
    
    # Import dependency for type availability
    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    
    # Mock PwshSpectreConsole commands
    Mock Write-SpectreFigletText { }
    Mock Write-Host { }
    Mock Clear-Host { }
}

Describe 'Show-ContentSlide' {
    Context 'When rendering a content slide with header' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 3
                Content = @'
### Key Points

This is some content text.
More content here.
'@
                IsBlank = $false
            }
            
            $settings = @{
                background = 'black'
                foreground = 'white'
                border     = 'green'
            }
        }

        It 'Should extract header text from ### heading' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Key Points'
            }
        }

        It 'Should clear the screen before rendering' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Clear-Host -Times 1
        }

        It 'Should render content below header' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-Host -Times 1 -ParameterFilter {
                $Object -match 'This is some content text'
            }
        }
    }

    Context 'When rendering content without header' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 3
                Content = @'
Just some content text without a heading.
More content here.
'@
                IsBlank = $false
            }
            
            $settings = @{
                foreground = 'white'
            }
        }

        It 'Should not render figlet header' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 0
        }

        It 'Should render all content' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-Host -Times 1 -ParameterFilter {
                $Object -match 'Just some content text'
            }
        }
    }

    Context 'When handling whitespace in header' {
        BeforeAll {
            $settings = @{
                foreground = 'yellow'
            }
        }

        It 'Should trim leading whitespace from header text' {
            $slide = [PSCustomObject]@{
                Number  = 3
                Content = '###     Extra Spaces'
                IsBlank = $false
            }
            
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Extra Spaces'
            }
        }

        It 'Should trim trailing whitespace from header text' {
            $slide = [PSCustomObject]@{
                Number  = 3
                Content = '### Trailing Spaces     '
                IsBlank = $false
            }
            
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Trailing Spaces'
            }
        }
    }
}
