![The Deck logo displays the word "Deck" in a chunky pixel/bitmap font with a tan and beige color on a black background, evoking a retro video game version of a deck.](Deck.png)
# Deck

Terminal-based presentations from Markdown files using PowerShell.

![PowerShell 7.4+](https://img.shields.io/badge/PowerShell-7.4%2B-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20arm64%20%7C%20Linux-lightgrey)
[![PSGallery](https://img.shields.io/powershellgallery/v/Deck)](https://www.powershellgallery.com/packages/Deck)
![License](https://img.shields.io/badge/license-MIT%20w%2FCommons%20Clause-green)

## Quick Start

```powershell
Install-Module Deck -Scope CurrentUser
```

Or clone from GitHub:

```powershell
git clone https://github.com/jakehildreth/Deck.git
Import-Module ./Deck/Deck.psd1
```

Create a Markdown file:

```markdown
---
background: Black
foreground: Cyan1
border: Blue
---

# My Presentation

---

## Section Title

---

### Slide Content

Your content here with **bold** and *italic* text.

* Progressive bullets
* Reveal one at a time
```

Run the presentation:

```powershell
Show-Deck -Path ./presentation.md
```

Or load directly from a web URL:

```powershell
Show-Deck -Path https://exampledeck.jakehildreth.com
```

Validate content before presenting:

```powershell
Show-Deck -Path ./presentation.md -Strict
```

The `-Strict` parameter validates:
- Content height doesn't exceed viewport
- Local image files exist (web image URLs are **not** validated)
- Reports all errors before starting

Start from a specific slide:

```powershell
Show-Deck -Path ./presentation.md -StartSlide 5
```

## Features

### Slide Types

* Title Slides - Single `#` heading with large figlet text
* Section Slides - Single `##` heading with medium figlet text
* Content Slides - `###` heading with body content
* Image Slides - Two-panel layout with content left (60%), image right (40%)
* Multi-Column Slides - Split content with `|||` delimiter (delimiter must be on its own line)
* Syntax Highlighting - Fenced code blocks with language-aware highlighting via TextMate

Tables, code blocks, and images can appear within any content, image, or multi-column slide.

#### Image Slides

Create side-by-side layouts with text and images:

```markdown
### Slide Title

Text content on the left.

* Progressive bullets supported
* Auto-sized images

![Alt Text](image.png){width=80}
```

Images are auto-detected. Use relative or absolute paths. Optional `{width=N}` sets max width.

Web images are supported:

```markdown
![Logo](https://example.com/logo.png)
### About Our Brand
Content appears here
```

#### Tables

Markdown tables render as rounded Spectre.Console tables:

```markdown
### Slide Title

| Name   | Role       | Status |
|-------|----------|-------|
| Alice  | Engineer   | Active |
| Bob    | Designer   | Active |
```

Tables work on content slides, image slides, and multi-column slides.

#### Syntax Highlighting

Fenced code blocks with a language identifier get automatic syntax highlighting powered by [TextMate](https://github.com/trackd/TextMate):

````markdown
```powershell
Get-Process | Where-Object CPU -gt 100
```
````

Renders in a rounded panel with language header and full color tokenization. Supports 60+ languages including PowerShell, Python, C#, JavaScript, Rust, Go, SQL, YAML, and more. Falls back to plain monochrome when a language grammar isn't available.

### Bullet Points

* Progressive bullets using `*` — revealed one at a time with each forward keypress; navigating backward un-reveals one at a time
* Static bullets using `-` — all visible immediately on slide entry

### Inline Formatting

* `**bold**` or `__bold__`  
* `*italic*` or `_italic_`  
* `` `code` ``  
* `~~strikethrough~~`
* `<colorname>text</colorname>` or `<span style="color:colorname">text</span>` for colors

#### Color Examples

```markdown
This text has <red>red</red>, <blue>blue</blue>, and <green>green</green> colors.

You can use standard HTML: <span style="color:yellow">yellow text</span>

Mix with formatting: **<red>bold red text</red>** or *<blue>italic blue</blue>*
```

Supports all [Spectre.Console color names](https://spectreconsole.net/appendix/colors).

### Navigation

* Forward: Right, Down, Space, Enter, `n`, Page Down
* Backward: Left, Up, Backspace, `p`, Page Up
* Exit: Esc, Ctrl+C, `q`
* Help: `?`

The first slide shows a `[press ? for help]` hint in place of pagination. After the last slide an "End of Deck" screen is shown — press any backward key to return to the last slide, or Esc / `q` / Ctrl+C to exit.

### Customization

Configure in YAML frontmatter:

```yaml
---
background: black          # Background color
foreground: white          # Text color
border: magenta            # Border color
borderStyle: rounded       # rounded, square, double, heavy, none
pagination: false          # Show slide numbers
paginationStyle: minimal   # minimal, fraction, text, progress, dots
h1: default                # Figlet font for # titles (aliases: titleFont, h1Font)
h2: default                # Figlet font for ## sections (aliases: sectionFont, h2Font)
h3: default                # Figlet font for ### headers (aliases: headerFont, h3Font)
h1Color: null              # Color for # titles (aliases: titleColor, h1FontColor)
h2Color: null              # Color for ## sections (aliases: sectionColor, h2FontColor)
h3Color: null              # Color for ### headers (aliases: headerColor, h3FontColor)
autoAdvance: 0             # Milliseconds per state tick (0 = disabled)
---
```

`paginationStyle` options:

| Value | Example |
|-------|--------|
| `minimal` | `5` |
| `fraction` | `5/10` |
| `text` | `Slide 5 of 10` |
| `progress` | `█████░░░░░` |
| `dots` | `○ ○ ● ○ ○` |

Figlet font names for `h1`, `h2`, and `h3` must match one of the 25 bundled fonts. See [Examples/Features/FontShowcase.md](Examples/Features/FontShowcase.md) for a visual preview.

Bundled fonts: `04B_03__` `04B_03B_` `04B_08__` `04B_09__` `04B_11__` `04B_19__` `04B_20__` `04B_21__` `04B_24__` `04B_25__` `5by5` `blocco` `Bytesized-Regular` `JacquardaBastarda9-Regular` `lisp-system-tools` `Micro5-Regular` `mini` `negative-quinpix` `PressStart2P` `Silkscreen` `Sixtyfour-Regular-VariableFont_BLED,SCAN` `small` `super-mario-brothers-3-all-stars` `Tiny5` `TinyUnicode`

#### Heading Colors

Heading colors can be specified three ways:

1. **Inline HTML tags** (highest priority):
```markdown
# <red>Red Title</red>
## <cyan>Cyan Section</cyan>
### <green>Green Header</green>
```

2. **Frontmatter settings**:
```yaml
h1Color: red
h2Color: cyan
h3Color: green
```

3. **Foreground fallback** (if neither above is specified)

Both `<colorname>text</colorname>` and `<span style="color:colorname">text</span>` syntax are supported.

#### Per-Slide Overrides

Any slide can override global frontmatter settings with HTML comments in the slide body. Overrides apply only to that slide.

```markdown
### My Slide
<!-- paginationStyle: dots -->
<!-- border: cyan -->
<!-- h1: PressStart2P -->

Slide content here.
```

Supported keys: `pagination`, `paginationStyle`, `h1`, `h2`, `h3`, `h1Color`, `h2Color`, `h3Color`, `border`, `borderStyle`, `autoAdvance`.

Set `<!-- autoAdvance: 0 -->` on a slide to disable a global timer for that slide only.

See [Examples/Features/OverrideTest.md](Examples/Features/OverrideTest.md) for examples.

#### Auto-Advance

Set `autoAdvance` in frontmatter to advance the presentation automatically on a timer (milliseconds):

```yaml
---
autoAdvance: 3000
---
```

Each timer tick fires a `Next` action: reveals the next progressive bullet if any are hidden, otherwise advances to the next slide. The timer resets after every state change. Manual navigation always works regardless of the timer.

Override per slide:

```markdown
### Fast Slide
<!-- autoAdvance: 400 -->
Advances after 400ms — useful for fade simulations.

---

### Pause Here
<!-- autoAdvance: 0 -->
Auto-advance disabled. Manual input required.
```

See [Examples/Features/AutoAdvanceTest.md](Examples/Features/AutoAdvanceTest.md) for a working demo.

#### Intentionally Blank Slides

A slide containing only `<!-- intentionally blank -->` renders with no heading, content, or pagination:

```markdown
---

<!-- intentionally blank -->

---
```

## Examples

See [Examples/ExampleDeck.md](Examples/ExampleDeck.md) for a comprehensive demo:

```powershell
Show-Deck -Path ./Examples/ExampleDeck.md
```

Additional examples in `Examples/Features/`:
- [ColorTest.md](Examples/Features/ColorTest.md) - Inline color text examples
- [HeadingColorsTest.md](Examples/Features/HeadingColorsTest.md) - Heading color examples
- [ImageTest.md](Examples/Features/ImageTest.md) - Image slide layouts
- [MultiColumnTest.md](Examples/Features/MultiColumnTest.md) - Multi-column layouts
- [BulletTest.md](Examples/Features/BulletTest.md) - Bullet reveal behavior
- [TitleTest.md](Examples/Features/TitleTest.md) - Title and section slides
- [TableTest.md](Examples/Features/TableTest.md) - Markdown table rendering
- [SyntaxHighlightTest.md](Examples/Features/SyntaxHighlightTest.md) - Code block syntax highlighting
- [AutoAdvanceTest.md](Examples/Features/AutoAdvanceTest.md) - Auto-advance timer with per-slide overrides

## Requirements

- PowerShell 7.4 or later
- [TextMate](https://github.com/trackd/TextMate) (auto-installed if missing; transitively loads PwshSpectreConsole)
- Windows, Linux, or macOS (Apple Silicon only — x64 Intel macOS is not supported)

## License

MIT License w/Commons Clause - see [LICENSE](LICENSE) file for details.

## Built With

- PowerShell
- [TextMate](https://github.com/trackd/TextMate)
- [PwshSpectreConsole](https://github.com/ShaunLawrie/PwshSpectreConsole)
- [Spectre.Console](https://spectreconsole.net)

Made with 💜 by [Jake Hildreth](https://jakehildreth.com)

