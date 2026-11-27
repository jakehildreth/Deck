BeforeAll {
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/ConvertTo-SpectreMarkup.ps1')
    . (Join-Path $modulePath 'Private/Format-ProgressiveBulletLine.ps1')

    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue
}

Describe 'Format-ProgressiveBulletLine' {
    Context 'When fade is disabled' {
        It 'Should convert the bullet marker to a glyph and not fade' {
            $result = Format-ProgressiveBulletLine -Line '* first' 
            $result | Should -Be '• first'
        }
    }

    Context 'When fading with the default dim style' {
        It 'Should wrap the converted line in dim and convert the bullet marker' {
            # Regression: fade applied after markup conversion, so '* ' becomes '• '.
            $result = Format-ProgressiveBulletLine -Line '* first' -Fade
            $result | Should -Be '[dim]• first[/]'
        }

        It 'Should compose dim over an inline color without removing it' {
            $result = Format-ProgressiveBulletLine -Line '* <span style="color:red">red point</span>' -Fade
            $result | Should -Be '[dim]• [red]red point[/][/]'
        }

        It 'Should preserve bold and italic under dim' {
            $result = Format-ProgressiveBulletLine -Line '* **bold** and *italic*' -Fade
            $result | Should -Be '[dim]• [bold]bold[/] and [italic]italic[/][/]'
        }
    }

    Context 'When fading with a fixed fadeColor' {
        It 'Should wrap the converted line in the fade color' {
            $result = Format-ProgressiveBulletLine -Line '* first' -Fade -FadeColor 'grey19'
            $result | Should -Be '[grey19]• first[/]'
        }

        It 'Should override an inline foreground color with the fade color' {
            # Regression: fixed fadeColor must take precedence over inline colors,
            # not lose to them (inner [red] would otherwise win).
            $result = Format-ProgressiveBulletLine -Line '* <span style="color:red">red point</span>' -Fade -FadeColor 'grey19'
            $result | Should -Be '[grey19]• [grey19]red point[/][/]'
        }

        It 'Should override each of several inline colors' {
            $result = Format-ProgressiveBulletLine -Line '* <cyan>a</cyan> and <blue>b</blue>' -Fade -FadeColor 'grey35'
            $result | Should -Be '[grey35]• [grey35]a[/] and [grey35]b[/][/]'
        }

        It 'Should preserve bold and links while overriding color' {
            $result = Format-ProgressiveBulletLine -Line '* **bold** [site](https://example.com) <green>g</green>' -Fade -FadeColor 'grey50'
            $result | Should -Be '[grey50]• [bold]bold[/] [link=https://example.com]site[/] [grey50]g[/][/]'
        }

        It 'Should rewrite only the foreground of inline code and keep its background' {
            # Regression: inline code renders as [grey on grey15]; the fixed fade
            # color must replace the foreground but retain the grey15 background.
            $result = Format-ProgressiveBulletLine -Line '* `code`' -Fade -FadeColor 'grey19'
            $result | Should -Be '[grey19]• [grey19 on grey15]code[/][/]'
        }
    }
}
