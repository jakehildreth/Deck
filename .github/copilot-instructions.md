# Deck Module Implementation Guidelines

This document defines the design specifications for the Deck PowerShell module, which converts Markdown files into terminal-based presentations using PwshSpectreConsole.

## Module Overview

### Purpose
Convert Markdown files into interactive terminal slide presentations with rich ASCII art, colors, and formatting.

### Dependencies
- **PwshSpectreConsole** — Required for rendering
- Auto-import if available, otherwise attempt `Install-PSResource`
- On failure: Display sad ASCII art with helpful installation instructions

### Public Cmdlets
- `Show-Deck` — Run a live presentation from a Markdown file
- `Export-Deck` — Generate a standalone `.ps1` script from a Markdown file

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
- `#` — Title slide heading (large figlet text, full screen)
- `##` — Section slide heading (medium figlet text, full screen)
- `###` — Regular slide header (smaller figlet text above content)
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
Deck/
├── Deck.psd1                          # Module manifest
├── Deck.psm1                          # Module loader
├── Public/
│   ├── Show-Deck.ps1                  # Live presentation cmdlet
│   └── Export-Deck.ps1                # Export to script cmdlet (future)
├── Private/
│   ├── ConvertFrom-DeckMarkdown.ps1   # Markdown parser
│   ├── Get-SlideNavigation.ps1        # Input handling
│   ├── Import-DeckDependency.ps1      # Dependency management
│   ├── Show-ContentSlide.ps1          # Content slide renderer
│   ├── Show-SadFace.ps1               # Failure ASCII art
│   ├── Show-SectionSlide.ps1          # Section slide renderer
│   └── Show-TitleSlide.ps1            # Title slide renderer
├── Fonts/                             # Bundled .flf figlet fonts
│   ├── small.flf                      # Section slide font
│   └── mini.flf                       # Content header font
├── Tests/                             # Pester tests
│   ├── Show-Deck.Tests.ps1
│   ├── Get-SlideNavigation.Tests.ps1
│   └── Show-ContentSlide.Tests.ps1
└── Examples/
    ├── FullTest.md                    # Comprehensive demo
    └── BulletTest.md                  # Bullet reveal demo
```

## Implementation Phases

### Phase 1: Foundation
- [x] **Module structure** — Create basic manifest (Deck.psd1), module file (Deck.psm1), and folder structure (Public/, Private/, Fonts/, Examples/)
- [x] **Dependency loader** — Implement PwshSpectreConsole loading with fallback to Install-PSResource (with sad face ASCII art on failure)
- [x] **Test** — Verify module loads correctly and handles missing dependencies gracefully

### Phase 2: Parsing
- [x] **YAML frontmatter parser** — Extract settings from markdown frontmatter
- [x] **Slide splitter** — Split markdown by horizontal rules (---, ***, ___) into individual slide chunks
- [x] **Test** — Parse a simple markdown file and verify correct extraction of settings and slide content

### Phase 3: First Slide Type
- [x] **Title slide renderer** — Implement complete Title slide rendering (# heading with large figlet text)
- [x] **Basic navigation** — Simple "press any key to exit" functionality
- [x] **Test** — Display a simple title slide presentation end-to-end

### Phase 4: Core Slide Types
- [x] **Section slide renderer** — Implement Section slide (## heading with medium figlet text)
- [x] **1-column slide renderer** — Implement basic content slide with header and content
- [x] **Test** — Display presentation with Title, Section, and 1-column slides

### Phase 5: Advanced Slide Types
- [ ] **2-column slide renderer** — Implement two-column layout
- [ ] **Left/Right slide renderers** — Implement image-based layouts
- [ ] **Test** — Display presentation with all slide types

### Phase 6: Full Navigation
- [x] **Complete navigation** — Implement all navigation keys (arrows, space, enter, n/p, page up/down)
- [x] **Bullet reveal** — Implement progressive bullet point reveal for `*` items
- [x] **Backward bullet navigation** — Hide bullets when navigating backward
- [ ] **Content scrolling** — Implement smart scrolling for overflow content
- [x] **Test** — Verify navigation key handlers (77 tests passing)

### Phase 6.5: Visual Polish
- [x] **Full-height borders** — All slide types fill terminal viewport
- [x] **Consistent border heights** — Fixed padding calculations to prevent shifting
- [x] **Accurate height measurement** — Account for horizontal padding in figlet wrapping
- [x] **Cursor hiding** — Hide cursor during presentation
- [x] **Exit message** — Display "Goodbye! <3" in magenta on exit
- [x] **Help screen** — Press ? to show navigation controls

### Phase 7: Validation & Polish
- [ ] **Image validation** — Implement pre-load validation with -Strict mode
- [ ] **Empty slide handling** — Interactive prompt with markdown file modification
- [ ] **Markdown formatting** — Implement bold, italic, inline code, strikethrough conversion
- [ ] **Code blocks** — Implement syntax highlighting support
- [ ] **Test** — Verify all validation and formatting features

### Phase 8: Watch Mode
- [ ] **File watcher** — Implement -Watch parameter with FileSystemWatcher
- [ ] **Auto-reload** — Reload and re-render on file changes with position preservation
- [ ] **Test** — Edit markdown file while watching and verify reload behavior

### Phase 9: Export Functionality
- [ ] **Export-Slides cmdlet** — Implement standalone script generation
- [ ] **Embedded dependencies** — Ensure exported script is self-contained
- [ ] **Test** — Generate and run exported presentation script

### Phase 10: Documentation & Examples
- [ ] **Comment-based help** — Complete help for both cmdlets
- [ ] **Example presentations** — Create sample markdown files demonstrating all features
- [ ] **README** — Write comprehensive project documentation
