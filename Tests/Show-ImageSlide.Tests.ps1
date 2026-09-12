BeforeAll {
    $modulePath = Split-Path -Parent $PSScriptRoot
    Import-Module PwshSpectreConsole -ErrorAction Stop

    . (Join-Path $modulePath 'Private/Get-TerminalDimensions.ps1')
    . (Join-Path $modulePath 'Private/Get-BorderStyleFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-SpectreColorFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-PaginationText.ps1')
    . (Join-Path $modulePath 'Private/New-FigletText.ps1')
    . (Join-Path $modulePath 'Private/ConvertTo-SpectreMarkup.ps1')
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
}
