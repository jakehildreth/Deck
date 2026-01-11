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

## Features

### Slide Types

* Title Slides - Single `#` heading with large figlet text  
* Section Slides - Single `##` heading with medium figlet text  
* Content Slides - `###` heading with body content  
* Multi-Column Slides - Split content with `|||` delimiter

### Bullet Points

* Progressive bullets using `*` (reveal one at a time)  
* Static bullets using `-` (all visible at once)

### Inline Formatting

* `**bold**` or `__bold__`  
* `*italic*` or `_italic_`  
* `` `code` ``  
* `~~strikethrough~~`

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

