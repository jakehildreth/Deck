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

### Three Slide Types

- Title slides: Single # heading, large text
- Section slides: Single ## heading, medium text  
- Content slides: ### heading with body content

---

### Customization

Configure appearance in frontmatter:

 ---
background: Black
foreground: Cyan1
border: Magenta
borderStyle: rounded
 ---

---

### Navigation Controls

- Forward: Right, Down, Space, Enter, n, Page Down
- Backward: Left, Up, Backspace, p, Page Up
- Exit: Esc or Ctrl+C
- Help: Press ?

---

## Thanks for Watching!

---

### Learn More

GitHub: github.com/jakehildreth/Deck

PowerShell Gallery: Install-Module Deck

Built with PwshSpectreConsole
