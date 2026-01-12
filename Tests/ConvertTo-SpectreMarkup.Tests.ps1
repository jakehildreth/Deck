BeforeAll {
    # Dot-source the private function for testing
    . "$PSScriptRoot/../Private/ConvertTo-SpectreMarkup.ps1"
}

Describe 'ConvertTo-SpectreMarkup' {
    Context 'Bold formatting' {
        It 'Converts **bold** syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is **bold** text'
            $result | Should -Be 'This is [bold]bold[/] text'
        }

        It 'Converts __bold__ syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is __bold__ text'
            $result | Should -Be 'This is [bold]bold[/] text'
        }

        It 'Handles multiple bold sections' {
            $result = ConvertTo-SpectreMarkup -Text '**First** and **second** bold'
            $result | Should -Be '[bold]First[/] and [bold]second[/] bold'
        }
    }

    Context 'Italic formatting' {
        It 'Converts *italic* syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is *italic* text'
            $result | Should -Be 'This is [italic]italic[/] text'
        }

        It 'Converts _italic_ syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is _italic_ text'
            $result | Should -Be 'This is [italic]italic[/] text'
        }

        It 'Handles multiple italic sections' {
            $result = ConvertTo-SpectreMarkup -Text '*First* and *second* italic'
            $result | Should -Be '[italic]First[/] and [italic]second[/] italic'
        }
    }

    Context 'Inline code formatting' {
        It 'Converts `code` syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is `inline code` text'
            $result | Should -Be 'This is [grey on grey15]inline code[/] text'
        }

        It 'Handles multiple code sections' {
            $result = ConvertTo-SpectreMarkup -Text 'Use `Get-Process` or `Get-Service` cmdlets'
            $result | Should -Be 'Use [grey on grey15]Get-Process[/] or [grey on grey15]Get-Service[/] cmdlets'
        }

        It 'Escapes angle brackets in code' {
            $text = 'Use `<red>text</red>` for colors'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be 'Use [grey on grey15]&lt;red&gt;text&lt;/red&gt;[/] for colors'
        }

        It 'Escapes square brackets in code' {
            $text = 'Use `[bold]text[/]` for bold'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be 'Use [grey on grey15]&#91;bold&#93;text&#91;/&#93;[/] for bold'
        }
    }

    Context 'Strikethrough formatting' {
        It 'Converts ~~strikethrough~~ syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is ~~strikethrough~~ text'
            $result | Should -Be 'This is [strikethrough]strikethrough[/] text'
        }

        It 'Handles multiple strikethrough sections' {
            $result = ConvertTo-SpectreMarkup -Text '~~First~~ and ~~second~~ strikethrough'
            $result | Should -Be '[strikethrough]First[/] and [strikethrough]second[/] strikethrough'
        }
    }

    Context 'Mixed formatting' {
        It 'Handles bold and italic together' {
            $result = ConvertTo-SpectreMarkup -Text 'Text with **bold** and *italic* formatting'
            $result | Should -Be 'Text with [bold]bold[/] and [italic]italic[/] formatting'
        }

        It 'Handles bold and code together' {
            $result = ConvertTo-SpectreMarkup -Text 'Use **PowerShell** with `Get-Process` cmdlet'
            $result | Should -Be 'Use [bold]PowerShell[/] with [grey on grey15]Get-Process[/] cmdlet'
        }

        It 'Handles all formatting types' {
            $result = ConvertTo-SpectreMarkup -Text '**bold** *italic* `code` ~~strike~~'
            $result | Should -Be '[bold]bold[/] [italic]italic[/] [grey on grey15]code[/] [strikethrough]strike[/]'
        }
    }

    Context 'Edge cases' {
        It 'Returns unchanged text with no markdown' {
            $result = ConvertTo-SpectreMarkup -Text 'Plain text with no formatting'
            $result | Should -Be 'Plain text with no formatting'
        }

        It 'Handles empty string' {
            $result = ConvertTo-SpectreMarkup -Text ''
            $result | Should -Be ''
        }

        It 'Handles text with existing Spectre markup' {
            $result = ConvertTo-SpectreMarkup -Text '[red]Already marked up[/]'
            $result | Should -Be '[red]Already marked up[/]'
        }
    }

    Context 'Pipeline support' {
        It 'Accepts input from pipeline' {
            $result = 'This is **bold**' | ConvertTo-SpectreMarkup
            $result | Should -Be 'This is [bold]bold[/]'
        }

        It 'Processes multiple pipeline items' {
            $results = 'First **bold**', 'Second *italic*' | ConvertTo-SpectreMarkup
            $results[0] | Should -Be 'First [bold]bold[/]'
            $results[1] | Should -Be 'Second [italic]italic[/]'
        }
    }

    Context 'Color formatting' {
        It 'Converts simple color tag syntax' {
            $result = ConvertTo-SpectreMarkup -Text 'This is <red>red text</red>'
            $result | Should -Be 'This is [red]red text[/]'
        }

        It 'Converts span style color syntax' {
            $text = 'This is <span style="color:blue">blue text</span>'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be 'This is [blue]blue text[/]'
        }

        It 'Handles multiple color sections' {
            $text = 'Text with <red>red</red> and <blue>blue</blue>'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be 'Text with [red]red[/] and [blue]blue[/]'
        }

        It 'Handles color with bold' {
            $text = '**<red>bold red text</red>**'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be '[bold][red]bold red text[/][/]'
        }

        It 'Handles color with italic' {
            $text = '*<blue>italic blue text</blue>*'
            $result = ConvertTo-SpectreMarkup -Text $text
            $result | Should -Be '[italic][blue]italic blue text[/][/]'
        }
    }
}

