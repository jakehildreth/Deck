function New-FigletText {
    <#
    .SYNOPSIS
        Creates a Spectre.Console.FigletText object with optional font and color.

    .DESCRIPTION
        Constructs a FigletText renderable object for ASCII art text display using
        PwshSpectreConsole. Handles font loading from .flf files, applies color and
        justification, and falls back to Spectre's default font if file not found.
        
        FigletText renders text as large ASCII art characters. The appearance depends
        on the font file used. Deck includes numerous .flf fonts in the Fonts directory
        for different sizes and styles.
        
        Font loading is defensive: if the specified font file doesn't exist or fails
        to load, the function falls back to Spectre.Console's built-in default font
        without throwing an error.

    .PARAMETER Text
        The text to render as figlet ASCII art. Should be relatively short as figlet
        text can become very wide. Most fonts work best with 1-3 words.

    .PARAMETER FontPath
        Path to a .flf (FIGlet Font) file. Can be relative or absolute path.
        If not provided or file doesn't exist, uses Spectre.Console's default font.
        
        The .flf format is the standard FIGlet font format. Many free fonts are
        available online.

    .PARAMETER Color
        Optional Spectre.Console.Color object for the figlet text.
        If not specified, uses terminal's default foreground color.

    .PARAMETER Justification
        Text justification within the available width.
        Valid values: 'Left', 'Center', 'Right'
        Default: 'Center'

    .EXAMPLE
        $figlet = New-FigletText -Text "Hello"
        Write-SpectreHost -Object $figlet

        Creates figlet text with default font, no color, centered justification.

    .EXAMPLE
        $color = [Spectre.Console.Color]::Cyan1
        $fontPath = Join-Path $PSScriptRoot '../Fonts/mini.flf'
        $figlet = New-FigletText -Text "Hello" -FontPath $fontPath -Color $color

        Creates figlet text with 'mini' font and cyan color.

    .EXAMPLE
        $figlet = New-FigletText -Text "Left Aligned" -Justification Left

        Creates figlet text aligned to the left side.

    .EXAMPLE
        $settings = @{ h1 = 'small' }
        $fontPath = Join-Path $PSScriptRoot "../Fonts/$($settings.h1).flf"
        $figlet = New-FigletText -Text "Title" -FontPath $fontPath -Justification Center

        Loads font dynamically based on settings, commonly used in slide renderers.

    .OUTPUTS
        Spectre.Console.FigletText
        
        Returns a FigletText renderable object that can be passed to Write-SpectreHost,
        added to panels, or included in other Spectre.Console layouts.

    .NOTES
        Font Files:
        - Format: FIGlet (.flf) font files
        - Location: Typically in ../Fonts/ relative to Deck module
        - Fallback: Uses Spectre.Console's built-in font if file not found
        - No error thrown on missing font (defensive programming)
        
        Common Fonts in Deck:
        - small: Medium-sized font (default for h2/section slides)
        - mini: Small font (default for h3/content headers)
        - Various others in Fonts/ directory
        
        Text Length Considerations:
        - Figlet text can be very wide (20-100+ characters per letter)
        - Keep text short to fit within terminal width
        - Test with target terminal dimensions
        - Consider terminal width when choosing fonts
        
        Justification Behavior:
        - Left: Figlet text starts at left edge
        - Center: Figlet text centered (most common)
        - Right: Figlet text aligned to right edge
        
        Color Application:
        - Applied to entire figlet text uniformly
        - No per-character coloring supported by this function
        - Color object must be Spectre.Console.Color type
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$FontPath,

        [Parameter(Mandatory = $false)]
        [object]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Left', 'Center', 'Right')]
        [string]$Justification = 'Center'
    )

    # Create figlet with font if available
    if ($FontPath -and (Test-Path $FontPath)) {
        $font = [Spectre.Console.FigletFont]::Load($FontPath)
        $figlet = [Spectre.Console.FigletText]::new($font, $Text)
    } else {
        $figlet = [Spectre.Console.FigletText]::new($Text)
    }

    # Set justification
    $figlet.Justification = [Spectre.Console.Justify]::$Justification

    # Set color if provided
    if ($Color) {
        $figlet.Color = $Color
    }

    return $figlet
}
