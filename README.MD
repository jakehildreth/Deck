# Deck

Terminal-based presentations from Markdown files using PowerShell.

## Installation

```powershell
Install-Module Deck -Scope CurrentUser
```

Or clone from GitHub:

```powershell
git clone https://github.com/jakehildreth/Deck.git
Import-Module ./Deck/Deck.psd1
```

## Quick Start

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
Show-Deck -Path https://raw.githubusercontent.com/jakehildreth/Deck/main/Examples/ExampleDeck.md
```

Validate content before presenting:

```powershell
Show-Deck -Path ./presentation.md -Strict
```

The `-Strict` parameter validates:
- Content height doesn't exceed viewport
- Image files exist
- Reports all errors before starting

## Features

### Slide Types

* Title Slides - Single `#` heading with large figlet text  
* Section Slides - Single `##` heading with medium figlet text  
* Content Slides - `###` heading with body content  
* Image Slides - Two-panel layout with content left (60%), image right (40%)  
* Multi-Column Slides - Split content with `|||` delimiter

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

### Bullet Points

* Progressive bullets using `*` (reveal one at a time)  
* Static bullets using `-` (all visible at once)

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
titleFont: default         # Figlet font for titles
sectionFont: default       # Figlet font for sections
headerFont: default        # Figlet font for headers
---
```

## Examples

See [Examples/ExampleDeck.md](Examples/ExampleDeck.md) for a comprehensive demo:

```powershell
Show-Deck -Path ./Examples/ExampleDeck.md
```

Additional examples:
- [Examples/ColorTest.md](Examples/ColorTest.md) - Color text examples
- [Examples/ImageTest.md](Examples/ImageTest.md) - Image slide layouts
- [Examples/MultiColumnTest.md](Examples/MultiColumnTest.md) - Multi-column layouts
- [Examples/BulletTest.md](Examples/BulletTest.md) - Bullet reveal behavior
- [Examples/TitleTest.md](Examples/TitleTest.md) - Title and section slides

## Requirements

- PowerShell 7.4 or later
- [PwshSpectreConsole](https://github.com/ShaunLawrie/PwshSpectreConsole) (auto-installed if missing)

## License

MIT

## Built With

- PowerShell
- [PwshSpectreConsole](https://github.com/ShaunLawrie/PwshSpectreConsole)

Made with 💜 by [Jake Hildreth](https://jakehildreth.com)

