# Deck Module Implementation Guidelines

This document defines the design specifications for the Deck PowerShell module, which converts Markdown files into terminal-based presentations using PwshSpectreConsole.

## Code Style

### OTBS (One True Brace Style)
All PowerShell code in this project must follow OTBS:
- Opening braces on same line as statement: `if ($condition) {`, `function Test-Thing {`
- Closing braces on new line
- `else`, `elseif`, `catch`, and `finally` keywords on same line as closing brace: `} else {`, `} elseif {`, `} catch {`, `} finally {`
- Never put these keywords on their own line after a closing brace

### Markdown Parsing Rules
**ALWAYS skip parsing markup inside code:**
- Inline code blocks (backticks: `` `code` ``)
- Code fences (triple backticks: ``` ```code``` ```)
- When parsing HTML comments, regex patterns, or any markup, temporarily replace code blocks with placeholders before parsing
- Restore code blocks after parsing is complete
- Never match or parse content that appears inside code examples

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
h1Font: default            # Figlet font for # (title slides)
h2Font: default            # Figlet font for ## (section slides)
h3Font: default            # Figlet font for ### (content headers)
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
- `#` — Title slide heading (large figlet text, full screen) - **Cannot have additional content**
- `##` — Section slide heading (medium figlet text, full screen) - **Cannot have additional content**
- `###` — Regular slide header (smaller figlet text above content)
- `*` item — Bullet points revealed one at a time
- `-` item — Bullet points shown all at once
- Regular text — Displayed as paragraphs
- `![alt](path)` — Images for Left/Right slide layouts
- Fenced code blocks — Syntax highlighted when language specified

**Important:** Title (`#`) and Section (`##`) slides must contain ONLY the heading text with no additional content. Use `###` headings for slides that need both a header and body content.

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
- [x] **Multi-column slide renderer** — Implement multi-column layout with ||| delimiter
- [x] **Image slide renderers** — Implement image-based layouts (left/right 60/40 split)
- [x] **Test** — Display presentation with all slide types

### Phase 6: Full Navigation
- [x] **Complete navigation** — Implement all navigation keys (arrows, space, enter, n/p, page up/down)
- [x] **Bullet reveal** — Implement progressive bullet point reveal for `*` items
- [x] **Backward bullet navigation** — Hide bullets when navigating backward
- [x] **Test** — Verify navigation key handlers (77 tests passing)

**Future Enhancement:**
- Content scrolling for overflow (Up/Down arrows scroll within slide when content exceeds viewport, navigate at boundaries)

### Phase 6.5: Visual Polish
- [x] **Full-height borders** — All slide types fill terminal viewport
- [x] **Consistent border heights** — Fixed padding calculations to prevent shifting
- [x] **Accurate height measurement** — Account for horizontal padding in figlet wrapping
- [x] **Cursor hiding** — Hide cursor during presentation
- [x] **Exit message** — Display "Goodbye! <3" in magenta on exit
- [x] **Help screen** — Press ? to show navigation controls

### Phase 7: Validation & Polish
- [x] **Image validation** — Implement pre-load validation with -Strict mode
- [x] **Empty slide handling** — Auto-skip empty slides, support `<!-- intentionally blank -->` comment
- [x] **Markdown formatting** — Implement bold, italic, inline code, strikethrough conversion
- [x] **Code blocks** — Implement syntax highlighting support
- [x] **Color support** — Implement `<colorname>text</colorname>` and `<span style="color:name">` tags
- [x] **Test** — Verify markdown formatting and code block features

### Phase 7.5: Documentation
- [x] **Comment-based help** — Comprehensive help for all 18 functions with 3-5 examples each
- [x] **Example presentations** — Create sample markdown files demonstrating all features
- [x] **README** — Write comprehensive project documentation

### Phase 8: Watch Mode
- [ ] **File watcher** — Implement -Watch parameter with FileSystemWatcher
- [ ] **Auto-reload** — Reload and re-render on file changes with position preservation
- [ ] **Test** — Edit markdown file while watching and verify reload behavior

### Phase 9: Export Functionality
- [ ] **Export-Deck cmdlet** — Implement standalone script generation
- [ ] **Embedded dependencies** — Ensure exported script is self-contained
- [ ] **Test** — Generate and run exported presentation script

### Phase 10: Presenter Mode
- [ ] **Dual window support** — Launch presenter and audience windows
- [ ] **Notes parsing** — Extract presenter notes from `<!-- [NOTES] -->` blocks
- [ ] **Next slide preview** — Show upcoming slide content in presenter view
- [ ] **Presenter display** — Current slide notes + next slide preview in split-pane layout
- [ ] **Synchronized navigation** — Control main presentation from presenter window
- [ ] **Timer display** — Elapsed time display in presenter view
- [ ] **Test** — Verify dual-window control and note display

