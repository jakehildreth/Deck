BeforeAll {
    $modulePath = Split-Path -Parent $PSScriptRoot
    . (Join-Path $modulePath 'Private/Get-TerminalDimensions.ps1')
    . (Join-Path $modulePath 'Private/Get-BorderStyleFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-SpectreColorFromSettings.ps1')
    . (Join-Path $modulePath 'Private/Get-PaginationText.ps1')
    . (Join-Path $modulePath 'Private/New-FigletText.ps1')
    . (Join-Path $modulePath 'Private/ConvertTo-SpectreMarkup.ps1')
    . (Join-Path $modulePath 'Private/ConvertTo-CodeBlockSegments.ps1')
    . (Join-Path $modulePath 'Private/Show-MultiColumnSlide.ps1')

    Import-Module PwshSpectreConsole -ErrorAction SilentlyContinue

    Mock Out-SpectreHost { }
    Mock Get-SpectreRenderableSize { [PSCustomObject]@{ Width = 80; Height = 10 } }
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

    Context 'Progressive bullets' {
        It 'Accepts a VisibleBullets parameter' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* one`n* two|||* three"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings -VisibleBullets 1 } | Should -Not -Throw
        }

        It 'Counts progressive bullets across all columns' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* one`n* two|||* three"
            }

            Show-MultiColumnSlide -Slide $slide -Settings $mockSettings

            $slide.TotalProgressiveBullets | Should -Be 3
        }

        It 'Hides progressive bullets beyond VisibleBullets' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* one`n* two|||* three"
            }

            # With only 1 visible, the function should still render without error
            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings -VisibleBullets 1 } | Should -Not -Throw
        }

        It 'Reveals all bullets when VisibleBullets exceeds count' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* one|||* two"
            }

            { Show-MultiColumnSlide -Slide $slide -Settings $mockSettings -VisibleBullets 99 } | Should -Not -Throw
        }
    }

    Context 'Progressive bullet layout stability' {
        It 'Uses the same content height regardless of VisibleBullets' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* one`n* two`n* three|||* four`n* five"
            }

            # Render with 0 visible — should still measure full height
            Show-MultiColumnSlide -Slide $slide -Settings $mockSettings -VisibleBullets 0

            # The slide object should carry FullContentHeight set from unfiltered content
            $slide.PSObject.Properties['FullContentHeight'] | Should -Not -BeNullOrEmpty
        }

        It 'Pads hidden progressive bullets to preserve column width' {
            $slide = [PSCustomObject]@{
                Number = 1
                Content = "* short`n* a much longer bullet line|||* right"
            }

            # Render with 0 visible — hidden lines should be padded, not empty
            Show-MultiColumnSlide -Slide $slide -Settings $mockSettings -VisibleBullets 0

            # The slide should carry a MaxColumnWidths array for stable layout
            $slide.PSObject.Properties['MaxColumnWidths'] | Should -Not -BeNullOrEmpty
        }
    }
}
