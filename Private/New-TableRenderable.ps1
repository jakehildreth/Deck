function New-TableRenderable {
    <#
    .SYNOPSIS
        Creates a Spectre.Console Table renderable from a markdown table string.

    .DESCRIPTION
        Parses a markdown table (header row, separator row, and data rows) into
        PSCustomObjects and pipes them to Format-SpectreTable. Column alignment is
        derived from the separator row using standard markdown alignment syntax:
        - :--- or --- = left-aligned (default)
        - :---: = center-aligned
        - ---: = right-aligned

        Uses Rounded border style to match the aesthetic of New-CodeBlockPanel.

    .PARAMETER RawTable
        The raw markdown table string including header, separator, and data rows.
        Expected format:
            | Col1 | Col2 | Col3 |
            |------|:----:|-----:|
            | a    | b    | c    |

    .PARAMETER Centered
        When specified, wraps the table in Format-SpectreAligned with Center
        horizontal alignment.

    .EXAMPLE
        $md = @'
        | Name | Value |
        |------|-------|
        | Foo  | 42    |
        '@
        New-TableRenderable -RawTable $md

        Returns a Spectre.Console.Table with two left-aligned columns.

    .EXAMPLE
        $md = @'
        | Left | Center | Right |
        |:-----|:------:|------:|
        | a    | b      | c     |
        '@
        New-TableRenderable -RawTable $md -Centered

        Returns a centered table with mixed column alignments.

    .EXAMPLE
        $md = @'
        | Item |
        |------|
        | only |
        '@
        New-TableRenderable -RawTable $md

        Returns a single-column, single-row table.

    .OUTPUTS
        Spectre.Console.IRenderable. A Table (or aligned Table) renderable for
        composition into slide layouts.

    .NOTES
        Follows the same helper pattern as New-CodeBlockPanel -- a shared private
        function called from ContentSlide, ImageSlide, and MultiColumnSlide renderers.
        Uses Format-SpectreTable from PwshSpectreConsole for table construction.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RawTable,

        [Parameter()]
        [switch]$Centered
    )

    process {
        # Split into non-empty lines
        $lines = $RawTable -split "`r?`n" | Where-Object { $_.Trim() -ne '' }

        if ($lines.Count -lt 2) {
            Write-Warning 'Table requires at least a header and separator row'
            return [Spectre.Console.Text]::new($RawTable)
        }

        # --- parse header row ---
        $headerCells = $lines[0].Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() }

        # --- parse separator row for alignment ---
        $separatorCells = $lines[1].Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() }

        # Build -Property array with alignment from separator row
        $properties = for ($i = 0; $i -lt $headerCells.Count; $i++) {
            $columnName = if ($headerCells[$i]) { $headerCells[$i] } else { ' ' }
            $alignment = 'Left'
            if ($i -lt $separatorCells.Count) {
                $cell = $separatorCells[$i]
                $leftColon = $cell.StartsWith(':')
                $rightColon = $cell.EndsWith(':')
                if ($leftColon -and $rightColon) {
                    $alignment = 'Center'
                } elseif ($rightColon) {
                    $alignment = 'Right'
                }
            }
            @{
                Name      = $columnName
                Expression = $columnName
                Alignment = $alignment
            }
        }

        # --- build PSCustomObjects from data rows ---
        $dataLines = $lines | Select-Object -Skip 2
        $dataObjects = foreach ($dataLine in $dataLines) {
            $cells = $dataLine.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() }
            $row = [ordered]@{}
            for ($i = 0; $i -lt $headerCells.Count; $i++) {
                $columnName = if ($headerCells[$i]) { $headerCells[$i] } else { ' ' }
                $cellValue = if ($i -lt $cells.Count -and $cells[$i]) { $cells[$i] } else { ' ' }
                $row[$columnName] = $cellValue
            }
            [PSCustomObject]$row
        }

        # --- pipe to Format-SpectreTable ---
        $tableParams = @{
            Data   = $dataObjects
            Border = 'Rounded'
            Property = $properties
        }
        $tableRenderable = Format-SpectreTable @tableParams

        if ($Centered) {
            return Format-SpectreAligned -Data $tableRenderable -HorizontalAlignment Center
        }

        $tableRenderable
    }
}
