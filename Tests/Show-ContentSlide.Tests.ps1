BeforeAll {
    # Import the private function directly for testing
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Show-ContentSlide.ps1')
    
    # Import dependency for type availability
    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    
    # Mock commands
    Mock Clear-Host { }
    Mock Out-SpectreHost { }
    Mock Get-SpectreRenderableSize { [PSCustomObject]@{ Width = 80; Height = 10 } }
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

        It 'Should render without errors' {
            { Show-ContentSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should clear the screen before rendering' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Clear-Host -Times 1
        }

        It 'Should render using Out-SpectreHost' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Out-SpectreHost -Times 1
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

        It 'Should render without errors' {
            { Show-ContentSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should render using Out-SpectreHost' {
            Show-ContentSlide -Slide $slide -Settings $settings
            
            Should -Invoke Out-SpectreHost -Times 1
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
            
            { Show-ContentSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should trim trailing whitespace from header text' {
            $slide = [PSCustomObject]@{
                Number  = 3
                Content = '### Trailing Spaces     '
                IsBlank = $false
            }
            
            { Show-ContentSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }
    }
}
