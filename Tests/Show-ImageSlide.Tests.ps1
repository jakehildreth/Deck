BeforeAll {
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module PwshSpectreConsole -ErrorAction Stop

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
    . (Join-Path $modulePath 'Private/Show-ImageSlide.ps1')

    $script:render = {
        param($Renderable)

        $writer = [System.IO.StringWriter]::new()
        $settings = [Spectre.Console.AnsiConsoleSettings]::new()
        $settings.Ansi = [Spectre.Console.AnsiSupport]::No
        $settings.Out = [Spectre.Console.AnsiConsoleOutput]::new($writer)
        $console = [Spectre.Console.AnsiConsole]::Create($settings)
        $console.Write($Renderable)
        $writer.ToString()
    }

    Mock Get-TerminalDimensions { @{ Width = 120; Height = 40 } }
    Mock Get-SpectreRenderableSize { [PSCustomObject]@{ Width = 20; Height = 10 } }
    Mock Get-SpectreImage { [Spectre.Console.Text]::new('image') }
    Mock Out-SpectreHost { param($Data) $script:rendered = $Data }
}

Describe 'Show-ImageSlide' {
    BeforeEach {
        $script:rendered = $null
    }

    Context 'When an image uses the removed width suffix' {
        It 'Renders the slide text and the suffix as literal text' {
            $slide = [PSCustomObject]@{
                Number     = 1
                SourceFile = Join-Path $TestDrive 'deck.md'
                Content    = "Body copy`n`n![Alt](image.png){width=80}"
            }
            $settings = @{
                foreground  = 'white'
                border      = 'white'
                borderStyle = 'rounded'
                h3          = 'default'
                pagination  = $false
            }

            Show-ImageSlide -Slide $slide -Settings $settings
            $output = & $script:render $script:rendered

            $output | Should -Match 'Body copy'
            $output | Should -Match '\{width=80\}'
        }
    }

    Context 'When fadeBullets is enabled' {
        # Fade markup correctness is covered in Format-ProgressiveBulletLine.Tests.ps1.
        # Smoke test: rendering faded colored bullets must not throw. h3 = 'default' keeps
        # the figlet path from hitting a null-path Test-Path error.
        It 'Should render faded colored bullets without errors' {
            $slide = [PSCustomObject]@{
                Number  = 1
                Content = @'
### Left

* <span style="color:red">red point</span>
* <span style="color:blue">blue point</span>

![img](pic.png)
'@
                IsBlank = $false
            }
            $settings = @{ foreground = 'white'; h3 = 'default'; fadeBullets = $true; fadeColor = 'grey19' }

            { Show-ImageSlide -Slide $slide -Settings $settings -VisibleBullets 2 } | Should -Not -Throw
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

![img](pic.png)
'@
                IsBlank = $false
            }
            $settings = @{ foreground = 'white'; h3 = 'default'; fadeBullets = $true; fadeColor = 'grey19' }

            Mock Format-ProgressiveBulletLine { $Line }
            Show-ImageSlide -Slide $slide -Settings $settings -VisibleBullets 2

            Should -Invoke Format-ProgressiveBulletLine -Times 1 -Exactly -ParameterFilter { $Line -like '* first' -and $Fade }
            Should -Invoke Format-ProgressiveBulletLine -Times 1 -Exactly -ParameterFilter { $Line -like '* second' -and -not $Fade }
        }
    }
}

