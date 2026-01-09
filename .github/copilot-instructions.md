# Slides Module Implementation Guidelines

This document defines the design specifications for the Slides PowerShell module, which converts Markdown files into terminal-based presentations using PwshSpectreConsole.

## Module Overview

### Purpose
Convert Markdown files into interactive terminal slide presentations with rich ASCII art, colors, and formatting.

### Dependencies
- **PwshSpectreConsole** — Required for rendering
- Auto-import if available, otherwise attempt `Install-PSResource`
- On failure: Display sad ASCII art with helpful installation instructions

### Public Cmdlets
- `Show-Slides` — Run a live presentation from a Markdown file
- `Export-Slides` — Generate a standalone `.ps1` script from a Markdown file

## Input Format

### Frontmatter (YAML)
Standard YAML frontmatter with `---` delimiters at the top of the file:

```yaml
---
background: black          # Named color or hex (e.g., "#1a1a1a")
foreground: white          # Named color or hex (e.g., "#FFFFFF")
border: magenta            # Named color or hex (e.g., "#FF00FF")
header: "Presentation Title"  # Optional header text
footer: "© 2026"           # Optional footer text
pagination: false          # Show slide numbers (default: false)
paginationStyle: minimal   # Style: minimal, fraction, text, progress, dots
borderStyle: rounded       # Style: rounded, square, double, heavy, none
titleFont: default         # Figlet font for Title slides
sectionFont: default       # Figlet font for Section slides
headerFont: default        # Figlet font for slide headers
---
```

### Slide Delimiters
Slides are separated by horizontal rules: `---`, `***`, or `___`

### Slide Type Detection

Auto-detect slide type based on content, with optional override via `<!-- type: xxx -->`:

| Type | Auto-Detection Rule |
|------|---------------------|
| `title` | `#` heading only, no other content |
| `section` | `##` heading only, no other content |
| `1column` | Default for content slides |
| `2column` | Has two distinct content blocks |
| `left` | Has image positioned on left |
| `right` | Has image positioned on right |

### Content Rules
- `#` — Main heading (Title slides use large figlet text)
- `##` — Section heading (Section slides use medium figlet text)
- `*` item — Bullet points revealed one at a time
- `-` item — Bullet points shown all at once
- Regular text — Displayed as paragraphs
- `![alt](path)` — Images for Left/Right slide layouts
- Fenced code blocks — Syntax highlighted when language specified

### Per-Slide Overrides
Use HTML comments to override settings for individual slides:

```markdown
<!-- type: 2column -->
<!-- background: #000033 -->
<!-- border: cyan -->
```

## Navigation Controls

### Forward (Next Slide/Bullet)
- Right Arrow (→)
- Down Arrow (↓)
- Space
- Enter
- `n`
- Page Down

### Backward (Previous Slide)
- Left Arrow (←)
- Up Arrow (↑)
- Backspace
- `p`
- Page Up

### Exit
- `Ctrl+C`
- `Esc`

### Bullet Reveal Behavior
Forward keys reveal the next `*` bullet. Once all bullets are shown, the next forward keypress advances to the next slide.

### Content Overflow Scrolling
When content exceeds terminal height:
- Up/Down arrows scroll within the slide
- At top of content, Up arrow goes to previous slide
- At bottom of content, Down arrow goes to next slide
- Other navigation keys (Left/Right, Space, Enter, n/p, Page Up/Down) navigate slides directly

## Visual Styling

### Pagination Styles
When `pagination: true`, display using configured style:
- `minimal` — Just the slide number: `3` (default)
- `fraction` — Fraction format: `3/10`
- `text` — Full text: `Slide 3 of 10`
- `progress` — Progress bar: `████░░░░░░`
- `dots` — Dot indicators: `○ ○ ● ○ ○ ○ ○ ○ ○ ○`

### Border Styles
- `rounded` — Smooth corners: `╭───╮` (default)
- `square` — Sharp corners: `┌───┐`
- `double` — Double lines: `╔═══╗`
- `heavy` — Thick lines: `┏━━━┓`
- `none` — No border

