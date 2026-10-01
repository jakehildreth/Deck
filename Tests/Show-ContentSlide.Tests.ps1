BeforeAll {
    # Import the private function directly for testing
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Get-TerminalDimensions.ps1')
    . (Join-Path $modulePath 'Private/Get-BorderStyleFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-SpectreColorFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-PaginationText.ps1')
    . (Join-Path $modulePath 'Private/New-FigletText.ps1')
    . (Join-Path $modulePath 'Private/ConvertTo-SpectreMarkup.ps1')
    . (Join-Path $modulePath 'Private/Resolve-FadeStyle.ps1')
    . (Join-Path $modulePath 'Private/Format-ProgressiveBulletLine.ps1')
    . (Join-Path $modulePath 'Private/New-CodeBlockPanel.ps1')
    . (Join-Path $modulePath 'Private/New-TableRenderable.ps1')
    . (Join-Path $modulePath 'Private/ConvertTo-TableCell.ps1')
    . (Join-Path $modulePath 'Private/Show-ContentSlide.ps1')

    # Import dependency for type availability
    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
    
    # Mock commands
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
    Context 'When rendering H1 heading with body content' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = @'
# Deck Title

Some body text under the H1 heading.
* progressive bullet one
* progressive bullet two
'@
                IsBlank = $false
            }

            $settings = @{
                foreground = 'white'
                h1         = 'small'
                h1Color    = 'Yellow'
            }
        }

        It 'Should render without errors' {
            { Show-ContentSlide -Slide $slide -Settings $settings } | Should -Not -Throw
        }

        It 'Should render using Out-SpectreHost' {
            Show-ContentSlide -Slide $slide -Settings $settings

            Should -Invoke Out-SpectreHost -Times 1
        }

        It 'Should count progressive bullets in the body' {
            Show-ContentSlide -Slide $slide -Settings $settings

            $slide.TotalProgressiveBullets | Should -Be 2
        }
    }

    Context 'When rendering H2 heading with body content' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 2
                Content = @'
## Section With Body

Body text under an H2 heading.
'@
                IsBlank = $false
            }

            $settings = @{
                foreground = 'white'
                h2         = 'mini'
                h2Color    = 'Cyan'
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

    Context 'When rendering H1 heading mixed with a table' {
        BeforeAll {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = @'
# Mixed Content

| Name  | Value |
| ----- | ----- |
| foo   | 1     |
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
    }

    Context 'When fadeBullets is enabled' {
        # Fade markup correctness is covered in Format-ProgressiveBulletLine.Tests.ps1.
        # These are smoke tests: rendering with fade on (plain and colored bullets) must not throw.

        It 'Should render faded colored and plain bullets without errors' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = @'
* <span style="color:red">red point</span>
* <span style="color:blue">blue point</span>
* plain point
'@
                IsBlank = $false
            }
            $settings = @{ foreground = 'white'; fadeBullets = $true; fadeColor = 'grey19' }

            { Show-ContentSlide -Slide $slide -Settings $settings -VisibleBullets 2 } | Should -Not -Throw
            $slide.TotalProgressiveBullets | Should -Be 3
        }

        It 'Should render with dim fade (no fadeColor) without errors' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = "* first`n* second"
                IsBlank = $false
            }
            $settings = @{ foreground = 'white'; fadeBullets = $true }

            { Show-ContentSlide -Slide $slide -Settings $settings -VisibleBullets 2 } | Should -Not -Throw
        }
        It 'Should fade bullets against a slide-global reveal index across segments' {
            # Regression: a per-segment render counter restarted at zero, so with bullets
            # split by a code block and VisibleBullets 2, BOTH bullets were faded and no
            # current bullet stayed full strength.
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = @'
* first

```powershell
Get-Process
```

* second
'@
                IsBlank = $false
            }
            $settings = @{ foreground = 'white'; fadeBullets = $true; fadeColor = 'grey19' }

            Mock Format-ProgressiveBulletLine { $Line }
            Show-ContentSlide -Slide $slide -Settings $settings -VisibleBullets 2

            Should -Invoke Format-ProgressiveBulletLine -Times 1 -Exactly -ParameterFilter { $Line -like '* first' -and $Fade }
            Should -Invoke Format-ProgressiveBulletLine -Times 1 -Exactly -ParameterFilter { $Line -like '* second' -and -not $Fade }
        }
    }
}

