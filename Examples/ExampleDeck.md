---
background: Black
foreground: Cyan1
border: Blue
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

## Key Features

---

### Four Slide Types

- Title slides: Single # heading, large text
- Section slides: Single ## heading, medium text  
- Content slides: ### heading with body content
- Image slides: Content on left (60%), image on right (40%)

---

### Image Slides

Two-panel layout with text content and image side-by-side.

Images auto-size to fit. Use `{width=N}` to set max width.

![PowerShell Logo](https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/Powershell_256.png)

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

### Markdown Formatting

Deck supports inline formatting:
  
```markdown
**Bold text** or __also bold__
*Italic text* or _also italic_
`Inline code` for technical terms
~~Strikethrough~~ for corrections
```

|||


  
Renders as:
  
  
**Bold text** or __also bold__
*Italic text* or _also italic_
`Inline code` for technical terms
~~Strikethrough~~ for corrections

---

### Multi-Column Layouts

Split content into columns using three pipes.

|||

First column with **bold** text.

|||

Second column with *italic* text.

|||

Third column with `code` formatting.

---

### Customization

Configure appearance in frontmatter:

```yaml
---
background: Black
foreground: Cyan1
border: Magenta
borderStyle: rounded
---
```

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

        Built with:
        - PowerShell
        - PwshSpectreConsole
        - <3
