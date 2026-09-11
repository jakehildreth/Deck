# PROTOTYPE - throwaway. Do not ship. Ticket: https://github.com/jakehildreth/Deck/issues/45
#
# Question being shown: why does Strict height math differ for the two inline-image layouts?
#   - FLOAT (align right):  image and text share one row -> height = MAX(image, text)
#   - CENTER (block):       image on its own line        -> height = text + image (ADDITIVE)
# Same content, rendered both ways, with the height calculation printed under each.
#
# Run:  pwsh ./PROTOTYPE-StrictImageHeight.ps1

$PrivateDir = Join-Path $PSScriptRoot 'Private'
. (Join-Path $PrivateDir 'Import-DeckDependency.ps1')
Import-DeckDependency
Import-Module TextMate
. (Join-Path $PrivateDir 'Get-TerminalDimensions.ps1')

$ImagePath = Join-Path $PSScriptRoot 'Deck.png'

$dimensions = Get-TerminalDimensions
$windowWidth = $dimensions.Width
$windowHeight = $dimensions.Height - 1
$contentWidth = $windowWidth - 8   # panel padding, as in the renderers

$windowHeight = $dimensions.Height - 1
if ($windowHeight -lt 10) { $windowHeight = 24 }   # redirected output reports height 1; assume a normal terminal

$Text = "Deck turns markdown into terminal presentations.`n`n- images inline in the flow`n- bullets keep working`n- text wraps beside a float`n- or sits above a centered figure`n- Strict must fit it all on screen"

function Measure-Height {
    param([object]$Renderable, [int]$Width)
    (Get-SpectreRenderableSize -Renderable $Renderable -ContainerWidth $Width).Height
}

function Show-Case {
    param([string]$Name, [object]$Body, [string]$MathLine, [int]$UsedHeight)
    $renderables = [System.Collections.Generic.List[object]]::new()
    $renderables.Add([Spectre.Console.Markup]::new("[bold yellow]$Name[/]"))
    $renderables.Add([Spectre.Console.Text]::new(""))
    $renderables.Add($Body)
    $renderables.Add([Spectre.Console.Text]::new(""))
    $renderables.Add([Spectre.Console.Markup]::new("[dim]Strict height math:[/] $MathLine"))
    $color = if ($UsedHeight -le ($windowHeight - 4)) { 'green' } else { 'red' }
    $renderables.Add([Spectre.Console.Markup]::new("[dim]total used:[/] [$color]$UsedHeight rows[/] [dim]of a $($windowHeight)-row viewport[/]"))
    $renderables.Add([Spectre.Console.Text]::new(""))
    $renderables.Add([Spectre.Console.Markup]::new("[dim][[press any key - next]][/]"))

    $panel = [Spectre.Console.Panel]::new([Spectre.Console.Rows]::new([object[]]$renderables.ToArray()))
    $panel.Padding = [Spectre.Console.Padding]::new(2, 1, 2, 1)
    $panel.Border = [Spectre.Console.BoxBorder]::Rounded
    $panel.BorderStyle = [Spectre.Console.Style]::new([Spectre.Console.Color]::Cyan1)
    $panel.Expand = $true

    if (-not [Console]::IsOutputRedirected) { [Console]::Clear() }
    [Spectre.Console.AnsiConsole]::Write($panel)
    if (-not [Console]::IsInputRedirected) { $null = [Console]::ReadKey($true) } else { Start-Sleep -Milliseconds 500 }
}

$textMarkup = [Spectre.Console.Markup]::new($Text)

# ---- CASE 1: right float -------------------------------------------------
# Image right, text wraps in a narrower left column. One shared row.
$floatImageMaxW = [math]::Floor($contentWidth * 0.3)
$floatImage = Get-SpectreImage -ImagePath $ImagePath -MaxWidth $floatImageMaxW
$imgColWidth = [math]::Floor($contentWidth * 0.3)
$textColWidth = $contentWidth - $imgColWidth

$grid = [Spectre.Console.Grid]::new()
$lc = [Spectre.Console.GridColumn]::new(); $lc.Width = $textColWidth
$rc = [Spectre.Console.GridColumn]::new(); $rc.Width = $imgColWidth
$grid.AddColumn($lc) | Out-Null
$grid.AddColumn($rc) | Out-Null
$grid.AddRow($textMarkup, $floatImage) | Out-Null

$textH = Measure-Height -Renderable $textMarkup -Width $textColWidth
$imgH = Measure-Height -Renderable $floatImage -Width $imgColWidth
$floatUsed = [math]::Max($textH, $imgH)
Show-Case -Name 'FLOAT (align right): image and text share a row' -Body $grid `
    -MathLine "text $textH rows, image $imgH rows, shared row -> MAX = $floatUsed (not added)" -UsedHeight $floatUsed

# ---- CASE 2: centered block ----------------------------------------------
# Text full width, then the image on its own line below. Heights add.
$blockImageMaxW = [math]::Floor($contentWidth * 0.4)
$blockImage = Get-SpectreImage -ImagePath $ImagePath -MaxWidth $blockImageMaxW
$block = [Spectre.Console.Rows]::new($textMarkup, [Spectre.Console.Text]::new(""), (Format-SpectreAligned -Data $blockImage -HorizontalAlignment Center))

$textH2 = Measure-Height -Renderable $textMarkup -Width $contentWidth
$imgH2 = Measure-Height -Renderable $blockImage -Width $contentWidth
$blockUsed = $textH2 + 1 + $imgH2
Show-Case -Name 'CENTER (block): image on its own line' -Body $block `
    -MathLine "text $textH2 rows + image $imgH2 rows, stacked -> ADD = $blockUsed" -UsedHeight $blockUsed

if (-not [Console]::IsOutputRedirected) { [Console]::Clear() }
Write-Output 'Done. Same words, same picture: float reuses a row (MAX), center adds a row (ADD). That is why Strict must know the layout. (ticket #45)'
