# PROTOTYPE - throwaway. Do not ship. Ticket: https://github.com/jakehildreth/Deck/issues/43
#
# Question: what syntax marks an inline image, and what does it look like rendered?
# Three variants of "image inline in flowing content", rendered with Deck's real internals:
#   A - flow block:   <img src="Deck.png" width="50%">          (image breaks the text column, centered)
#   B - right float:  <img src="Deck.png" align="right">        (image right third, text wraps beside it)
#   C - figure:       :::figure Deck.png "caption" :::          (small image + dim caption, grouped)
#
# Run:  pwsh ./PROTOTYPE-InlineImages.ps1

$PrivateDir = Join-Path $PSScriptRoot 'Private'
. (Join-Path $PrivateDir 'Import-DeckDependency.ps1')
Import-DeckDependency
Import-Module TextMate
. (Join-Path $PrivateDir 'ConvertTo-SpectreMarkup.ps1')
. (Join-Path $PrivateDir 'Get-TerminalDimensions.ps1')
. (Join-Path $PrivateDir 'Get-BorderStyleFromSettings.ps1')

$ImagePath = Join-Path $PSScriptRoot 'Deck.png'

$Copy = @{
    Before = "Deck turns markdown into terminal presentations.`n`n* Images today force a 60/40 split`n* Inline images should just flow"
    After  = "The quick brown fox paragraph resumes after the image, proving that flow continues cleanly and bullets below still work.`n`n- static bullet under the image"
}

function Show-Variant {
    param(
        [string]$Name,
        [string]$Syntax,
        [object[]]$Body
    )
    $dimensions = Get-TerminalDimensions
    $renderables = [System.Collections.Generic.List[object]]::new()
    $renderables.Add([Spectre.Console.Markup]::new("[bold yellow]$Name[/]"))
    $renderables.Add([Spectre.Console.Markup]::new("[dim]author writes:[/] [grey on grey15] $Syntax [/]"))
    $renderables.Add([Spectre.Console.Text]::new(""))
    foreach ($item in $Body) { $renderables.Add($item) }
    $renderables.Add([Spectre.Console.Text]::new(""))
    $renderables.Add([Spectre.Console.Markup]::new("[dim][[press any key - next variant]][/]"))

    $rows = [Spectre.Console.Rows]::new([object[]]$renderables.ToArray())
    $panel = [Spectre.Console.Panel]::new($rows)
    $panel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
    $panel.Border = [Spectre.Console.BoxBorder]::Rounded
    $panel.BorderStyle = [Spectre.Console.Style]::new([Spectre.Console.Color]::Cyan1)
    $panel.Expand = $true

    if (-not [Console]::IsOutputRedirected) { [Console]::Clear() }
    [Spectre.Console.AnsiConsole]::Write($panel)

    if (-not [Console]::IsInputRedirected) {
        $null = [Console]::ReadKey($true)
    } else {
        Start-Sleep -Milliseconds 500
    }
}

$windowWidth = (Get-TerminalDimensions).Width
$beforeMarkup = [Spectre.Console.Markup]::new((($Copy.Before -split "`n" | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }) -join "`n"))
$afterMarkup  = [Spectre.Console.Markup]::new((($Copy.After  -split "`n" | ForEach-Object { ConvertTo-SpectreMarkup -Text $_ }) -join "`n"))

# Variant A - flow block: image breaks the column, LEFT aligned at ~40% width
$imageA = Get-SpectreImage -ImagePath $ImagePath -MaxWidth ([math]::Floor($windowWidth * 0.4))
Show-Variant -Name 'VARIANT A - flow block (left)' -Syntax '<img src="Deck.png" width="40%">' -Body @(
    $beforeMarkup
    $imageA
    $afterMarkup
)

# Variant B - right float: Grid with explicit widths, text left / image right, then full-width below
$imageB = Get-SpectreImage -ImagePath $ImagePath -MaxWidth ([math]::Floor($windowWidth * 0.3))
$textColWidth = [math]::Floor($windowWidth * 0.6) - 8
$imgColWidth = $windowWidth - $textColWidth - 8
$floatGrid = [Spectre.Console.Grid]::new()
$leftCol = [Spectre.Console.GridColumn]::new(); $leftCol.Width = $textColWidth
$rightCol = [Spectre.Console.GridColumn]::new(); $rightCol.Width = $imgColWidth
$floatGrid.AddColumn($leftCol) | Out-Null
$floatGrid.AddColumn($rightCol) | Out-Null
$floatGrid.AddRow($beforeMarkup, $imageB) | Out-Null
Show-Variant -Name 'VARIANT B - right float' -Syntax '<img src="Deck.png" align="right" width="30%">' -Body @(
    $floatGrid
    $afterMarkup
)

# Variant C - figure: small constrained image, CENTERED, dim caption beneath
$imageC = Get-SpectreImage -ImagePath $ImagePath -MaxWidth ([math]::Floor($windowWidth * 0.3))
$caption = [Spectre.Console.Markup]::new('[dim italic]fig. 1 - The Deck logo[/]')
Show-Variant -Name 'VARIANT C - figure' -Syntax ':::figure Deck.png "fig. 1 - The Deck logo" :::' -Body @(
    $beforeMarkup
    (Format-SpectreAligned -Data ([Spectre.Console.Rows]::new($imageC, $caption)) -HorizontalAlignment Center)
    $afterMarkup
)

if (-not [Console]::IsOutputRedirected) { [Console]::Clear() }
Write-Output 'Prototype done. Which variant felt right - and is the syntax one you would type? (ticket #43)'
