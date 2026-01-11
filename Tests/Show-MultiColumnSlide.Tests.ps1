BeforeAll {
    Import-Module "$PSScriptRoot/../Deck.psd1" -Force
}

Describe 'Show-MultiColumnSlide' {
    BeforeAll {
        $mockSettings = @{
            background = 'Black'
            foreground = 'White'
            border = 'Blue'
            borderStyle = 'Rounded'
        }
    }

    Context 'Column detection' {
        It 'Detects ||| delimiter and splits content' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Left content|||Right content"
            }

            # Just verify it doesn't throw
            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles content with header' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = @"
### Two Column Header
Left content
|||
Right content
"@
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles missing delimiter with warning' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Single column content"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings 3>&1 } | Should -Not -Throw
        }
    }

    Context 'Content formatting' {
        It 'Applies markdown formatting to left column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "**Bold left**|||Right"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Applies markdown formatting to right column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Left|||**Bold right**"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Applies markdown formatting to both columns' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "**Bold left**|||*Italic right*"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }
    }

    Context 'Multi-line content' {
        It 'Handles multiple lines in left column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = @"
Line 1 left
Line 2 left
Line 3 left
|||
Right
"@
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles multiple lines in right column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = @"
Left
|||
Line 1 right
Line 2 right
Line 3 right
"@
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles multiple lines in both columns' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = @"
Line 1 left
Line 2 left
|||
Line 1 right
Line 2 right
"@
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }
    }

    Context 'Edge cases' {
        It 'Handles empty left column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "|||Right content"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles empty right column' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Left content|||"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles both columns empty' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "|||"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }
    }

    Context 'Multiple columns' {
        It 'Handles three columns' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Column 1|||Column 2|||Column 3"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles four columns' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "Col 1|||Col 2|||Col 3|||Col 4"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }

        It 'Handles columns with formatting' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "**Bold**|||*Italic*|||~~Strike~~"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings } | Should -Not -Throw
        }
    }
}
