---
background: Black
foreground: Cyan1
border: Blue
h1: PressStart2P
h2: Silkscreen
h3: Micro5-Regular
h1Color: cyan
h2Color: yellow
h3Color: green
pagination: true
paginationStyle: dots
---

# Deck

---

## Terminal Presentations Made Simple

---

### What is Deck?

A PowerShell module for creating terminal-based presentations from Markdown files.

* No GUI required
* Works cross-platform
* Simple Markdown syntax
* Figlet text rendering for title text

---

### Installation

From PowerShell Gallery:

```powershell
Install-Module Deck -Scope CurrentUser
```

Or clone from GitHub:

```powershell
git clone https://github.com/jakehildreth/Deck.git
```

---

### Quick Start

Create a Markdown file with your content:

```markdown
# My Presentation

---

## Section Title

---

### Slide with Content
Your content here
```

---

### Run Your Deck

```powershell
Show-Deck -Path ./presentation.md
```

That's it!

---

## Basic Features

---

### Four Slide Types

- Title slides: Single # heading, large text
- Section slides: Single ## heading, medium text  
- Content slides: ### heading with body content
- Image slides: Content on left (60%), image on right (40%)

---

### Markdown Formatting

Deck supports inline formatting:
  
```markdown
**Bold text** or __also bold__
*Italic text* or _also italic_
`Inline code` for technical terms
~~Strikethrough~~ for corrections
<red>Colored text</red> using HTML tags
```

|||

Renders as:
  
**Bold text** or __also bold__
*Italic text* or _also italic_
`Inline code` for technical terms
~~Strikethrough~~ for corrections
<red>Colored text</red> using HTML tags

---

### Progressive Bullets

Use asterisks for bullets that reveal one at a time:

* This appears first
* Then this
* Finally this

Perfect for building suspense!

---

### Static Bullets

Use hyphens for bullets that appear all at once:

- All visible
- At the same time
- No progressive reveal

Great for lists and references.

---

## Advanced Features

---

### Color Support

Add color to your text using HTML tags:

* <red>Red text</red> for emphasis
* <blue>Blue text</blue> for information
* <green>Green text</green> for success
* <yellow>Yellow text</yellow> for warnings

You can combine: **<magenta>bold magenta</magenta>** and *<cyan>italic cyan</cyan>*

|||

Syntax examples:

```markdown
<red>text</red>
<blue>text</blue>
<span style="color:green">text</span>
```

---

# <red>Colored Titles!</red>

---

## <magenta>Colored Sections!</magenta>

---

### Inline Heading Colors

You can add colors directly to headings using HTML tags:

```markdown
# <red>Red Title</red>
## <cyan>Cyan Section</cyan>
### <green>Green Header</green>
```

Both formats work:
- Simple: `<colorname>text</colorname>`
- HTML: `<span style="color:name">text</span>`

Color priority: inline tags > frontmatter settings > foreground

---

### Image Slides

Two-panel layout with text content and image side-by-side.

Images auto-size to fit. Use `{width=N}` to set max width.

![PowerShell Logo](https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png)

---

### Multi-Column Layouts

Split content into columns using three pipes.

|||

Second column with **bold** text.

|||

Third column with *italic* text.

|||

Fourth column with `code` formatting.

---

## Customization

---

### Appearance Settings

Configure appearance in frontmatter:

```yaml
---
background: Black
foreground: Cyan1
border: Magenta
borderStyle: rounded
h1: PressStart2P          # Font aliases: titleFont, h1Font
h2: Silkscreen            # Font aliases: sectionFont, h2Font
h3: Micro5-Regular        # Font aliases: headerFont, h3Font
h1Color: red              # Color aliases: titleColor, h1FontColor
h2Color: cyan             # Color aliases: sectionColor, h2FontColor
h3Color: green            # Color aliases: headerColor, h3FontColor
pagination: true
paginationStyle: minimal
---
```

---
<!-- paginationStyle: fraction -->
### Per-Slide Overrides

Override settings per-slide using HTML comments:

```markdown
<!-- pagination: false -->
<!-- paginationStyle: progress -->
<!-- background: #1a1a1a -->
```

This slide uses `paginationStyle: fraction` override!

---

### Navigation Controls

- Forward: Right, Down, Space, Enter, n, Page Down
- Backward: Left, Up, Backspace, p, Page Up
- Exit: Esc, Ctrl+C, or q
- Help: Press ?

---

## Thanks for Watching!

---

### Learn More

GitHub: github.com/jakehildreth/Deck

          Built with
          PowerShell
      PwshSpectreConsole
              <darkmagenta><3</darkmagenta>