#### Presenter Mode Specifications

**Activation:**
```powershell
Show-Deck -Path presentation.md -PresenterMode
```

**Notes Syntax:**
```markdown
### Slide Title

Content for the slide

<!-- [NOTES]
Remember to mention the key point here.
Ask if there are questions about this topic.
Transition smoothly to the next section.
Demo the live feature if time permits.
-->
```

**Presenter Window Layout:**

```
┌─ Deck Presenter View ─────────────────────────────────────────────────────────┐
│ Slide 3 of 10                                      Elapsed: [00:05:32]        │
├───────────────────────────────────┬───────────────────────────────────────────┤
│ Current Slide Notes:              │ Next Slide Preview:                       │
│                                   │                                           │
│ Remember to mention the key       │  ### Implementation Details               │
│ point here.                       │                                           │
│                                   │  * First implementation step              │
│ Ask if there are questions about  │  * Second implementation step             │
│ this topic.                       │  * Third implementation step              │
│                                   │                                           │
│ Transition smoothly to the next   │  ```powershell                            │
│ section.                          │  Get-Process | Where CPU -gt 100          │
│                                   │  ```                                      │
│ Demo the live feature if time     │                                           │
│ permits.                          │                                           │
│                                   │                                           │
└───────────────────────────────────┴───────────────────────────────────────────┘
Navigation: ← → (navigate) | ESC (exit) | ? (help)
```

**Notes Format:**
- Use `<!-- [NOTES] ... -->` HTML comment blocks
- Place at the end of each slide (after content)
- Content can be free-form text (not required to be bullets)
- Notes are parsed and displayed as-is in presenter window
- Notes are never visible in audience view

**Layout:**
- Top bar: Slide counter and elapsed timer
- Left pane (50%): Current slide notes in plain text format
- Right pane (50%): Next slide preview showing final state (all bullets visible)
- Bottom: Navigation key hints

**Requirements:**
- Presenter window controls both displays
- Navigation in presenter window advances both views
- Notes persist across slide changes (no progressive reveal)
- Next slide preview shows final state (all bullets visible)
- Timer starts when presentation begins
- Both windows close on exit from either window
- Graceful fallback if dual terminals not supported

#### Technical Implementation: Named Pipes IPC

**Approach:** Use System.IO.Pipes.NamedPipeServerStream for inter-process communication

**Why Named Pipes:**
- Cross-platform in .NET 8 (PowerShell 7.4+)
  - Windows: Native named pipes
  - Linux/macOS: Unix domain sockets (seamless)
- Low latency (< 1ms)
- Built-in message framing
- Connection-oriented (detect disconnection)
- Automatic cleanup on process termination
- No port management or firewall concerns

**Architecture:**
```
Presenter Window (Server/Controller)
├── Named Pipe Server: "Deck_$PID"
├── Slide state tracking
├── Navigation input handling
└── Sends: { Command: "NextSlide", SlideNum: 5, Timestamp: ... }

Audience Window (Client/Follower)
├── Named Pipe Client connects to "Deck_$PID"
├── Non-blocking read loop
├── Slide rendering
└── Receives commands and updates display
```

**Implementation Files:**
- `Private/Start-PresenterPipe.ps1` - Create named pipe server
- `Private/Connect-AudiencePipe.ps1` - Connect as pipe client
- `Private/Send-NavigationEvent.ps1` - Write JSON commands to pipe
- `Private/Receive-NavigationEvent.ps1` - Non-blocking read from pipe
- Update `Show-Deck.ps1` - Add `-PresenterMode`, `-AudienceMode`, `-PipeName` parameters

**Sample Implementation:**
```powershell
# Presenter starts server and launches audience window
$pipeName = "Deck_$PID"
$pipe = [System.IO.Pipes.NamedPipeServerStream]::new(
    $pipeName,
    [System.IO.Pipes.PipeDirection]::InOut,
    1,
    [System.IO.Pipes.PipeTransmissionMode]::Message
)

# Launch audience window
Start-Process pwsh -ArgumentList @(
    "-NoProfile"
    "-Command"
    "Show-Deck -Path '$Path' -AudienceMode -PipeName '$pipeName'"
)

# Wait for connection
$pipe.WaitForConnectionAsync().Wait()
$writer = [System.IO.StreamWriter]::new($pipe)
$writer.AutoFlush = $true

# Send navigation commands
$writer.WriteLine((@{ Command = 'NextSlide'; Slide = 5 } | ConvertTo-Json))
```

**Error Handling:**
- Connection timeout (5 seconds) if audience fails to connect
- Pipe disconnection detection → close both windows
- Process exit monitoring → cleanup and terminate peer