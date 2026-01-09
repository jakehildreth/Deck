BeforeAll {
    # Import the private function directly for testing
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Show-TitleSlide.ps1')
    
    # Import dependency for type availability
    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    
    # Mock PwshSpectreConsole commands
    Mock Write-SpectreFigletText { }
    Mock Clear-Host { }
}

Describe 'Show-TitleSlide' {
    Context 'When rendering a valid title slide' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '# Welcome to My Presentation'
                IsBlank = $false
            }
            
            $settings = @{
                background = 'black'
                foreground = 'white'
                border     = 'red'
            }
        }

        It 'Should extract title text from # heading' {
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Welcome to My Presentation'
            }
        }

        It 'Should clear the screen before rendering' {
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Clear-Host -Times 1
        }

        It 'Should use foreground color from settings' {
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Color -ne $null -and $Color.ToString() -eq 'White'
            }
        }
    }

    Context 'When rendering with different color names' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '# Test Title'
                IsBlank = $false
            }
        }

        It 'Should handle lowercase color names' {
            $settings = @{ foreground = 'green' }
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Color -ne $null -and $Color.ToString() -eq 'Green'
            }
        }

        It 'Should handle uppercase color names' {
            $settings = @{ foreground = 'YELLOW' }
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Color -ne $null -and $Color.ToString() -eq 'Yellow'
            }
        }

        It 'Should handle mixed case color names' {
            $settings = @{ foreground = 'ReD' }
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Color -ne $null -and $Color.ToString() -eq 'Red'
            }
        }
    }

    Context 'When foreground color is not specified' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '# Test Title'
                IsBlank = $false
            }
            
            $settings = @{
                background = 'black'
            }
        }

        It 'Should render without color parameter' {
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $PSBoundParameters.ContainsKey('Color') -eq $false
            }
        }
    }

    Context 'When slide content is invalid' {
        BeforeAll {
            $settings = @{
                foreground = 'cyan'
            }
        }

        It 'Should throw error when no # heading found' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = 'Just some text without heading'
                IsBlank = $false
            }
            
            { Show-TitleSlide -Slide $slide -Settings $settings } | 
                Should -Throw -ExpectedMessage '*does not contain a valid # heading*'
        }

        It 'Should throw error when slide has ## heading instead of #' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '## Section Heading'
                IsBlank = $false
            }
            
            { Show-TitleSlide -Slide $slide -Settings $settings } | 
                Should -Throw -ExpectedMessage '*does not contain a valid # heading*'
        }
    }

    Context 'When handling whitespace in title' {
        BeforeAll {
            $settings = @{
                foreground = 'white'
            }
        }

        It 'Should trim leading whitespace from title text' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '#     Extra Spaces'
                IsBlank = $false
            }
            
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Extra Spaces'
            }
        }

        It 'Should trim trailing whitespace from title text' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '# Trailing Spaces     '
                IsBlank = $false
            }
            
            Show-TitleSlide -Slide $slide -Settings $settings
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $Text -eq 'Trailing Spaces'
            }
        }
    }

    Context 'When using invalid color names' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = '# Test Title'
                IsBlank = $false
            }
            
            $settings = @{
                foreground = 'notarealcolor'
            }
        }

        It 'Should render without color when invalid color specified' {
            # When invalid color, should fallback to no color
            Show-TitleSlide -Slide $slide -Settings $settings -WarningAction SilentlyContinue
            
            Should -Invoke Write-SpectreFigletText -Times 1 -ParameterFilter {
                $PSBoundParameters.ContainsKey('Color') -eq $false
            }
        }
    }
}