### Figlet Fonts
- Use Spectre.Console's built-in default font as the default
- Support bundled `.flf` font files
- Allow custom font paths via `titleFont`, `sectionFont`, `headerFont` settings

### Inline Markdown Formatting
Support these inline styles:
- `**bold**` or `__bold__` → Spectre `[bold]text[/]`
- `*italic*` or `_italic_` → Spectre `[italic]text[/]`
- `` `code` `` → Styled inline code
- `~~strikethrough~~` → Spectre `[strikethrough]text[/]`

### Code Blocks
- With language specified: Syntax highlighted
- Without language: Plain monospace text (no default language)

## Cmdlet Parameters

### Show-Slides

```powershell
Show-Slides
    [-Path] <string>           # Mandatory: Path to Markdown file
    [-Background <string>]     # Override background color
    [-Foreground <string>]     # Override foreground color
    [-Border <string>]         # Override border color
    [-Header <string>]         # Override header text
    [-Footer <string>]         # Override footer text
    [-Pagination]              # Enable pagination
    [-PaginationStyle <string>] # Pagination style
    [-BorderStyle <string>]    # Border style
    [-Strict]                  # Fail on validation errors
    [-Watch]                   # Auto-reload on file changes
```

### Export-Slides

```powershell
Export-Slides
    [-Path] <string>           # Mandatory: Path to Markdown file
    [-OutputPath <string>]     # Output .ps1 file path
    [-Background <string>]     # Override background color
    [-Foreground <string>]     # Override foreground color
    [-Border <string>]         # Override border color
    [-Header <string>]         # Override header text
    [-Footer <string>]         # Override footer text
    [-Pagination]              # Enable pagination
    [-PaginationStyle <string>] # Pagination style
    [-BorderStyle <string>]    # Border style
```

## Validation and Error Handling

### Image Validation
During load, validate all images:
1. Check file exists
2. Check file is valid image format
3. Check terminal supports image rendering

**Default behavior:** Warn in console, auto-continue with alt text in styled box for broken images

**With `-Strict`:** Fail fast with a clear list of all issues

### Empty Slides
When an empty slide is detected:
1. Show warning for each empty slide
2. Prompt user: Skip or Keep
3. If Keep: Add `<!-- intentionally blank -->` comment to markdown file
4. Slides with `<!-- intentionally blank -->` display as blank without warning

### No Slide Delimiters
If no horizontal rules found in file:
- Display warning to user
- Treat entire file as single slide
- Continue with presentation

### PwshSpectreConsole Load Failure
1. Attempt to import module
2. If not found, attempt `Install-PSResource PwshSpectreConsole`
3. On failure: Display sad ASCII art with helpful manual installation instructions
4. Exit gracefully

## Watch Mode

When `-Watch` is specified on `Show-Slides`:
- Monitor the markdown file for changes
- On file change, reload and re-render the presentation
- Preserve current slide position if possible
- Useful for editing in one window while previewing in another

## Module Structure

```
Slides/
├── Slides.psd1              # Module manifest
├── Slides.psm1              # Module loader
├── Public/
│   ├── Show-Slides.ps1      # Live presentation cmdlet
│   └── Export-Slides.ps1    # Export to script cmdlet
├── Private/
│   ├── Import-SlidesDependency.ps1   # Dependency management
│   ├── ConvertFrom-SlideMarkdown.ps1 # Markdown parser
│   ├── Get-SlideType.ps1             # Slide type detection
│   ├── Show-Slide.ps1                # Single slide renderer
│   ├── Show-TitleSlide.ps1           # Title slide renderer
│   ├── Show-SectionSlide.ps1         # Section slide renderer
│   ├── Show-ContentSlide.ps1         # Content slide renderer
│   ├── Show-TwoColumnSlide.ps1       # Two-column renderer
│   ├── Show-ImageSlide.ps1           # Left/Right image renderer
│   ├── ConvertTo-SpectreMarkup.ps1   # Markdown to Spectre conversion
│   ├── Get-SlideNavigation.ps1       # Input handling
│   └── Show-SadFace.ps1              # Failure ASCII art
├── Fonts/                   # Bundled .flf figlet fonts
└── Examples/
    └── Example.md           # Example presentation
```
