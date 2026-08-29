BeforeAll {
    # Load Spectre.Console assembly (ConvertTo-SpectreMarkup uses [Spectre.Console.Markup]::Escape)
    Import-Module TextMate -ErrorAction Stop

    # Dot-source the function under test and its dependency
    . "$PSScriptRoot/../Private/ConvertTo-SpectreMarkup.ps1"
    . "$PSScriptRoot/../Private/ConvertTo-TableCell.ps1"
}

Describe 'ConvertTo-TableCell' {
    Context 'Markdown links' {
        It 'Converts [text](url) to a clickable link' {
            $result = ConvertTo-TableCell -Text '[@jeffhicks](https://techhub.social/@JeffHicks)'
            $result | Should -Be '[link=https://techhub.social/@JeffHicks]@jeffhicks[/]'
        }

        It 'Converts multiple links in one cell' {
            $result = ConvertTo-TableCell -Text '[a](https://a.example) and [b](https://b.example)'
            $result | Should -Be '[link=https://a.example]a[/] and [link=https://b.example]b[/]'
        }

        It 'Preserves surrounding text around a link' {
            $result = ConvertTo-TableCell -Text 'see [docs](https://example.com/docs) now'
            $result | Should -Be 'see [link=https://example.com/docs]docs[/] now'
        }
    }

    Context 'Inline formatting (issue #25)' {
        It 'Converts simple HTML color tags' {
            $result = ConvertTo-TableCell -Text '<green>@jeffhicks</green>'
            $result | Should -Be '[green]@jeffhicks[/]'
        }

        It 'Converts span color tags' {
            $result = ConvertTo-TableCell -Text '<span style="color:red">alert</span>'
            $result | Should -Be '[red]alert[/]'
        }

        It 'Converts bold' {
            $result = ConvertTo-TableCell -Text '**total**'
            $result | Should -Be '[bold]total[/]'
        }

        It 'Converts italic' {
            $result = ConvertTo-TableCell -Text '*note*'
            $result | Should -Be '[italic]note[/]'
        }

        It 'Converts inline code' {
            $result = ConvertTo-TableCell -Text '`Get-Process`'
            $result | Should -Be '[grey on grey15]Get-Process[/]'
        }

        It 'Converts strikethrough' {
            $result = ConvertTo-TableCell -Text '~~removed~~'
            $result | Should -Be '[strikethrough]removed[/]'
        }
    }

    Context 'Leading marker bullets' {
        It 'Converts a leading dash followed by space to a bullet' {
            $result = ConvertTo-TableCell -Text '- 5%'
            $result | Should -Be '• 5%'
        }

        It 'Converts a leading asterisk followed by space to a bullet' {
            $result = ConvertTo-TableCell -Text '* 3 items'
            $result | Should -Be '• 3 items'
        }

        It 'Converts a leading dash with leading whitespace' {
            $result = ConvertTo-TableCell -Text '  - indented'
            $result | Should -Be '  • indented'
        }

        It 'Still converts formatting after a bullet marker' {
            $result = ConvertTo-TableCell -Text '- **down** 5%'
            $result | Should -Be '• [bold]down[/] 5%'
        }

        It 'Leaves a dash without trailing space as literal data' {
            $result = ConvertTo-TableCell -Text '-5%'
            $result | Should -Be '-5%'
        }
    }

    Context 'Passthrough behavior' {
        It 'Returns plain text unchanged' {
            $result = ConvertTo-TableCell -Text 'jdhitsolutions'
            $result | Should -Be 'jdhitsolutions'
        }

        It 'Returns empty string unchanged' {
            $result = ConvertTo-TableCell -Text ''
            $result | Should -Be ''
        }

        It 'Returns a single space unchanged' {
            $result = ConvertTo-TableCell -Text ' '
            $result | Should -Be ' '
        }

        It 'Preserves pre-escaped ANSI content without corruption' {
            $text = [char]27 + '[38;2;95;135;255m@user' + [char]27 + '[0m'
            $result = ConvertTo-TableCell -Text $text
            $result | Should -Be $text
        }
    }
}
